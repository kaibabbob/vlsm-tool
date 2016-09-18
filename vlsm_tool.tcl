# VLSM Tool
#
# V0.1 6/15/99 DRR
# V0.2 1/01 DRR Fixed address display bug 
# V1.1 5/03 DRR Added many exciting new features: navigation,
# V1.3 9/16 DRR porting to MAC

# The following is the list of procedures contained in this script in the order they are found.
# The main code is found at the end of the procedures.
#
# Local changes should only have to be made to the Initialize script.
#

# Initialize
# Aggregate
# Build_GUI
# Cleanup
# Create_Navigation
# Decrease_Mask
# Display_Navigation
# Display_Next_Block
# Display_Previous_Block
# Display_Subnet
# enable_subnet
# Increase_Mask_Dn_Right
# Increase_Mask_Up_Right
# Label_Subnets
# NetSort
# Restore_Subnet_Selections
# Scroll_Dn
# Scroll_Up
# select_subnet
# Show_Subnet_Grid
# Update




#--------------------------------------------------------

#------------------------------------------------------------
#  This is the initialization code.  You shouldn't need to modify anything else
#
proc Initialize {} {
 global network address aggregates row_offset col_offset min_mask network_mask max_mask
 global label_count top

	set network 192.168.0.0
	set address {}
	set aggregates {}
	set row_offset 4
	set col_offset 7
	set min_mask 25
	set network_mask 25
	set max_mask 30
	set label_count 0
	set top .top
}

#------------------------------------------------------------
#
#
proc Build_GUI {} {
 global network min_mask base_address top  

	set row_height .15i
	for {set x 5} {$x < 44} {incr x} {
		grid rowconfigure . $x -minsize $row_height
	}


	label .title -text "VLSM Tool" 
	label .network_address_id -text "Enter CIDR Address"
	entry .network_address -width 15 -textvariable base_address
	bind .network_address <Return> Update
	.network_address insert 0 $network

	label .network_mask_id -text "Enter Netmask"
	entry .network_mask -width 2 -textvariable min_mask
	bind .network_mask <Return> Update

	label .selected_subnets_label -text "Subnets Selected" 
	text .selected_subnets -width 17 -height 4  \
		 -bg white -relief sunken  \
	        -yscrollcommand {.ysbar set}
	scrollbar .ysbar -orient vertical  -command {.selected_subnets yview}

	label .aggr_label -text "Aggregate Routes"
	text .aggr -width 17 -height 4  \
		 -bg white -relief sunken  \
	        -yscrollcommand {.aggrysbar set}
	scrollbar .aggrysbar -orient vertical  -command {.aggr yview}

# here
	radiobox_create .aggr_controls ""

	radiobox_add .aggr_controls "Strict Aggregation" {
		set aggr_type strict
	}
	radiobox_add .aggr_controls "Loose Aggregation" {
		set aggr_type loose
	}
	radiobox_add .aggr_controls "Single Aggregate" {
		set aggr_type single
	}
	radiobox_add .aggr_controls "No Aggregation" {
		set aggr_type none
	}

	button .clear -bg grey -text CLEAR -command "Cleanup selections" -relief raised \
	              -borderwidth 5 -pady 4 -padx 4 -width 8

	button .display -bg green -text DISPLAY -command Update -relief raised \
			-borderwidth 5 -pady 4 -padx 4  -width 8

	button .help -bg green -text HELP -command {} -relief raised \
			-borderwidth 5 -pady 4 -padx 4 -width 8

	button .import -bg green -text IMPORT -command {} -relief raised \
			-borderwidth 5 -pady 4 -padx 4 -width 8

	button .exit -bg red -text EXIT -command exit -relief raised \
			-borderwidth 5 -pady 4 -padx 4 -width 8

	label .stats -text "Statistics"
	for {set x 0} {$x <= 30 } {incr x} {
	  label .stats_${x}_id -text "/$x"
	  label .stats_$x -width 3 -background white  -relief sunken
	  label .stats_${x}_hosts -text "[expr (1<<(32-$x)) -2]"
	}

	label .total_hosts_id -text "Total Host Addresses"
	label .total_hosts -width 6 -bg white -relief sunken

	label .total_nets_id -text "Total Networks"
	label .total_nets -width 6 -bg white -relief sunken

	label .prefix_label -text "Prefix Length" -borderwidth 0
	label .sel_count_label -text "Subnets Selected" -borderwidth 0
	label .host_cnt_label -text "Hosts/Subnet" -borderwidth 0


	grid  .title    			-row 0 -column 0 -columnspan 2 
	grid	.network_address_id -row 1 -column 0 
	grid 	.network_mask_id    -row 1 -column 1
	grid 	.network_address    -row 2 -column 0
	grid 	.network_mask       -row 2 -column 1 
 
	grid	.selected_subnets_label -row 3 -column 0 -pady 0 
	grid	.selected_subnets  		-row 4 -column 0  -rowspan 16 -sticky nsew
	grid	.ysbar 			   		-row 4 -column 1  -rowspan 16  -sticky ew
	grid	.aggr_label             -row 21 -column 0 -rowspan 3  -sticky s
	grid	.aggr 			        -row 24 -column 0 -rowspan 10  -sticky nsew
	grid	.aggrysbar         		-row 24 -column 1 -rowspan 10  -sticky ew
	grid	.aggr_controls          -row 24 -column 2 -rowspan 8  -sticky n

	grid	.stats          -row 5 -column 2 -rowspan 2 
	grid	.total_hosts_id -row 7 -column 2  
	grid	.total_hosts    -row 8 -column 2 
	grid	.total_nets_id  -row 10 -column 2 
	grid	.total_nets     -row 11 -column 2 


	grid	.import  -row 35 -column 0 -rowspan 1 -columnspan 1 -sticky n -pady 3
	grid	.display -row 35 -column 1 -rowspan 8 -columnspan 1 -sticky n -pady 3
	grid	.help	 -row 35 -column 2 -rowspan 8 -columnspan 1 -sticky n -pady 3
	grid	.clear   -row 35 -column 0 -rowspan 8 -columnspan 1 -sticky s -pady 3
	grid	.exit	 -row 35 -column 1 -rowspan 8 -columnspan 1 -sticky s -pady 3

	Create_Navigation

}


#------------------------------------------------------------

proc Aggregate {} {
puts "running Aggregate"

  global aggr_type
  global aggregates
  global min_mask
  global max_mask


   set aggregates ""
   for {set mask $max_mask} {$mask >= $min_mask} { incr mask -1} {
	    set subnets [expr 1 << ($mask - $min_mask)]
        for {set x 0} {$x < $subnets} {incr x} {
            if {[.view.$mask,$x cget -bg] == "green"} {
 		        Aggr_list remove .view.$mask,$x
		        .view.$mask,$x configure -bg blue              
            }
        }

    }



   for {set mask $max_mask} {$mask >= [expr $min_mask+1]} { incr mask -1} {

	set subnets [expr 1 << ($mask - $min_mask)]
#count number of nonblue buttons in this column
    set active_cnt 0
    for {set x 0} {$x < $subnets} {incr x} {
        if {[.view.$mask,$x cget -bg] != "blue"} {
            incr active_cnt
        }
    }
    if {($active_cnt < 2) & ($aggr_type != "loose") | ($aggr_type == "none")} {set subnets -1}
	   for {set row 0} {$row < $subnets} {incr row 2} {

           set button_id_0 $mask,$row
           set button_id_1 $mask,[expr $row + 1]
		   set aggr_button_id "[expr $mask - 1],[expr $row/2]"
		   if { [.view.$aggr_button_id cget -bg] == "green" } {
		       .view.$aggr_button_id configure -bg blue
		   }
		   set subnet_status_0 [.view.$button_id_0 cget -bg]
		   set subnet_status_1 [.view.$button_id_1 cget -bg]
		   set states "$subnet_status_0/$subnet_status_1"

	       switch $states {

	          yellow/yellow {
		           Aggr_list add .view.$aggr_button_id
		           .view.$aggr_button_id configure -bg green
	          }

	          green/green {
		           Aggr_list add .view.$aggr_button_id
		           Aggr_list remove .view.$button_id_0
	               Aggr_list remove .view.$button_id_1
		           .view.$aggr_button_id configure -bg green
		           .view.$button_id_0 configure -bg blue
		           .view.$button_id_1 configure -bg blue	
	          }

# ---- mixed fruit	     
	          blue/yellow -
	          yellow/blue {
		         switch $aggr_type {
		            strict {}
		            loose {
		      	        Aggr_list add .view.$aggr_button_id
		      	        .view.$aggr_button_id configure -bg green
		            }
		            single {
		      	        Aggr_list add .view.$aggr_button_id
		      	        .view.$aggr_button_id configure -bg green
		            }
		            default {}
                  }
		      }

	          blue/green -
	          green/blue {
		         switch $aggr_type {
		            strict { }
		            loose  { }
		            single {
			           if {[llength $aggregates] > 1} {
		                  Aggr_list add .view.$aggr_button_id
		                  .view.$aggr_button_id configure -bg green
 		                  if {$subnet_status_0 == "green"} {
		                      Aggr_list remove .view.$button_id_0
		                      .view.$button_id_0 configure -bg blue
		                  }
		                  if {$subnet_status_1 == "green" } {
		                      Aggr_list remove .view.$button_id_1
		                      .view.$button_id_1 configure -bg blue
		                  }
			           }
		            }
		            default {}
	             }
              }

	          yellow/green -
	          green/yellow {
		         Aggr_list add .view.$aggr_button_id
		         .view.$aggr_button_id configure -bg green
 		         if {$subnet_status_0 == "green"} {
		             Aggr_list remove .view.$button_id_0
		             .view.$button_id_0 configure -bg blue
		         }
		         if {$subnet_status_1 == "green" } {
		             Aggr_list remove .view.$button_id_1
		             .view.$button_id_1 configure -bg blue
		         }
	          }
	     

	          default {}
        }  
      }
   }


   if {[.view.$mask,0 cget -bg] == "orange" } {
      .view.$mask,0 configure -bg blue
   }

   set address [lsort -command NetSort $aggregates]

   .aggr delete 1.0 end 
   foreach subnet $address {
      .aggr insert end "$subnet\n"
   }

}
#--------------------------------------------------------
proc Aggr_list {op button_id } {
    global aggregates
    global network

	set net_info [lindex [split $button_id .] end]

	set mask [lindex [split $net_info ,] 0]
	set subnet [lindex [split $net_info ,] end]

	set subnet_addr [expr $subnet * (1 << ([expr 32- $mask]))]


	set octet_4_overflow [expr $subnet_addr/256]
	set subnet_addr [expr $subnet_addr - (256 * $octet_4_overflow)]

	set octet_3 [expr $octet_4_overflow + [lindex [split $network .] 2]]
	set octet_3_overflow [expr $octet_3/256]
	set octet_3 [expr $octet_3 - (256 * $octet_3_overflow)]

	set octet_2 [expr $octet_3_overflow + [lindex [split $network .] 1]]
	set octet_2_overflow [expr $octet_2/256]
	set octet_2 [expr $octet_2 - (256 * $octet_2_overflow)]

	set octet_1 [expr $octet_2_overflow + [lindex [split $network .] 0]]

	set selected_net "$octet_1.$octet_2.$octet_3.$subnet_addr/$mask"
	switch $op {
		add {
			lappend aggregates $selected_net
		}
		remove {
			set index [lsearch $aggregates $selected_net]
			set aggregates [lreplace $aggregates $index $index]
		}
		default {}
	}
}
#--------------------------------------------------------
proc Cleanup {type} {

  global row_offset
  global col_offset
  global network
  global addresss
  global aggregates
  global network_mask
  global max_mask
  global label_count

	for {set col $network_mask} {$col <= 30} {incr col} {

		set subnets [expr 1 << ($col - $network_mask)]

		if {[lsearch [grid slaves .] [subst {.stats_${col}_id}]]} {grid forget .stats_${col}_id}
		if {[lsearch [grid slaves .] [subst {.stats_$col}]] } {grid forget .stats_$col }
		if {[lsearch [grid slaves .] [subst {.stats_${col}_hosts}]]} {grid forget .stats_${col}_hosts }

		if {$subnets > 256} {
			set max_row 256
		} else {
			set max_row $subnets
		}
		for {set row 0} {$row < $max_row} {incr row} {
                set button_id $col,$row
			destroy .view.$button_id 
		}
		destroy .view 
	}


	if {[lsearch [grid slaves .] .prefix_label]} {
	    grid forget .prefix_label
   	 	grid forget .sel_count_label
    	grid forget .host_cnt_label
	}
	if {[lsearch [grid slaves .] .larger_mask] } {
 		grid forget .larger_mask
		grid forget .smaller_mask_0 
		grid forget .smaller_mask_1 
	}


	if {[lsearch [grid slaves .] .scrollup] } {
		grid forget .scrollup
		grid forget .scrolldn
	}

	for {set x 0} {$x < 6} {incr x} {
		if {[lsearch [grid slaves .] [subst {.scrollup-$x}]]} {
			grid forget .scrollup-$x
			grid forget .scrolldn-$x
		}
	}	


	if {$type == "selections"} {
		set address ""
		set aggregates ""

		for {set x 8} {$x <=30} {incr x} {
	  	   .stats_$x configure -text ""
		}

		.selected_subnets delete 1.0 end
	   	.aggr delete 1.0 end 

		.total_hosts configure -text ""
		.total_nets configure -text ""
	}

	for {set label 0} {$label < $label_count} { incr label} {
	    destroy .subnet_addr_$label
	}


}
#--------------------------------------------------------
proc count_nets {} {
    global .stats_30
    global .stats_29
    global .stats_28
    global .stats_27
    global .stats_26
    global .stats_25
    global .stats_24
    global .total_nets

	set nbr_of_nets 0
	set nbr_of_hosts 0

	for {set x 24} {$x < 31} {incr x} {
		set y [.stats_$x cget -text]
		if {$y == ""} {set y 0}
		set hosts [expr $y * ((1<<(32-$x)) -2)]
		if {$y != ""} {
			incr nbr_of_nets $y
			incr nbr_of_hosts $hosts
		}
	}
	.total_nets configure -text $nbr_of_nets
	.total_hosts configure -text $nbr_of_hosts
}
#--------------------------------------------------------
proc count_selected_subnets {} {

 
 global address
 global min_mask
 global max_mask

 #  set address ""

   for {set mask $min_mask} {$mask <= $max_mask} { incr mask} {
	set subnets [expr 1 << ($mask - $min_mask)]

	for {set row 0} {$row < $subnets} {incr row} {
                set button_id $mask,$row
		set subnet_status [.view.$button_id cget -bg]
		if {$subnet_status == "yellow"} {
			VLSM_list add .view.$button_id
		}
	}
   }
   set address [lsort -unique -command NetSort $address]


   .selected_subnets delete 1.0 end 
   foreach subnet $address {
      .selected_subnets insert end "$subnet\n"
   }

}
#--------------------------------------------------------
proc count_subnets mask {
  global min_mask

	set subnets [expr 1 << ($mask - $min_mask)]
	set subnet_count 0
	for {set row 0} {$row < $subnets} {incr row} {
                set button_id $mask,$row
		set subnet_status [.view.$button_id cget -bg]
		if {$subnet_status == "yellow"} {
			incr subnet_count
		}
	}
	if {$subnet_count > 0} { 
		.stats_$mask configure -text $subnet_count
	}
	if {$subnet_count == 0} { 
		.stats_$mask configure -text ""
	}
	count_nets
}

#--------------------------------------------------------
#
# This procedure creates the buttons and labels needed for navigating 
# through the IP address space
#
proc Create_Navigation {} {
	
	for {set x 0} {$x < 6} {incr x} {
		button .scrollup-$x \
				-bg blue \
				-width 30 \
				-relief raised \
				-pady 0 \
				-font {times 1} 
		button .scrolldn-$x \
				-bg blue \
				-width 30 \
				-relief raised \
				-pady 0 \
				-font {times 1}
	}

	label .scrollup -text "Scroll Up"
	label .scrolldn -text "Scroll Down"

	button .larger_mask  -text "<-" -command {Decrease_Mask}
	button .smaller_mask_0 -text "->" -command {Increase_Mask_Up_Right}
	button .smaller_mask_1 -text "->" -command {Increase_Mask_Dn_Right}
	button .jumpup -text " ^ " -command {Display_Previous_Block}
	button .jumpdn -text "\\/" -command {Display_Next_Block}
}

#--------------------------------------------------------
#  This procedure decreases the length of the mask
# and changes the base address to the next lower one if necessary.

proc Decrease_Mask {} {
 global base_address min_mask max_mask
	if {($min_mask - 1) >= 0} {
		incr min_mask -1
		Update_Mask
		set col [expr $min_mask]
		set base_address [VLSM_list get_addr .view.$col,0]
		Update_Address
		Cleanup view
		Show_Subnet_Grid
	}
}
#--------------------------------------------------------
proc Display_Navigation {} {

global row_offset
global col_offset
global network
global min_mask
global base_address
global max_mask button_col

	set scrolling_col [expr $col_offset + $max_mask - $min_mask + 1] 
	set scrolling_row [expr $row_offset + 2 + (1 << ($max_mask - $min_mask))]


	grid	.larger_mask    -row [expr $row_offset -2] -column [expr $col_offset -2] -sticky w
	grid	.jumpup		-row [expr $row_offset -3] -column [expr $col_offset -2] -sticky n
	grid	.jumpdn		-row [expr $row_offset -1] -column [expr $col_offset -2] -sticky s
	grid	.smaller_mask_0 -row [expr $row_offset -3] -column [expr $col_offset -1] -sticky e
	grid	.smaller_mask_1 -row [expr $row_offset -1] -column [expr $col_offset -1] -sticky e

#  this was from new feature testing
#	grid	.scrollup -row $scrolling_row -column [expr $col_offset -1] -sticky w 
#	grid	.scrolldn -row [expr $scrolling_row + 1] -column [expr $col_offset -1] -sticky w 

	set scrolling_col [expr $col_offset] 
	set mask_length $min_mask

	for {set x 0} {$x <= ($max_mask - $min_mask )} {incr x} {
#		.scrollup-$x configure -command "Scroll-Up $mask_length"
#		.scrolldn-$x configure -command "Scroll-Dn $mask_length"
#		grid .scrollup-$x -row $scrolling_row -column $scrolling_col -sticky nsew
#		grid .scrolldn-$x -row expr $scrolling_row + 1] -column $scrolling_col -sticky nsew 

		incr mask_length
		incr scrolling_col
	}
}

#--------------------------------------------------------
#  This procedure moves the base address down one window

proc Display_Next_Block  {} {
 global base_address next_addr

	set base_address $next_addr
	Update_Address
	Cleanup view
	Show_Subnet_Grid

}
#--------------------------------------------------------
#  This procedure moves the base address up one window

proc Display_Previous_Block  {} {
 global base_address prev_addr

	set base_address $prev_addr
	Update_Address
	Cleanup view
	Show_Subnet_Grid

}
#--------------------------------------------------------
proc Display_Subnet button_id {

  global min_mask
  global max_mask
  global aggr_type

	$button_id configure -bg blue
	set net_info [lindex [split $button_id .] end]
	set bits [lindex [split $net_info ,] 0]
	set subnet [lindex [split $net_info ,] end]
	VLSM_list remove $button_id

# Clear Grey buttons
	for {set x [expr $bits + 1]} {$x <= $max_mask} {incr x} {
		set first_subnet [expr $subnet * (1 << ($x - $bits))]
		set last_subnet [expr $first_subnet + (1 << ($x - $bits)) -1]
		for {set y $first_subnet} {$y <= $last_subnet} {incr y} {
			.view.$x,$y configure -bg blue
		}
		count_subnets $x
	}
	count_subnets $bits
	count_selected_subnets
#	if {$aggr_type != "none"} {
	   Aggregate
#	}

}

#--------------------------------------------------------
proc enable_subnet button_id {
  global aggr_type address

	$button_id configure -bg yellow

	VLSM_list add $button_id

	Greyout_Subnets $button_id


#    if {$aggr_type != "none"} {
		Aggregate
#    }

}

#--------------------------------------------------------
proc Greyout_Subnets button_id {
  global min_mask
  global max_mask
  global aggr_type address

	set net_info [lindex [split $button_id .] end]
	set bits [lindex [split $net_info ,] 0]
	set subnet [lindex [split $net_info ,] end]

	for {set x [expr $bits + 1]} {$x <= $max_mask} {incr x} {
		set first_subnet [expr $subnet * (1 << ($x - $bits))]
		set last_subnet [expr $first_subnet + (1 << ($x - $bits)) -1]
		for {set y $first_subnet} {$y <= $last_subnet} {incr y} {
			.view.$x,$y configure -bg grey
		}
		count_subnets $x
	}
	count_subnets $bits
	count_selected_subnets
}

#--------------------------------------------------------
#  This procedure increases the length of the mask
# and changes the base address to the next higher one.

proc Increase_Mask_Dn_Right {} {
 global base_address min_mask max_mask
	if {($min_mask + 1) <= $max_mask} {
		incr min_mask 1
		Update_Mask
		set col [expr $min_mask]
		set base_address [VLSM_list get_addr .view.$col,1]
		Update_Address
		Cleanup view
		Show_Subnet_Grid
	}
}
#--------------------------------------------------------
#  This procedure increases the length of the mask
# and keeps the same base address

proc Increase_Mask_Up_Right  {} {
 global min_mask max_mask
	if {($min_mask + 1) <= $max_mask} {
		incr min_mask 1
		Update_Mask
		Cleanup view
		Show_Subnet_Grid
	}
}
#---------------------------------------------------------------------------
#
#  This procedure places the labels on the right side of the screen:
#	column heading labels and the starting address for the subnets
#
proc Label_Subnets {} {
  global min_mask
  global col_offset
  global row_offset
  global max_mask
  global label_count

	set label_count 0
	set subnets [expr 1 << ($max_mask - $min_mask)]

	set button_info  [grid info .view]
	set button_info [string trim $button_info]
	set button_row 5 
	set button_col [lindex  [split $button_info] 5] 

	set addr_col [expr $button_col + $max_mask - $min_mask +3]

	for {set row 0} {$row < $subnets} {incr row} {
	    if {[expr fmod($row,4.0)] == 0} {
			set address [VLSM_list get_addr .view.$max_mask,$row]
			set addr_row [expr $button_row + $row]
    		label .subnet_addr_$label_count -text $address -borderwidth 0
    		grid  .subnet_addr_$label_count -row $addr_row -column $addr_col    \
											-sticky nw

	        incr label_count
	    }
	}

	grid	.prefix_label    -row 1 -column $addr_col
	grid	.sel_count_label -row 2 -column $addr_col
	grid	.host_cnt_label  -row 3 -column $addr_col
}

#--------------------------------------------------------
proc NetSort {net_1 net_2} {

 set octet_4_1 [lindex [split [lindex [split $net_1 .] 3] / ] 0]
 set octet_4_2 [lindex [split [lindex [split $net_2 .] 3] / ] 0]

return [expr $octet_4_1 - $octet_4_2]
}


#--------------------------------------------------------
proc radiobox_add { win choice {command ""  }} {
	global rbInfo
	set name "$win.border.rb[incr rbInfo($win-count)]"
	radiobutton $name -text $choice -command $command \
		-variable rbInfo($win-current) -value $choice
	pack $name -side top -anchor w
	if {$rbInfo($win-count) ==1} {
		$name invoke
	}
}
#--------------------------------------------------------
proc radiobox_create { win {title ""}} {
	global rbInfo
	set rbInfo($win-current) ""
	set rbInfo($win-count) 0

	frame $win -class Radiobox
	if {$title !=""} {
		label $win.title -text $title
		pack $win.title -side top
	}
	frame $win.border -borderwidth 2 -relief groove
	pack $win.border -expand yes -fill both
	bind $win <Destroy> "radiobox_destroy $win"
	return $win
}
#--------------------------------------------------------
proc Restore_Subnet_Selections {} {

# Created 6/07 to be able to update the grid based on the current entries in the address list
# to be applied after shifting the view 

global min_mask
global max_mask
global address

	set offset 0

	for {set col $min_mask} {$col <= $max_mask} {incr col} {
		set subnets [expr 1 << ($col - $min_mask)]

		incr offset

		for {set row 0} {$row < $subnets} {incr row} {
	                set button_id $col,$row

			set button_network [VLSM_list get_addr $button_id]\/$col

			if {[lsearch $address $button_network] >=0} {
				enable_subnet .view.$button_id
			}

		}
	  }

}
#--------------------------------------------------------
proc select_subnet button_id {
	set state [split [$button_id configure -bg]]
	switch [lindex $state end] {
		blue {enable_subnet $button_id}
		green {enable_subnet $button_id}
		yellow {Display_Subnet $button_id}
		default {}
	} 
}


#--------------------------------------------------------
proc Scroll_Dn {mask} {

}
#--------------------------------------------------------
proc Scroll_Up {mask} {

}

#--------------------------------------------------------
proc Show_Subnet_Grid {} {


global row_offset
global col_offset
global network
global min_mask
global base_address
global max_mask
global address

	set offset 0
	canvas .view 

	grid	.view -row [expr $row_offset +1] -column $col_offset \
				-rowspan [expr 1 << ($max_mask - $min_mask)] \
				-columnspan [expr $max_mask - $min_mask + 1] \
				-sticky nsew

	for {set col $min_mask} {$col <= $max_mask} {incr col} {
		set subnets [expr 1 << ($col - $min_mask)]

		grid .stats_${col}_id -row [expr $row_offset -3] -column [expr $col_offset + $offset]
		grid .stats_$col      -row [expr $row_offset -2] -column [expr $col_offset + $offset]
		grid .stats_${col}_hosts -row [expr $row_offset -1] -column [expr $col_offset + $offset]
		incr offset

		for {set row 0} {$row < $subnets} {incr row} {
	                set button_id $col,$row

			button .view.$button_id \
				-bg blue \
				-width 30 \
				-relief raised \
				-pady 0 \
				-command "select_subnet .view.$button_id " \
				-font {times 1}

puts "view.$button_id : [expr 1 << ($max_mask -$col)]"
			grid .view.$button_id \
				-row [expr $row * ([expr 1 << ($max_mask -$col)])] \
				-column [expr $col - $min_mask] \
				-rowspan [expr 1 << ($max_mask -$col)] \
				-sticky nsew
			set row_height .15i
			grid rowconfigure .view $row -minsize $row_height

		}
	  }
	Label_Subnets
	Display_Navigation
	Restore_Subnet_Selections

}

#--------------------------------------------------------
proc Update {} {
	Cleanup selections
	set good_addr [Update_Address]
	set good_mask [Update_Mask]
	if {($good_addr == 0) & ($good_mask ==0 )} { Show_Subnet_Grid }

}
#--------------------------------------------------------
proc Update_Address {} {
# The address for the jump up and down buttons is computed here for possible future use
  global base_address
  global network
  global min_mask
  global network_mask
  global address_value prev_addr next_addr

  set address_check bad


  set octet_1 [lindex [split $base_address .] 0]
  set octet_2 [lindex [split $base_address .] 1]
  set octet_3 [lindex [split $base_address .] 2]
  set octet_4 [lindex [split $base_address .] 3]
  set octet_5 [lindex [split $base_address .] 4]

  if {($octet_1 >= 0) & ($octet_1 < 256)} {
     if {($octet_2 >= 0) & ($octet_2 < 256)} {
        if {($octet_3 >= 0) & ($octet_3 < 256)} {
           if {($octet_4 >= 0) & ($octet_4 < 256)} {
              if {$octet_5 == "" } {
		set address_check good
		if {$min_mask >= 24} {
		   set mask_field [expr 256 - [expr 1 << (32 - $min_mask)]]
		   set octet_4 [expr $octet_4 & $mask_field]
		} elseif {$min_mask >= 16} {
		   set octet_4 0
		   set mask_field [expr 256 - [expr 1 << (24 - $min_mask)]]
		   set octet_3 [expr $octet_3 & $mask_field]	
 		} elseif {$min_mask >= 8} {
		   set octet_4 0
		   set octet_3 0
		   set mask_field [expr 256 - [expr 1 << (16 - $min_mask)]]
		   set octet_2 [expr $octet_2 & $mask_field]	
		} elseif {$min_mask >= 0} {
		   set octet_4 0
		   set octet_3 0
		   set octet_2 0
		   set mask_field [expr 256 - [expr 1 << (8 - $min_mask)]]
		   set octet_1 [expr $octet_1 & $mask_field]	
		}
		set network "$octet_1.$octet_2.$octet_3.$octet_4"
    		.network_address delete 0 end
    		.network_address insert 0 $network
              }	 
           }	 
        }	
     }	
  }
  if {$address_check != "good"} {
    .network_address delete 0 end
    .network_address insert 0 $network
    return 1
  }

  set address_value [expr $octet_1 * pow(2,24) + $octet_2 * pow(2,16) +  $octet_3 * pow(2,8) + $octet_4] 

  set prev_address [expr $address_value - pow(2,32-$min_mask)]

  if {$prev_address < 0} { set prev_address 0}

  set octet_1 [expr int($prev_address/pow(2,24))]
  set prev_address [expr $prev_address - $octet_1*pow(2,24)]
  set octet_2 [expr int($prev_address/pow(2,16))]
  set prev_address [expr $prev_address - $octet_2*pow(2,16)]
  set octet_3 [expr int($prev_address/pow(2,8))]
  set prev_address [expr $prev_address - $octet_3*pow(2,8)]
  set octet_4 [expr int($prev_address)]
  set prev_addr "$octet_1\.$octet_2\.$octet_3\.$octet_4"

  set next_address [expr $address_value + pow(2,32-$min_mask)]
  if {$next_address >= [expr pow(2,32)]} { set next_address $address_value}

  set octet_1 [expr int($next_address/pow(2,24))]
  set next_address [expr $next_address - $octet_1*pow(2,24)]
  set octet_2 [expr int($next_address/pow(2,16))]
  set next_address [expr $next_address - $octet_2*pow(2,16)]
  set octet_3 [expr int($next_address/pow(2,8))]
  set next_address [expr $next_address - $octet_3*pow(2,8)]
  set octet_4 [expr int($next_address)]
  set next_addr "$octet_1\.$octet_2\.$octet_3\.$octet_4"


  return 0
}

#--------------------------------------------------------
proc Update_Mask {} {
 global base_address
 global min_mask
 global network_mask
 global max_mask

    if {($min_mask >= 0) & ($min_mask <=30 ) } {


  	set network_mask $min_mask
   	if {$min_mask < 25} {
	    	set max_mask [expr $min_mask + 5]
   	} else {set max_mask 30}

# apply the mask to the base address to zero out the any bits
	set octet_1 [lindex [split $base_address .] 0]
	set octet_2 [lindex [split $base_address .] 1]
	set octet_3 [lindex [split $base_address .] 2]
	set octet_4 [lindex [split $base_address .] 3]

	if {$min_mask >= 24} {
	   set mask_field [expr 256 - [expr 1 << (32 - $min_mask)]]
	   set octet_4 [expr $octet_4 & $mask_field]
	} elseif {$min_mask >= 16} {
	   set octet_4 0
	   set mask_field [expr 256 - [expr 1 << (24 - $min_mask)]]
	   set octet_3 [expr $octet_3 & $mask_field]	
	} elseif {$min_mask >= 8} {
	   set octet_4 0
	   set octet_3 0
	   set mask_field [expr 256 - [expr 1 << (16 - $min_mask)]]
	   set octet_2 [expr $octet_2 & $mask_field]	
	} elseif {$min_mask >= 0} {
	   set octet_4 0
	   set octet_3 0
	   set octet_2 0
	   set mask_field [expr 256 - [expr 1 << (8 - $min_mask)]]
	   set octet_1 [expr $octet_1 & $mask_field]	
	}
	set network "$octet_1.$octet_2.$octet_3.$octet_4"
		.network_address delete 0 end
		.network_address insert 0 $network


    } else { 
	set min_mask $network_mask
	return 1
    }
 
    return 0
}
#--------------------------------------------------------
proc VLSM_list {op button_id } {
    global address
    global network base_address

# Get each of the base octets
	set octet_1 [lindex [split $base_address .] 0]
	set octet_2 [lindex [split $base_address .] 1]
	set octet_3 [lindex [split $base_address .] 2]
	set octet_4 [lindex [split $base_address .] 3]

	set net_info [lindex [split $button_id .] end]
	set mask [lindex [split $net_info ,] 0]
	set subnet [lindex [split $net_info ,] end]
	set subnet_addr [expr $subnet * (1 << ([expr 32- $mask])) + $octet_4]

	set octet_4_overflow [expr $subnet_addr/256]
	set subnet_addr [expr $subnet_addr - (256 * $octet_4_overflow)]

	set octet_3 [expr $octet_4_overflow + [lindex [split $network .] 2]]
	set octet_3_overflow [expr $octet_3/256]
	set octet_3 [expr $octet_3 - (256 * $octet_3_overflow)]

	set octet_2 [expr $octet_3_overflow + [lindex [split $network .] 1]]
	set octet_2_overflow [expr $octet_2/256]
	set octet_2 [expr $octet_2 - (256 * $octet_2_overflow)]

	set octet_1 [expr $octet_2_overflow + [lindex [split $network .] 0]]

	set selected_net "$octet_1.$octet_2.$octet_3.$subnet_addr/$mask"
	switch $op {
		add {
			lappend address $selected_net
		}
		remove {
			set index [lsearch $address $selected_net]
			set address [lreplace $address $index $index]
		}
		get_addr {
			return [lindex [split $selected_net /] 0]
		}
		default {}
	}
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------



Initialize
Build_GUI
#Show_Subnet_Grid
Cleanup selections
#console show
