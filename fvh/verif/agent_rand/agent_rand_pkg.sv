
`ifndef AGENT_PKG_RAND_SV
`define AGENT_PKG_RAND_SV

package agent_rand_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    
    import gaussian_blur_config_rand_pkg::*; 
    import agent_pkg::gaussian_blur_seq_item;
    import agent_pkg::gaussian_blur_driver;
    
    `include "sequencer.sv"
    `include "monitor.sv"
    `include "agent.sv"
    
endpackage : agent_rand_pkg

`endif
