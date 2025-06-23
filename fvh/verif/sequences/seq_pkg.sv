
`ifndef GAUSSIAN_BLUR_SEQ_PKG_SV
`define GAUSSIAN_BLUR_SEQ_PKG_SV

package seq_pkg;

	import uvm_pkg::*;      // import the UVM library
	`include "uvm_macros.svh" // Include the UVM macros
	
	import agent_pkg::gaussian_blur_seq_item;
	import agent_pkg::gaussian_blur_sequencer;
	`include "base_seq.sv"
	`include "simple_seq.sv"
	
endpackage : seq_pkg
      
`endif
