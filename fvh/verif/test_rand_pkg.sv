
`ifndef TEST_RAND_PKG_SV
`define TEST_RAND_PKG_SV

package test_rand_pkg;

	import uvm_pkg::*;      // import the UVM library   
	`include "uvm_macros.svh" // Include the UVM macros

	import agent_rand_pkg::*;
	import seq_rand_pkg::*;
	import gaussian_blur_config_rand_pkg::*;   
    
    `include "scoreboard_rand.sv"
    `include "env_rand.sv"
	`include "base_test_rand.sv"    
    `include "rand_test.sv"  

endpackage : test_rand_pkg
    `include "gaussian_blur_if.sv" 
`endif
