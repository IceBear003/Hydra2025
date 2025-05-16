set output_subdir "$output_dir/$module"
if {![file exists "$output_subdir"]} { file mkdir "$output_subdir"}
#Report Design
#set name rules for output, important when verilog is converted to spice
define_name_rules verilog -case_insensitive
change_names -hierarchy -rules verilog

#write data
write -h -format verilog -output "$output_subdir/code_gate.v"
write -format ddc -output -hierarchy "$output_subdir/code_gate.ddc"
write_sdc "$output_subdir/code_gate.sdc"
write_sdf "$output_subdir/code_gate.sdf"

#report
redirect -append -tee "$output_subdir/Report_area.txt" {report_area -nosplit -hierarchy}
# redirect -append -tee "$output_subdir/Report_power.txt" {report_power -hier -hier_level 100 -analysis_effort high}
# redirect -append -tee "soutput subdir/Report_power_netcell.txt" {report_power -net -cell -analysis effort high -sort_mode dynamic_power}
redirect -append -tee "$output_subdir/Report_clock.txt" {report_clock -nosplit}
redirect -append -tee "$output_subdir/Report_timing.txt" {report_timing -path full -delay max -nworst 1 -max_paths 3 -significant_digits 3 -sort_by group}
# redirect -append -tee "$output_subdir/Report_operand_isolation.txt" {report_isolation_cell}
redirect -append -tee "$output_subdir/Report_clock_gating.txt" \
{report_clock_gating -gating_elements -gated}