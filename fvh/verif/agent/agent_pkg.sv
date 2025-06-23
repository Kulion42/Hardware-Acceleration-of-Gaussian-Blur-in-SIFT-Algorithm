
`ifndef AGENT_PKG_SV
`define AGENT_PKG_SV

package agent_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    
    import gaussian_blur_config_pkg::*;
    
    `include "seq_item.sv"
    `include "sequencer.sv"
    `include "driver.sv"
    `include "monitor.sv"
    `include "agent.sv"
endpackage : agent_pkg

`endif
