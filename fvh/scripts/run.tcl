# Usage:
#   vivado -mode tcl -source run_combined.tcl [test_name] [test_count]
#   test_mode: UVM test name (default: simple_test)
#   test_count: Number of runs (default: 1)

set test_mode "simple"
set test_count 1


if {$argc > 0} {
    set test_mode [lindex $argv 0]
}
if {$argc > 1} {
    set test_count [lindex $argv 1]
}

if {$test_count > 300} {
    puts "Error: Too big test_count. At least one test will be repeated"
    exit 1
}

# --- Common setup ---
cd ..
set root_dir [pwd]
cd scripts

puts "Running test: $test_mode for $test_count times"
if {$test_mode == "rand"} {
    set resultDir ../uvm_project_rand
} else {
    set resultDir ../uvm_project
}
file mkdir $resultDir
create_project gaussian_blur_verif $resultDir -part xc7z010clg400-1 -force
set_property board_part digilentinc.com:zybo-z7-10:part0:1.1 [current_project]

# Add RTL files
add_files -norecurse ../../psds/rtl/gaussian_blur_v1_0.vhd
add_files -norecurse ../../psds/rtl/gaussian_blur_v1_0_S00_AXI.vhd
add_files -norecurse ../../psds/rtl/top_model.vhd
add_files -norecurse ../../psds/rtl/gaussian_blur.vhd
add_files -norecurse ../../psds/rtl/memory_subsystem.vhd
add_files -norecurse ../../psds/rtl/bram.vhd
add_files -norecurse ../../psds/rtl/convolute_loops.vhd
add_files -norecurse ../../psds/rtl/kernel_rom.vhd
add_files -norecurse ../../psds/rtl/dsp_unit_mac_shift.vhd
add_files -norecurse ../../psds/rtl/dsp_unit_mul_shift.vhd
add_files -norecurse ../../psds/rtl/dsp_unit_add.vhd
add_files -norecurse ../../psds/rtl/utils_pkg.vhd

update_compile_order -fileset sources_1

set_property SOURCE_SET sources_1 [get_filesets sim_1]

# Add common verification files (adjust as needed)
add_files -fileset sim_1 -norecurse ../verif/agent/agent_pkg.sv
add_files -fileset sim_1 -norecurse ../verif/agent_rand/agent_rand_pkg.sv
add_files -fileset sim_1 -norecurse ../verif/config/gaussian_blur_config_pkg.sv
add_files -fileset sim_1 -norecurse ../verif/config/gaussian_blur_config_rand_pkg.sv
add_files -fileset sim_1 -norecurse ../verif/sequences/seq_pkg.sv
add_files -fileset sim_1 -norecurse ../verif/sequences/seq_rand_pkg.sv
add_files -fileset sim_1 -norecurse ../verif/test_pkg.sv
add_files -fileset sim_1 -norecurse ../verif/test_rand_pkg.sv
add_files -fileset sim_1 -norecurse ../verif/gaussian_blur_if.sv
add_files -fileset sim_1 -norecurse ../verif/gaussian_blur_top.sv


update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Vivado/XSIM properties
set_property -name {xsim.elaborate.mt_level} -value {off} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {-v 1} -objects [get_filesets sim_1]
set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects [get_filesets sim_1]

# Run regression
set test_name [expr {$test_mode == "rand" ? "rand_test" : "simple_test"}]
for {set i 0} {$i < $test_count} {incr i} {
    set db_name "covdb_$i"
    set xsim_command "set_property -name \{xsim.simulate.xsim.more_options\} -value \{-testplusarg UVM_TESTNAME=$test_name -testplusarg UVM_VERBOSITY=UVM_LOW -sv_seed random -runall -cov_db_name $db_name\} -objects \[get_filesets sim_1\]"
    eval $xsim_command
    launch_simulation
    run all
    if {$i+1 < $test_count} {
        close_sim
        puts "Test $i is over !!!!"
    }
}
exec xcrg -report_format html -dir $resultDir/gaussian_blur_verif.sim/sim_1/behav/xsim -report_dir $resultDir/coverage
puts "Regression is over !!!!"
exit 0
