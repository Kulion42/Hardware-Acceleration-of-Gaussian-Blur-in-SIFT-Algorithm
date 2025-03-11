`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2025 04:05:17 PM
// Design Name: 
// Module Name: base_test
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

`ifndef BASE_TEST_REF_SV
`define BASE_TEST_REF_SV

class base_test_ref extends uvm_test;

   gaussian_blur_env_ref env_ref;
   gaussian_blur_config_ref cfg;

   `uvm_component_utils(base_test_ref)

   function new(string name = "base_test_ref", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cfg = gaussian_blur_config_ref::type_id::create("cfg"); 
      if (cfg == null) begin
            `uvm_fatal("CFG_REF_NULL", "Cfg is null!")
      end
      cfg.randomize(); 
      cfg.random_configuration(); //randomize files
      uvm_config_db#(gaussian_blur_config_ref)::set(this, "env_ref", "gaussian_blur_config_ref", cfg);      
      env_ref = gaussian_blur_env_ref::type_id::create("env_ref", this);
      if (env_ref == null) begin
            `uvm_fatal("ENV_REF_NULL", "Env_ref is null!")
      end      
   endfunction : build_phase

   function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      uvm_top.print_topology();
   endfunction : end_of_elaboration_phase

endclass : base_test_ref

`endif
