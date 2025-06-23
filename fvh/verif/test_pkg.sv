
`ifndef TEST_PKG_SV
`define TEST_PKG_SV

package test_pkg;

	import uvm_pkg::*;      // import the UVM library   
	`include "uvm_macros.svh" // Include the UVM macros

	import agent_pkg::*;
	import seq_pkg::*;
	import gaussian_blur_config_pkg::*;   

	`include "scoreboard.sv" 
	`include "env.sv"   
	`include "base_test.sv"
	`include "simple_test.sv"

endpackage : test_pkg

  `include "gaussian_blur_if.sv"    

`endif
