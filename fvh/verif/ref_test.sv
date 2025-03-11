`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2025 04:05:17 PM
// Design Name: 
// Module Name: simple_test
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

`ifndef REF_TEST_SV
`define REF_TEST_SV

class ref_test extends base_test_ref;

   `uvm_component_utils(ref_test)

   gaussian_blur_ref_seq ref_seq;

   function new(string name = "ref_test", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ref_seq = gaussian_blur_ref_seq::type_id::create("gaussian_blur_ref_seq");
      if (ref_seq == null) begin
            `uvm_fatal("RAND_SEQ_NULL", "Rand_seq is null!")
      end
   endfunction : build_phase

   task main_phase(uvm_phase phase);
      phase.raise_objection(this);
      ref_seq.start(env_ref.agent_ref.seqr);
      phase.drop_objection(this);
   endtask : main_phase

endclass : ref_test

`endif
