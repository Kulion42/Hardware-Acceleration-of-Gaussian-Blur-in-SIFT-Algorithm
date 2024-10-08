set PROJECT_NAME              gaussian_blur_rtl
set PROJECT_CONSTRAINT_FILE ./constraints/Zybo-Z7-Master.xdc

set DIR_OUTPUT project_gaussian_blur
            
file mkdir ${DIR_OUTPUT}

create_project ${PROJECT_NAME} ${DIR_OUTPUT}/${PROJECT_NAME} -part xc7z010clg400-1 -force

add_files -norecurse -fileset sim_1 {tb/convolute_loops_tb/check_convolution_tb.vhd}
add_files -norecurse -fileset sim_1 {tb/convolute_loops_tb/check_convolution_tb_behav.wcfg }
add_files -norecurse {rtl/dsp_unit_add.vhd}
add_files -norecurse {rtl/dsp_unit_mac_shift.vhd}
add_files -norecurse {rtl/dsp_unit_mac_shift2.vhd}
add_files -norecurse {rtl/utils_pkg.vhd}
add_files -norecurse {tb/convolute_loops_tb/txt_util.vhd}
add_files -norecurse {rtl/kernel_rom.vhd}
add_files -norecurse {rtl/convolute_loops.vhd}
add_files -norecurse {rtl/bram.vhd}
add_files -norecurse {tb/convolute_loops_tb/bram1.vhd}
add_files -norecurse {rtl/gaussian_blur.vhd}
add_files -norecurse {rtl/top_model.vhd}

set_property file_type {VHDL 2008} [get_files rtl/kernel_rom.vhd]

import_files -force

import_files -fileset constrs_1 -force -norecurse ${PROJECT_CONSTRAINT_FILE}

# Mimic GUI behavior of automatically setting top and file compile order

update_compile_order -fileset sources_1
set_property xsim.view {tb/convolute_loops_tb/check_convolution_tb_behav.wcfg } [get_filesets sim_1]
# Launch Synthesis and wait on completion
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
launch_runs synth_1
wait_on_run synth_1
open_run synth_1 -name netlist_1

# Generate a timing and power reports and write to disk
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -file ${DIR_OUTPUT}/syn_timing.rpt
report_power -file ${DIR_OUTPUT}/syn_power.rpt

# Launch Implementation
launch_runs impl_1 #-to_step write_bitstream
wait_on_run impl_1 

# Generate a timing and power reports and write to disk
# comment out the open_run for batch mode
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -file ${DIR_OUTPUT}/imp_timing.rpt
report_power -file ${DIR_OUTPUT}/imp_power.rpt


# comment out the for batch mode
start_gui
