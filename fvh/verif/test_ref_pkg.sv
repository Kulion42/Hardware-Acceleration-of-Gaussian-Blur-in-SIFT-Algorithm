`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2025 04:05:17 PM
// Design Name: 
// Module Name: test_pkg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef TEST_REF_PKG_SV
`define TEST_REF_PKG_SV

package test_ref_pkg;

	import uvm_pkg::*;      // import the UVM library   
	`include "uvm_macros.svh" // Include the UVM macros

	import agent_ref_pkg::*;
	import seq_ref_pkg::*;
	import gaussian_blur_config_ref_pkg::*;   
	
    `include "gaussian_blur_if.sv" 
    
    `include "scoreboard_ref.sv"
    `include "env_ref.sv"
	`include "base_test_ref.sv"    
    `include "ref_test.sv"  

endpackage : test_ref_pkg

`endif
