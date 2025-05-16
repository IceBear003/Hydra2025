source -echo ./variables.tcl
source -echo ./libraries.tcl
source -echo ./reorganize.tcl

set module "uuu_fp18_add"
set should_compile 1
set do_clock_gating 1
source -echo ./compile.tcl

set module "uus_fp18_sub"
set should_compile 1
set do_clock_gating 1
source -echo ./compile.tcl

set module "uuu_fp18_acc"
set should_compile 1
set do_clock_gating 1
source -echo ./compile.tcl

set module "usu_fp18_add"
set should_compile 1
set do_clock_gating 1
source -echo ./compile.tcl