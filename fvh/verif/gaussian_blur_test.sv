
`ifndef BASE_TEST_SV
`define BASE_TEST_SV

class base_test extends uvm_test;

   gaussian_blur_env env;
   gaussian_blur_config cfg;

   `uvm_component_utils(base_test)

   function new(string name = "base_test", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   virtual function void cfg_override();
   endfunction : cfg_override

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cfg_override();
      cfg = gaussian_blur_config::type_id::create("cfg"); 
      if (cfg == null) begin
            `uvm_fatal("CFG_NULL", "Cfg is null!")
      end
      cfg.randomize(); 
      cfg.random_configuration(); //randomize files
      uvm_config_db#(gaussian_blur_config)::set(this, "env", "gaussian_blur_config", cfg);      
      env = gaussian_blur_env::type_id::create("env", this);
      if (env == null) begin
            `uvm_fatal("ENV_NULL", "Env is null!")
      end      
   endfunction : build_phase

   function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      uvm_top.print_topology();
   endfunction : end_of_elaboration_phase

endclass : base_test

class file_test extends base_test;

   `uvm_component_utils(file_test)

   gaussian_blur_seq file_seq;

   function new(string name = "file_test", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   virtual function void cfg_override();
      gaussian_blur_config::type_id::set_type_override(gaussian_blur_config_file::get_type());
   endfunction : cfg_override

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
   endfunction : build_phase

   task main_phase(uvm_phase phase);
      phase.raise_objection(this);
      file_seq = gaussian_blur_seq::type_id::create("gaussian_blur_seq");
      if (file_seq == null) begin
            `uvm_fatal("FILE_SEQ_NULL", "File_seq is null!")
      end
      file_seq.start(env.agent.seqr);
      phase.drop_objection(this);
      phase.phase_done.set_drain_time(this, 200us);
   endtask : main_phase

endclass : file_test

class rand_test extends base_test;

   `uvm_component_utils(rand_test)

   gaussian_blur_seq rand_seq;

   function new(string name = "rand_test", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   virtual function void cfg_override();
      gaussian_blur_config::type_id::set_type_override(gaussian_blur_config_rand::get_type());
   endfunction : cfg_override

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
   endfunction : build_phase

   task main_phase(uvm_phase phase);
      phase.raise_objection(this);
      rand_seq = gaussian_blur_seq::type_id::create("gaussian_blur_seq");
      if (rand_seq == null) begin
            `uvm_fatal("RAND_SEQ_NULL", "Rand_seq is null!")
      end
      rand_seq.start(env.agent.seqr);
      phase.drop_objection(this);
      phase.phase_done.set_drain_time(this, 200us);
   endtask : main_phase

endclass : rand_test


`endif
