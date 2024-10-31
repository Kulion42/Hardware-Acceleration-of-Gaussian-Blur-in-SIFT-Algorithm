# Stvaranje direktorijuma u kojem ce biti smesten projekat
#cd ..
file mkdir project_folder
cd project_folder

# Stvaranje projekta
create_project gaussian_blur_project gaussian_blur_project -part xc7z010clg400-1
set_property board_part digilentinc.com:zybo-z7-10:part0:1.2 [current_project]
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

# Otvaranje novog projekta za pakovanj IP jezgra
create_peripheral xilinx.com user gaussian_blur_ip 1.0 -dir ip_repo
add_peripheral_interface S00_AXI -interface_mode slave -axi_type lite [ipx::find_open_core xilinx.com:user:gaussian_blur_ip:1.0]
set_property VALUE 8 [ipx::get_bus_parameters WIZ_NUM_REG -of_objects [ipx::get_bus_interfaces S00_AXI -of_objects [ipx::find_open_core xilinx.com:user:gaussian_blur_ip:1.0]]]
add_peripheral_interface S01_AXI -interface_mode slave -axi_type full [ipx::find_open_core xilinx.com:user:gaussian_blur_ip:1.0]




set_property VALUE 4096 [ipx::get_bus_parameters WIZ_MEMORY_SIZE -of_objects [ipx::get_bus_interfaces S01_AXI -of_objects [ipx::find_open_core xilinx.com:user:gaussian_blur_ip:1.0]]]




generate_peripheral -driver -bfm_example_design -debug_hw_example_design [ipx::find_open_core xilinx.com:user:gaussian_blur_ip:1.0]
write_peripheral [ipx::find_open_core xilinx.com:user:gaussian_blur_ip:1.0]
set_property  ip_repo_paths  ip_repo/gaussian_blur_ip_1.0 [current_project]
update_ip_catalog -rebuild
ipx::edit_ip_in_project -upgrade true -name edit_gaussian_blur_ip_v1_0 -directory ip_repo ip_repo/gaussian_blur_ip_1.0/component.xml
update_compile_order -fileset sources_1


# Ucitavanje potrebnih fajlova i podesavanje vrha hijerarhije
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../gaussian_blur_v1_0_S01_AXI.vhd
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../dsp_unit_mac_shift.vhd 
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../utils_pkg.vhd 
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../gaussian_blur_v1_0_S00_AXI.vhd 
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../dsp_unit_add.vhd 
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../gaussian_blur_v1_0.vhd 
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../kernel_rom.vhd 
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../bram.vhd 
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../dsp_unit_mul_shift.vhd 
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../gaussian_blur.vhd 
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../convolute_loops.vhd 
add_files -norecurse -copy_to ip_repo/gaussian_blur_ip_1.0/src ../memory_subsystem.vhd
update_compile_order -fileset sources_1

# Postavi potrebne fajlove na VHDL 2008
set_property file_type {VHDL 2008} [get_files  ip_repo/gaussian_blur_ip_1.0/src/convolute_loops.vhd]
update_compile_order -fileset sources_1
set_property file_type {VHDL 2008} [get_files  ip_repo/gaussian_blur_ip_1.0/src/kernel_rom.vhd]
update_compile_order -fileset sources_1

# Postavi top na gaussian_blur_v1_0
set_property top gaussian_blur_v1_0 [current_fileset]
update_compile_order -fileset sources_1

# Pokretanje sinteze radi provere ispravnosti IP jezgra
launch_runs synth_1 -jobs 6
wait_on_run synth_1

# Podesavanje parametara IP jezgra
set_property vendor FTN [ipx::current_core]
set_property library y24_g10 [ipx::current_core]
set_property name gaussian_blur_ip [ipx::current_core]
set_property display_name gaussian_blur_ip_v1.0 [ipx::current_core]
set_property description {IP core that performs gaussian blur on a image} [ipx::current_core]
set_property supported_families {zynq Pre-Production} [ipx::current_core]
set_property core_revision 1 [ipx::current_core]


# Zavrsna faza pakovanja jezgra i zatvaranje projekta
ipx::merge_project_changes files [ipx::current_core]

set_property widget {comboBox} [ipgui::get_guiparamspec -name "C_S01_AXI_DATA_WIDTH" -component [ipx::current_core] ]
set_property value_validation_list 64 [ipx::get_user_parameters C_S01_AXI_DATA_WIDTH -of_objects [ipx::current_core]]


ipx::merge_project_changes hdl_parameters [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]

ipx::check_integrity [ipx::current_core]

ipx::save_core [ipx::current_core]
ipx::move_temp_component_back -component [ipx::current_core]

#close_project -delete

update_ip_catalog -rebuild -repo_path ip_repo/gaussian_blur_ip_1.0

# Stvaranje blok-dizajna
create_bd_design "gaussian_blur_bd"
update_compile_order -fileset sources_1

# Ubacivanje Zynq procesorske jedinice i njena podesavanja
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

# Ubacivanje gaussian_blur IP
startgroup
create_bd_cell -type ip -vlnv FTN:y24_g10:gaussian_blur_ip:1.0 gaussian_blur_ip_0
endgroup

# Automatsko povezivanje
startgroup
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/gaussian_blur_ip_0/S00_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins gaussian_blur_ip_0/S00_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/gaussian_blur_ip_0/S01_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins gaussian_blur_ip_0/S01_AXI]
endgroup

