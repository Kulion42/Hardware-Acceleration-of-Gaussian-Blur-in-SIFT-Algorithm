
`ifndef BASE_TEST_SV
`define BASE_TEST_SV

class base_test extends uvm_test;

   gaussian_blur_env env;
   gaussian_blur_config cfg;

   `uvm_component_utils(base_test)

   function new(string name = "base_test", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
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

`endif
