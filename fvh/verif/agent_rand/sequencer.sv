
`ifndef SEQUENCER_SV
`define SEQUENCER_SV
    
class gaussian_blur_sequencer extends uvm_sequencer#(agent_rand_pkg::gaussian_blur_seq_item);

    `uvm_component_utils(gaussian_blur_sequencer)
    
    gaussian_blur_config_rand cfg;
    
    function new(string name = "gaussian_blur_sequencer" , uvm_component parent = null);
        super.new(name, parent);
        
        if (!uvm_config_db#(gaussian_blur_config_rand)::get(this, "", "gaussian_blur_config_rand", cfg))
            `uvm_fatal("NOCONFIG", {"Config object must be set for: ", get_full_name(), ".cfg"})
    endfunction : new
    
endclass : gaussian_blur_sequencer

`endif
