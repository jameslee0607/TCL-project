proc gen_lotinfo {} {
global division  lot_demand_id start_count
set report_path c:/working/
set lot_info [open "$report_path/loading_report.csv" w]
puts $lot_info "lot_id,lot_demand_id, com@location, mthod, route, route_segment_ix,route_segment,route_segment_desc,\
seq_ix,lot_seq_pref,Step_id,operation,lot_step_start,lot_step_end,duration_of_lot_step,BORA,bor_ix,bor_id,bor_pref,RA_ix,RA_id,RES_ix,RES_id,RES_pref,\
DIvision,lot_start,lot_end"		    			
	for {set i 0} {$i < [lot get number]} {incr i} {
	    	lot set ix $i
	    	if {[lot get sched]=="yes"} {	
		   set lot_id [lot get id]
		   period_looping $lot_id 
		   #catch {unset start_count}
		   set lot_method [lot get method]		
		   set lot_route [lot get route]
		   set lot_status [lot get status]
		   set lot_com [lot get com@location]
		   set lot_due [cast time date3 [lot get due]]
		   set lot_start [cast time date3 [lot get start]]
		   set lot_end [cast time date3 [lot get end]]
		   set lot_actual [lot get cyc_act]
		   set lot_ideal [lot get cyc_ideal]
		   #puts $lotinfo "$lot_id,$lot_start,$lot_due,$lot_end,$lot_actual,$lot_ideal"	   
		   for {set j 0} {$j < [lot segment get number]} {incr j} {
		 	lot segment set ix $j
		    	set lot_segment [lot segment get id]
		    	set lot_segmentix [lot segment get ix]	;#Route_Segment 
		    	set lot_seqix [lot seq get sched_ix]	    	;#the scheduled wo on step sequence. 
		    	if {$lot_seqix == -1} {
		    		continue
		    	}
		        if {[catch {route_segment set id $lot_segment}] == 0} {
		    	    set lot_segmentdesc [string range [route_segment get desc] 0 1]
		    	} else {
		    	    set lot_segmentdesc "-1"
		    	}
		    	lot seq set ix $lot_seqix
		    	set lot_seq_pref [lot seq get pref]
		    	set lot_seq [lot seq get id]
		    	for {set k 0} {$k < [lot step get number]} {incr k} {
		    		lot step set ix $k
				set lot_step_ix $k
				set lot_step_id [lot step get id]
				set lot_step_dur [lot step get dur]
				set lot_step_start [cast time date3 [lot step get start]]
				set lot_step_end [cast time date3 [lot step get end]]
				set lot_op [lot step get op]
				op set id $lot_op
				if {[catch {op com_override set id $lot_com}] == 0} {
					set lot_bora [op com_override get bor_alt]
				} else {
					op set id $lot_op
					set lot_bora [op get bor_alt]
				}								
				set lot_bor_ix [lot bor get ix]
				set lot_bor_id [lot bor get bor]
				bor_alt set id $lot_bora
				bor_alt elem set ix 0  ;#take the first Bill of Resource from spec. 
				;#bor_alt elem set ix $lot_bor_ix
				set lot_bor_pref [bor_alt elem get pref]
				set lot_act_no [lot act get number]
				for {set m 0} {$m < $lot_act_no} {incr m} {
				    lot act set ix $m
				    set lot_ra_id [lot act get res_alt]
				    set lot_res_id [lot act get res]
				    res set id $lot_res_id
				    set lot_ra_ix [search_raix $lot_bor_id $lot_ra_id]
				    set lot_res_ix [search_resix $lot_ra_id $lot_res_id]
				    set lot_res_pref [search_respref $lot_ra_id $lot_res_id]
				    #echo $lot_id
				    test $lot_id 	
				    #period_looping $lot_id 		    
        			} 
        			
		    	 }		    
		    }
		
	    puts $lot_info "$lot_id,$lot_demand_id,$lot_com,$lot_method,$lot_route,$lot_segmentix,\
	    $lot_segment,$lot_segmentdesc,$lot_seqix,$lot_seq,$lot_seq_pref,\
	    $lot_step_id,$lot_op,$lot_step_start,$lot_step_end,$lot_step_dur,$lot_bora,\
	    $lot_bor_ix,$lot_bor_id,$lot_bor_pref,$lot_ra_ix,$lot_ra_id,$lot_res_ix,$lot_res_id,$lot_res_pref,\
	    $division,$lot_start, $lot_end"	
	}
	} 
close $lot_info
}


#proc test_1 { } {
#	global division
#	for {set i 0} {$i < [lot get number]} {incr i} {
#		lot set ix $i 
#		set lot_id [lot get id]
#		test $lot_id 
#		#echo -$lot_id -$division ##
#	}
#}

proc test { lot_id } {
	global division  lot_demand_id 

	for {set i 0} {$i < [lot demand get number]} {incr i} {
	lot demand set ix $i 
	set lot_demand_id [lot demand get id]
	catch {demand set id $lot_demand_id}
	set demand_qty [ lot demand get qty]
	set demand_qty $demand_qty
	set lot_qty [lot get end_qty]
	set lot_qty $lot_qty
	set division [expr $lot_qty / $demand_qty ] 
	#echo $lot_demand_id ++ $demand_qty 
	return $division 
	#echo $division
	# if <= 1 then the lot is covered by the demand 
	# if > 1 then other lot is needed to cover it again. 
	return $lot_demand_id 
	}
}

proc period_looping { lot_id } { 

global start_count
	lot set id $lot_id 
	set lot_start [lot get start]
	set lot_end [lot get end]
	cal period_mgr set id default 
	#set start_count 0 
	#set end_count 0 
	
	for {set i 0} {$i < [cal period get number]} {incr i} {
		cal period set ix $i 
		set period_start [cal period get start]
		set period_end [cal period get end]	
		  if { $lot_start <= $period_start } {		  	
		  	set start_count [expr $i-1]
		  	
		  } elseif { $lot_start >=  $period_start && $lot_start <= $period_end } {
		  	set start_count [cal period get ix]
		  	#echo $start_count $i $lot_start $period_start
		  	#echo  $lot_start $period_end  <<<<
		  	
		  } else {
		  	#set  start_count out_of horizon_end 
		  	#echo $lot_start 
		  	set start_count outside_end_horizon
		  
		  }
		  
		  if { $lot_end <= [cal horizon get end] } {		  	
		  	set start_count [expr $i-1]
		  	
		  } elseif { $lot_end <= $period_end } {
		  	set start_count [cal period get ix]
		  	#echo $start_count $i $lot_start $period_start
		  	#echo  $lot_start $period_end  <<<<
		  	
		  } else {
		  	#set  start_count out_of horizon_end 
		  	#echo $lot_start 
		  	set start_count outside_end_horizon
		  	
		  }
		  return $lot_start
		  return $lot_end
		  #retrun  $start_count
		  catch {unset start_count}
		  
		#set period_array($i) "$period_start/$period_end---$i"	
	}
}

proc search_raix {borid raid} {
	
	bor set id $borid 
	set borelem_no [bor elem get number]
	for {set i 0} {$i < $borelem_no} {incr i} {
	   bor elem set ix $i
	   set borelem_id [bor elem get id]
	   if {$borelem_id == $raid} {
	      return $i
	   }
	}
	return -1
}

proc search_resix {raid resid} {
	
	res_alt set id $raid 
	set resaltelem_no [res_alt elem get number]
	for {set i 0} {$i < $resaltelem_no} {incr i} {
	   res_alt elem set ix $i
	   set resaltelem_id [res_alt elem get id]
	   if {$resaltelem_id == $resid} {
	      return $i
	   }
	}
	return -1
}

proc search_respref {raid resid} {
	
	res_alt set id $raid 
	set resaltelem_no [res_alt elem get number]
	for {set i 0} {$i < $resaltelem_no} {incr i} {
	   res_alt elem set ix $i
	   set resaltelem_id [res_alt elem get id]
	   if {$resaltelem_id == $resid} {
	      return [res_alt elem get pref]
	   }
	}
	return -1
}

