analyze -format verilog "$rtl_dir/$module.v"
elaborate $module

current_design $module

link

source ./constraints.tcl

if {$do_clock_gating>0} {
    puts "clock gating is inserted"
    set compile_clock_gating_through_hierarchy true 
    insert_clock_gating -global
}

set_leakage_optimization true
set_dynamic_optimization true

if {$should_compile>0} {
    compile_ultra
}

redirect -append -tee "$output_dir/reports/$module.rpt" {report_constraint -all}
write_file -format ddc -hierarchy -output $ddc_dir/$module.ddc

source ./report.tcl