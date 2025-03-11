`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2025 04:05:17 PM
// Design Name: 
// Module Name: env
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

`ifndef ENV_REF_SV
`define ENV_REF_SV

class gaussian_blur_env_ref extends uvm_env;

    gaussian_blur_agent agent_ref;
    gaussian_blur_config_ref cfg;
    gaussian_blur_scoreboard_ref scbd_ref;
    
    virtual interface gaussian_blur_if vif;
    `uvm_component_utils(gaussian_blur_env_ref)
    
    function new(string name = "gaussian_blur_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction 
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Getting interfaces from configuration base 
        if (!uvm_config_db#(virtual gaussian_blur_if)::get(this, "", "gaussian_blur_if", vif))
            `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".h_vif"})

        if (!uvm_config_db#(gaussian_blur_config_ref)::get(this, "", "gaussian_blur_config_ref", cfg))
            `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".cfg"})

         // Setting to configurartion base 
        uvm_config_db#(gaussian_blur_config_ref)::set(this, "agent_ref", "gaussian_blur_config_ref", cfg);
        uvm_config_db#(gaussian_blur_config_ref)::set(this, "scbd_ref","gaussian_blur_config_ref", cfg);
        uvm_config_db#(virtual gaussian_blur_if)::set(this, "agent_ref", "gaussian_blur_if", vif);
        //uvm_config_db#(virtual gaussian_blur_if)::set(this, "axi_agent", "gaussian_blur_if", h_vif);

        agent_ref = agent_ref_pkg::gaussian_blur_agent::type_id::create("agent_ref",this);
        if (agent_ref == null) begin
            `uvm_fatal("AGENT_NULL", "Agent is null!")
        end
        
        //Adding scoreboard
        scbd_ref = test_ref_pkg::gaussian_blur_scoreboard_ref::type_id::create("scbd_ref",this);
        if (scbd_ref == null) begin
            `uvm_fatal("SCBD_NULL", "Scoreboard is null!")
        end
    endfunction : build_phase   
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent_ref.mon.item_collected_port.connect(scbd_ref.item_collected_import);
    endfunction
    
endclass : gaussian_blur_env_ref

`endif
