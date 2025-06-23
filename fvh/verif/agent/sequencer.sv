
`ifndef SEQUENCER_SV
`define SEQUENCER_EV
    
class gaussian_blur_sequencer extends uvm_sequencer#(agent_pkg::gaussian_blur_seq_item);

    `uvm_component_utils(gaussian_blur_sequencer)
    
    gaussian_blur_config cfg;
    
    function new(string name = "gaussian_blur_sequencer" , uvm_component parent = null);
        super.new(name, parent);
        
        if (!uvm_config_db#(gaussian_blur_config)::get(this, "", "gaussian_blur_config", cfg))
            `uvm_fatal("NOCONFIG", {"Config object must be set for: ", get_full_name(), ".cfg"})
    endfunction : new

endclass : gaussian_blur_sequencer

`endif
