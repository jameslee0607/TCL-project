# This is my old codes for Adexa business rules

proc split_into_tl {so_lot_id} {

problem update off
update_gui off 
lot sort off    
global SO_Sched_Lot_Header
global SO_Sched_Lot_Element
global SO_Sched_Lot_BORA_Element 
global bal_list

lot set id $so_lot_id 
set lot_com [lot get com@location]
set lot_qty [lot get qty]      
com@location set id $lot_com
set tl_std_size [com@location get standard_lot]
set tl_min_size [com@location get min_lot]
set tl_max_size [com@location get max_lot]
            
set tl_count 0
set lot_remaining $lot_qty
#echo [lot get id],$lot_remaining

if {$lot_qty >= [expr $tl_std_size + $tl_min_size]} {
	planner mode set no_resize_supply_lots on
  # planner mode set no_change_due_date_supply_lots on
  
  lot set id $so_lot_id
  set lot_qty [lot get qty]
  set lot_desc [lot get desc]
  set lot_com [lot get com@location]
  set lot_method [lot get method]
  set lot_due [lot get due]
  set lot_cfi [lot get cfi]  
  set lot_cfitype [lot get cfi_type]
  set lot_prio [lot get prio]
  set lot_status [lot get status]
  set lot_fixed [lot get fixed_status]
  set step_count 0    
  set hardbatchdemand [lot attribute_value get HardBatch_Demand]
  set hardbatchsupply [lot attribute_value get HardBatch_Supply]
  set pull_in_type [lot attribute_value get Pull_In_Type]
  set schedule_type [lot attribute_value get sched_type]
  set Second_Phase [lot attribute_value get Second_Phase]
  set scheduling_mode [lot attribute_value get scheduling_mode]
  set Presort [lot attribute_value get Presort]
  set Postsort [lot attribute_value get Postsort]
  set lot_fwd_start [lot attribute_value get Lot_fwd_start]
  set AMS [lot attribute_value get AMS]
  
  set tl_balance_list {}
  set tl_sup_list() {}
  set tl_sup_com_list {}
  set tl_dem_list {}
  set tl_balance_dem_list {}
  set tl_sup_com_ix 0
  for {set lot_sup_com_ix 0} {$lot_sup_com_ix < [lot supply get com@location_number]} {incr lot_sup_com_ix} {
  	  lot supply set com@location_ix $lot_sup_com_ix
  	  set tl_sup_com [lot supply get com@location_id]
  	  if {[lsearch $tl_sup_com_list $tl_sup_com*] != -1} {
  	  	  incr tl_sup_com_ix
  	  }
  	  lappend tl_sup_com_list [list $tl_sup_com $tl_sup_com_ix]
  	  for {set lot_sup_ix 0} {$lot_sup_ix < [lot supply get number]} {incr lot_sup_ix} {
  	  	  lot supply set ix $lot_sup_ix
  	  	  lappend tl_sup_list($tl_sup_com) [list [lot supply get id] [lot supply get qty]]
  	  }
  }
  for {set lot_dem_ix 0} {$lot_dem_ix < [lot demand get number]} {incr lot_dem_ix} {
  	  lot demand set ix $lot_dem_ix
  	  set tl_dem_com $lot_com
  	  set tl_dem_id [lot demand get id]
  	  set tl_dem_connct_qty [lot demand get qty]
  	  lappend tl_dem_list [list $tl_dem_id $tl_dem_connct_qty]
  }
  	
  while {$lot_remaining > 0} {
         incr tl_count
         set tl_lot_id ""
         if {$tl_count < 10} {
            set tl_index "0$tl_count"
         } else {
            set tl_index $tl_count
         } 
         set tl_lot_id "$so_lot_id#$tl_index"
         if {$lot_remaining >= [expr $tl_std_size + $tl_min_size]} {
            set tl_lot_qty $tl_std_size
            set lot_remaining [expr $lot_remaining - $tl_std_size]
         } else {
            set tl_lot_qty $lot_remaining
            set lot_remaining 0                        
         }
         #echo $tl_lot_id,$tl_lot_qty
         catch {[lot add $tl_lot_id]}
         catch {[lot set id $tl_lot_id]}
         lot set desc $lot_desc 
         lot set qty $tl_lot_qty
         lot set com@location $lot_com
         lot set method $lot_method 
         lot set due $lot_due
         lot set cfi $lot_cfi
         lot set cfi_type $lot_cfitype
         lot set prio $lot_prio
         lot set status $lot_status          
         lot set fixed_status $lot_fixed
         lot attribute_value set HardBatch_Demand $hardbatchdemand
         lot attribute_value set HardBatch_Supply $hardbatchsupply
         lot attribute_value set LOT_TYPE SO_TL            
         lot attribute_value set Pull_In_Type $pull_in_type
         lot attribute_value set sched_type $schedule_type
         lot attribute_value set Second_Phase $Second_Phase 
         lot attribute_value set scheduling_mode $scheduling_mode
         lot attribute_value set Presort $Presort
         lot attribute_value set Postsort $Postsort
         lot attribute_value set Lot_fwd_start $lot_fwd_start
         lot attribute_value set AMS $AMS
         
         set tl_lot_end_qty [lot get end_qty]
		 set tmp_qty $tl_lot_end_qty
		 set remaining 0
		 set connct_qty 0
		 for {set elem_dem_ix 0} {$elem_dem_ix < [llength $tl_dem_list]} {incr elem_dem_ix} {
		 	  set elem_rec [lindex $tl_dem_list $elem_dem_ix]
		 	  set avaliable [lindex $elem_rec 1]
		 	  set elem_dem_id [lindex $elem_rec 0]
		 	  
		 	  if {$avaliable == 0} {
		 	  	  continue
		 	  }
		 	  
		 	  if {$avaliable <= $tmp_qty} {
		 	  	  set tmp_qty [expr $tmp_qty - $avaliable]
		 	  	  set connct_qty $avaliable
		 	  	  set elem_rec [lreplace $elem_rec 1 1 0]
		 	  } else {
		 	  	  set remaining [expr $avaliable - $tmp_qty]
		 	  	  set connct_qty $tmp_qty
		 	  	  set elem_rec [lreplace $elem_rec 1 1 $remaining]
		 	  	  set tmp_qty 0
		 	  }
		 	  set tl_dem_list [lreplace $tl_dem_list $elem_dem_ix $elem_dem_ix $elem_rec]
		 	  lappend tl_balance_dem_list [list $lot_com $elem_dem_id $tl_lot_id $connct_qty]
		 	  if {$tmp_qty == 0} {
		 	  	  break
		 	  }
		 }

          foreach elem_tl_sup $tl_sup_com_list {
          	 set elem_tl_sup_com [lindex $elem_tl_sup 0]
          	 set elem_tl_sup_com_ix [lindex $elem_tl_sup 1]
          	 set elem_tl_sup $tl_sup_list($elem_tl_sup_com)
         	 set tmp_qty $tl_lot_qty
         	 set remaining 0
         	 set connct_qty 0
             for {set elem_sup_ix 0} {$elem_sup_ix < [llength $elem_tl_sup]} {incr elem_sup_ix} {
             	  set elem_rec [lindex $elem_tl_sup $elem_sup_ix]
             	  set avaliable [lindex $elem_rec 1]
             	  set sup_id [lindex $elem_rec 0]
             	  
             	  if {$avaliable == 0} {
             	      continue
             	  }
             	  
             	  if {$avaliable <= $tmp_qty} {
             	 	  set tmp_qty [expr $tmp_qty - $avaliable]
             	 	  set connct_qty $avaliable
             	 	  set elem_rec [lreplace $elem_rec 1 1 0]
             	  } else {
             	 	  set remaining [expr $avaliable - $tmp_qty]
             	 	  set connct_qty $tmp_qty
             	 	  set elem_rec [lreplace $elem_rec 1 1 $remaining]
             	 	  set tmp_qty 0
             	  }
             	  set tl_sup_list($elem_tl_sup_com) [lreplace $tl_sup_list($elem_tl_sup_com) $elem_sup_ix $elem_sup_ix $elem_rec]
             	  #echo "$tl_sup_list($elem_tl_sup_com)"
             	  lappend tl_balance_list [list $elem_tl_sup_com $tl_lot_id $sup_id $connct_qty $elem_tl_sup_com_ix]
             	  if {$tmp_qty == 0} {
             	  	  break
             	  }
              }
          }
     }
  planner unsched $so_lot_id
  lot delete $so_lot_id
  
  #echo "getting consumed commodities for shop order - which are to be balanced in next loop"
  

  foreach elem_bal_dem_list $tl_balance_dem_list {
  	  #echo "$elem_bal_dem_list"
  	  com@location set id [lindex $elem_bal_dem_list 0]
  	  com@location connect [lindex $elem_bal_dem_list 1] [lindex $elem_bal_dem_list 2] [lindex $elem_bal_dem_list 3]
  }
  
  foreach elem_bal_list $tl_balance_list {
#  	  echo "$elem_bal_list"
  	  com@location set id [lindex $elem_bal_list 0]  	  
  	  com@location connect [lindex $elem_bal_list 1] [lindex $elem_bal_list 2] [lindex $elem_bal_list 3] 1 [lindex $elem_bal_list 4]
  }
  
  
  
  planner mode set no_resize_supply_lots off
  # planner mode set no_change_due_date_supply_lots off
  }     
}