-uvmhome "/eda/cadence/2019-20/RHELx86/XCELIUM_19.03.013/tools/methodology/UVM/CDNS-1.2/" 
-uvm +UVM_TESTNAME=rand_test +UVM_VERBOSITY=UVM_LOW
-sv +incdir+../verif
-sv +incdir+../verif/agent_rand
-sv +incdir+../verif/sequences
-sv +incdir+../verif/config

../../psds/rtl/utils_pkg.vhd
../../psds/rtl/dsp_unit_add.vhd
../../psds/rtl/dsp_unit_mul_shift.vhd
../../psds/rtl/dsp_unit_mac_shift.vhd
../../psds/rtl/kernel_rom.vhd
../../psds/rtl/convolute_loops.vhd
../../psds/rtl/bram.vhd
../../psds/rtl/memory_subsystem.vhd
../../psds/rtl/gaussian_blur.vhd
../../psds/rtl/top_model.vhd
../../psds/rtl/gaussian_blur_v1_0_S00_AXI.vhd
../../psds/rtl/gaussian_blur_v1_0.vhd

-sv ../verif/config/gaussian_blur_config_rand_pkg.sv
-sv ../verif/agent_rand/agent_rand_pkg.sv
-sv ../verif/sequences/seq_rand_pkg.sv
-sv ../verif/test_rand_pkg.sv
-sv ../verif/gaussian_blur_if.sv
-sv ../verif/gaussian_blur_top_rand.sv

#-LINEDEBUG
-access +rwc
-disable_sem2009
-nowarn "MEMODR"
-timescale 1ns/10ps
