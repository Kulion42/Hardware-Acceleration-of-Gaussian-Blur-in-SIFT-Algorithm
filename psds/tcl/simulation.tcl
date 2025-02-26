set PROJECT_NAME              gaussian_blur_rtl
set PROJECT_CONSTRAINT_FILE ../constraints/Zybo-Z7-Master.xdc

set DIR_OUTPUT ../tb/project_gaussian_blur
            
file mkdir ${DIR_OUTPUT}

create_project ${PROJECT_NAME} ${DIR_OUTPUT}/${PROJECT_NAME} -part xc7z010clg400-1 -force
#Simulation sources
add_files -norecurse -fileset sim_1 {../tb/convolute_loops_tb/check_convolution_tb.vhd}
#add_files -norecurse -fileset sim_1 {../tb/convolute_loops_tb/check_convolution_tb_behav.wcfg }
add_files -norecurse -fileset sim_1 {../tb/convolute_loops_tb/check_gaussian_blur.vhd}
#add_files -norecurse -fileset sim_1 {../tb/convolute_loops_tb/check_gaussian_blur_behav.wcfg }
add_files -norecurse -fileset sim_1 {../tb/convolute_loops_tb/check_top_model.vhd}
add_files -norecurse -fileset sim_1 {../tb/convolute_loops_tb/check_top_model_behav.wcfg }
#Design sources
add_files -norecurse {../rtl/dsp_unit_add.vhd}
add_files -norecurse {../rtl/dsp_unit_mac_shift.vhd}
add_files -norecurse {../rtl/dsp_unit_mul_shift.vhd}
add_files -norecurse {../rtl/utils_pkg.vhd}
add_files -norecurse {../tb/convolute_loops_tb/txt_util.vhd}
add_files -norecurse {../rtl/kernel_rom.vhd}
add_files -norecurse {../rtl/convolute_loops.vhd}
add_files -norecurse {../rtl/bram.vhd}
add_files -norecurse {../tb/convolute_loops_tb/bram1.vhd}
add_files -norecurse {../tb/convolute_loops_tb/bram2.vhd}
add_files -norecurse {../rtl/gaussian_blur.vhd}
add_files -norecurse {../rtl/top_model.vhd}

set_property file_type {VHDL 2008} [get_files ../tb/convolute_loops_tb/check_top_model.vhd]
set_property file_type {VHDL 2008} [get_files ../tb/convolute_loops_tb/check_gaussian_blur.vhd]
set_property file_type {VHDL 2008} [get_files ../tb/convolute_loops_tb/check_convolution_tb.vhd]
set_property top check_top_model [get_filesets sim_1]

import_files -force

import_files -fileset constrs_1 -force -norecurse ${PROJECT_CONSTRAINT_FILE}

# Mimic GUI behavior of automatically setting top and file compile order

update_compile_order -fileset sources_1
set_property xsim.view {../tb/convolute_loops_tb/check_convolution_tb_behav.wcfg } [get_filesets sim_1]

launch_simulation

add_wave {{/check_top_model/TOP/gauss_blur/end_y_conv}} 
add_wave {{/check_top_model/TOP/gauss_blur/start_x_conv}}
add_wave {{/check_top_model/TOP/gauss_blur/main_bram_b_we}} {{/check_top_model/TOP/gauss_blur/main_bram_b_addr}} {{/check_top_model/TOP/gauss_blur/tmp_bram_a_we}} {{/check_top_model/TOP/gauss_blur/tmp_bram_a_addr}} {{/check_top_model/TOP/gauss_blur/tmp_bram_b_we}} {{/check_top_model/TOP/gauss_blur/tmp_bram_b_addr}} 


run 20 ms
start_gui
