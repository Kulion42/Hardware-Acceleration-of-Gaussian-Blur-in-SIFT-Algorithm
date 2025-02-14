`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/09/2025 04:57:14 PM
// Design Name: 
// Module Name: base_seq
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

`ifndef GAUSSIAN_BLUR_BASE_SEQ_SV
`define GAUSSIAN_BLUR_BASE_SEQ_SV

class gaussian_blur_base_seq extends uvm_sequence#(gaussian_blur_seq_item);

   `uvm_object_utils(gaussian_blur_base_seq)
   `uvm_declare_p_sequencer(gaussian_blur_sequencer)

   function new(string name = "gaussian_blur_base_seq");
      super.new(name);
   endfunction

   // objections are raised in pre_body
   virtual task pre_body();
      uvm_phase phase = get_starting_phase();
      if (phase != null)
        phase.raise_objection(this, {"Running sequence '", get_full_name(), "'"});
      uvm_test_done.set_drain_time(this, 200us);
   endtask : pre_body

   // objections are dropped in post_body
   virtual task post_body();
      uvm_phase phase = get_starting_phase();
      if (phase != null)
        phase.drop_objection(this, {"Completed sequence '", get_full_name(), "'"});
   endtask : post_body

endclass : gaussian_blur_base_seq

`endif

