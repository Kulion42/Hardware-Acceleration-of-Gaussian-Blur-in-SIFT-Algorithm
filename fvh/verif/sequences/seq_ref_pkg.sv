`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/09/2025 04:59:40 PM
// Design Name: 
// Module Name: seq_pkg
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

`ifndef GAUSSIAN_BLUR_SEQ_REF_PKG_SV
`define GAUSSIAN_BLUR_SEQ_REF_PKG_SV

package seq_ref_pkg;

	import uvm_pkg::*;      // import the UVM library
	`include "uvm_macros.svh" // Include the UVM macros
	
	import agent_ref_pkg::gaussian_blur_seq_item;
	import agent_ref_pkg::gaussian_blur_sequencer_ref;
    
    `include "base_seq_ref.sv"
	`include "ref_seq.sv"
	
endpackage : seq_ref_pkg
      
`endif
