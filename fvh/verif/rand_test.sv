
`ifndef RAND_TEST_SV
`define RAND_TEST_SV

class rand_test extends base_test_rand;

   `uvm_component_utils(rand_test)

   gaussian_blur_rand_seq rand_seq;

   function new(string name = "rand_test", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
   endfunction : build_phase

   task main_phase(uvm_phase phase);
      phase.raise_objection(this);
      rand_seq = gaussian_blur_rand_seq::type_id::create("gaussian_blur_rand_seq");
      if (rand_seq == null) begin
            `uvm_fatal("RAND_SEQ_NULL", "Rand_seq is null!")
      end
      rand_seq.start(env_rand.agent.seqr);
      phase.drop_objection(this);
   endtask : main_phase

endclass : rand_test

`endif
