CC = "g++"
PROJECT = cosim
SRC = sc_main.cpp ip_core.cpp cpu.cpp interconnect.cpp functions.cpp image.cpp utils_pkg.vhd dsp_unit_add.vhd dsp_unit_mac_shift.vhd dsp_unit_mul_shift.vhd bram.vhd convolute_loops.vhd kernel_rom.vhd gaussian_blur.vhd top_model.vhd

$(PROJECT) : $(SRC)
	xmsc_run -sc_main -DSC_INCLUDE_DYNAMIC_PROCESSES -DSC_INCLUDE_FX +systemc_args+"../images/bird.jpg"  -gui -access +r $(SRC)

clean:
	rm *.jpg *.txt *.log *.jou *.key *.so -r *.d .simvision/ waves.shm/ *.diag
