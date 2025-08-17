
`ifndef AGENT_RAND_SV
`define AGENT_RAND_SV
    
class gaussian_blur_agent_rand extends uvm_agent;

    gaussian_blur_driver drv;
    gaussian_blur_monitor_rand mon;
    gaussian_blur_sequencer_rand seqr;
    
    virtual interface gaussian_blur_if vif;
    
    gaussian_blur_config_rand cfg;
    
    `uvm_component_utils_begin(gaussian_blur_agent_rand)
        `uvm_field_object(cfg, UVM_DEFAULT)
        `uvm_field_object(drv, UVM_DEFAULT)
        `uvm_field_object(mon, UVM_DEFAULT)
        `uvm_field_object(seqr, UVM_DEFAULT)                   
    `uvm_component_utils_end
    
    function new(string name = "gaussian_blur_agent_rand", uvm_component parent = null);
        super.new(name,parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      /************Geting from configuration database*******************/
      if (!uvm_config_db#(virtual gaussian_blur_if)::get(this, "", "gaussian_blur_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      
      if(!uvm_config_db#(gaussian_blur_config_rand)::get(this, "", "gaussian_blur_config_rand", cfg))
        `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
      /*****************************************************************/
      
      /************Setting to configuration database********************/
      uvm_config_db#(gaussian_blur_config_rand)::set(this, "mon", "gaussian_blur_config_rand", cfg);
      uvm_config_db#(gaussian_blur_config_rand)::set(this, "seqr", "gaussian_blur_config_rand", cfg);
      uvm_config_db#(virtual gaussian_blur_if)::set(this, "*", "gaussian_blur_if", vif);
      /*****************************************************************/
      
      mon = agent_rand_pkg::gaussian_blur_monitor_rand::type_id::create("mon", this);
      if (mon == null) begin
            `uvm_fatal("MON_NULL", "Monitor is null!")
      end
      if(cfg.is_active == UVM_ACTIVE) begin
         drv = agent_pkg::gaussian_blur_driver::type_id::create("drv", this);
         if (drv == null) begin
            `uvm_fatal("DRV_NULL", "Driver is null!")
         end
         seqr = agent_rand_pkg::gaussian_blur_sequencer_rand::type_id::create("seqr", this);
         if (seqr == null) begin
            `uvm_fatal("SEQR_NULL", "Sequencer is null!")
         end
      end
   endfunction : build_phase

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if(cfg.is_active == UVM_ACTIVE) begin
         drv.seq_item_port.connect(seqr.seq_item_export);
      end
   endfunction : connect_phase
       
endclass : gaussian_blur_agent_rand

`endif
