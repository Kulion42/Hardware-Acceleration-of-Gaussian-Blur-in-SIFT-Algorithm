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

`ifndef SIMPLE_TEST_SV
`define SIMPLE_TEST_SV

class simple_test extends base_test;

   `uvm_component_utils(simple_test)

   gaussian_blur_simple_seq simple_seq;

   function new(string name = "simple_test", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      simple_seq = gaussian_blur_simple_seq::type_id::create("gaussian_blur_simple_seq");
      if (simple_seq == null) begin
            `uvm_fatal("SIM_SEQ_NULL", "Simple_seq is null!")
      end
   endfunction : build_phase

   task main_phase(uvm_phase phase);
      phase.raise_objection(this);
      simple_seq.start(env.agent.seqr);
      phase.drop_objection(this);
   endtask : main_phase

endclass : simple_test

`endif
