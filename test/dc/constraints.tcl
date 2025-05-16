set_ideal_network [get_ports clk]

# create_clock -period 2 [get_ports clk]
# set_clock_uncertainty -setup 0.1 [get_clocks clk]
# set_clock_uncertainty -hold 0.05 [get_clocks clk]
# set_clock_transition 0.05 [get_clocks clk]
# set_clock_latency 0 [get_clocks clk]

create_clock -period 5 [get_ports clk]
set_clock_uncertainty -setup 0.25 [get_clocks clk]
set_clock_uncertainty -hold 0.125 [get_clocks clk]
set_clock_transition 0.125 [get_clocks clk]
set_clock_latency 0 [get_clocks clk]

set all_input_but_clock [remove_from_collection [all_inputs] {clk}]
set_input_delay -max 0.2 -clock clk $all_input_but_clock
set_input_delay -min 0.1 -clock clk $all_input_but_clock
set_output_delay -max 0.2 -clock clk [all_outputs]
set_output_delay -min 0.1 -clock clk [all_outputs]

set_load 0.01 [all_outputs]

remove_unconnected_ports [get_cells -hier *] -blast_buses

set_max_area 0
set_fix_hold [all_clocks]

set verilogout_show_unconnected_pins true
set verilogout_no_tri true

set_fix_multiple_port_nets -all -buffer_constants

set compile_keep_original_for_external_references true