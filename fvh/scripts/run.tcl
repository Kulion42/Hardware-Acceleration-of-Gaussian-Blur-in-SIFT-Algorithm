cd ..
set root_dir [pwd]
cd scripts
set resultDir ../uvm_project

if {$argc > 1} {
    puts "Error: Too many arguments. Usage: $argv0 [<test_count>]"
    exit 1
}

# Set the default value to 1 if no argument is provided
if {$argc == 0} {
    set test_count 1
} else {
    set test_count [lindex $argv 0]
}

if {$test_count > 300} {
    puts "Error: Too big test_count. At least one test will be reapeted"
    exit 1
}

file mkdir $resultDir

create_project gaussian_blur_verif $resultDir -part xc7z010clg400-1 -force
set_property board_part digilentinc.com:zybo-z7-10:part0:1.2 [current_project]


# Ukljucivanje svih izvornih i simulacionih fajlova u projekat

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
add_files -fileset sim_1 -norecurse ../verif/agent/agent_pkg.sv
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../verif/config/gaussian_blur_config_pkg.sv
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../verif/sequences/seq_pkg.sv
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../verif/test_pkg.sv
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../verif/gaussian_blur_if.sv
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../verif/gaussian_blur_top.sv

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

#Povecanje osjetljivosti(verbosity) elaboracije

set_property -name {xsim.elaborate.mt_level} -value {off} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {-v 1} -objects [get_filesets sim_1]

# Ukljucivanje uvm biblioteke

set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects [get_filesets sim_1]
#set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg UVM_TESTNAME=simple_test -testplusarg UVM_VERBOSITY=UVM_LOW -sv_seed random} -objects [get_filesets sim_1]

#Pokretanje regresije
for {set i 0} {$i < $test_count} {incr i} {
    set db_name "covdb_$i" ;
    set xsim_command "set_property -name \{xsim.simulate.xsim.more_options\} -value \{-testplusarg UVM_TESTNAME=simple_test -testplusarg UVM_VERBOSITY=UVM_LOW -sv_seed random -runall -cov_db_name $db_name\} -objects \[get_filesets sim_1\]"
    eval $xsim_command
    launch_simulation
    #add_wave {{/gaussian_blur_top/DUT/top_model_instance/gauss_blur/y_conv_gen/bram1_b_addr}} {{/gaussian_blur_top/DUT/top_model_instance/gauss_blur/y_conv_gen/c_x2_vec}} {{/gaussian_blur_top/DUT/top_model_instance/gauss_blur/y_conv_gen/c_y_vec}} {{/gaussian_blur_top/DUT/top_model_instance/gauss_blur/y_conv_gen/img_w2}} 
    run all
    #start_gui
    if {$i+1 < $test_count} {
        close_sim
		puts "Test $i is over !!!!"
    }
}
exec xcrg -report_format html -dir uvm_project/gaussian_blur_verif.sim/sim_1/behav/xsim -report_dir coverage
puts "Regression is over !!!!"


