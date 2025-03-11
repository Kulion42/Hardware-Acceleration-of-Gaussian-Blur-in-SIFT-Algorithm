`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2025 10:34:50 AM
// Design Name: 
// Module Name: agent_pkg
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

`ifndef AGENT_PKG_REF_SV
`define AGENT_PKG_REF_SV

package agent_ref_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    
    import gaussian_blur_config_ref_pkg::*;   
    
    `include "seq_item.sv"
    `include "sequencer_ref.sv"
    `include "driver.sv"
    `include "monitor_ref.sv"
    `include "agent.sv"
    
endpackage : agent_ref_pkg

`endif
