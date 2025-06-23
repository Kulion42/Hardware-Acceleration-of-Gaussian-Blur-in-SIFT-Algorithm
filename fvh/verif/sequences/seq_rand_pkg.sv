
`ifndef GAUSSIAN_BLUR_SEQ_RAND_PKG_SV
`define GAUSSIAN_BLUR_SEQ_RAND_PKG_SV

package seq_rand_pkg;

	import uvm_pkg::*;      // import the UVM library
	`include "uvm_macros.svh" // Include the UVM macros
	
	import agent_rand_pkg::gaussian_blur_seq_item;
	import agent_rand_pkg::gaussian_blur_sequencer;
    
    `include "base_seq_rand.sv"
	`include "rand_seq.sv"
	
endpackage : seq_rand_pkg
      
`endif
