
`ifndef BASE_TEST_RAND_SV
`define BASE_TEST_RAND_SV

class base_test_rand extends uvm_test;

   gaussian_blur_env_rand env_rand;
   gaussian_blur_config_rand cfg;

   `uvm_component_utils(base_test_rand)

   function new(string name = "base_test_rand", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cfg = gaussian_blur_config_rand::type_id::create("cfg"); 
      if (cfg == null) begin
            `uvm_fatal("CFG_NULL", "Cfg is null!")
      end
      cfg.randomize(); 
      cfg.random_configuration(); //randomize files
      uvm_config_db#(gaussian_blur_config_rand)::set(this, "env_rand", "gaussian_blur_config_rand", cfg);
      env_rand = gaussian_blur_env_rand::type_id::create("env_rand", this);
      if (env_rand == null) begin
            `uvm_fatal("ENV_RAND_NULL", "Env_rand is null!")
      end      
   endfunction : build_phase

   function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      uvm_top.print_topology();
   endfunction : end_of_elaboration_phase

endclass : base_test_rand

`endif
