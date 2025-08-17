
`ifndef SEQUENCER_RAND_SV
`define SEQUENCER_RAND_SV
    
class gaussian_blur_sequencer_rand extends uvm_sequencer#(gaussian_blur_seq_item);

    `uvm_component_utils(gaussian_blur_sequencer_rand)
    
    gaussian_blur_config_rand cfg;
    
    function new(string name = "gaussian_blur_sequencer_rand" , uvm_component parent = null);
        super.new(name, parent);
        
        if (!uvm_config_db#(gaussian_blur_config_rand)::get(this, "", "gaussian_blur_config_rand", cfg))
            `uvm_fatal("NOCONFIG", {"Config object must be set for: ", get_full_name(), ".cfg"})
    endfunction : new
    
endclass : gaussian_blur_sequencer_rand

`endif
