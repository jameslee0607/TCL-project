proc adjust_periodmgr_elem { } {
   global env db_params
   global uds_case_id   
   if {[string index $db_params(import_case) 0] != "_"} {
      set uds_case_id _$db_params(import_case)
   } else {
     set uds_case_id $db_params(import_case)
   }   
   set table_name_dest "PERIODMGRELEM$uds_case_id\_"   
   rdb close
   rdb open ORACLE $db_params(database_servicename) $db_params(dbuser_id) $db_params(password) "" ""
   rdb delete $db_params(database_servicename) "" $table_name_dest ""
   rdb bulkopeninsert $db_params(database_servicename) "" $table_name_dest
   cal period_mgr set ix 0
   set period_id [cal period_mgr get id]
   for {set i 0} {$i < [cal period get number]} {incr i} {
       cal period set ix $i   
       set period_end [cast time date3 [cal period get end]]    
       rdb bulkinsert $db_params(database_servicename) "" $table_name_dest $period_id $period_end      
  }
  rdb bulkcloseinsert $db_params(database_servicename) "" $table_name_dest
  rdb close     
}

adjust_periodmgr_elem