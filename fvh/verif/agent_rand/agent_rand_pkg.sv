
`ifndef AGENT_PKG_RAND_SV
`define AGENT_PKG_RAND_SV

package agent_rand_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    
    import gaussian_blur_config_rand_pkg::*;   
    
    `include "seq_item.sv"
    `include "sequencer.sv"
    `include "driver.sv"
    `include "monitor.sv"
    `include "agent.sv"
    
endpackage : agent_rand_pkg

`endif
