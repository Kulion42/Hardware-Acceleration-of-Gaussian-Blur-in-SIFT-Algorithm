
`ifndef ENV_SV
`define ENV_SV

class gaussian_blur_env extends uvm_env;

    gaussian_blur_agent agent;
    gaussian_blur_config cfg;
    gaussian_blur_scoreboard scbd;
    
    virtual interface gaussian_blur_if vif;
    `uvm_component_utils(gaussian_blur_env)
    
    function new(string name = "gaussian_blur_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction 
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Getting interfaces from configuration base 
        if (!uvm_config_db#(virtual gaussian_blur_if)::get(this, "", "gaussian_blur_if", vif))
            `uvm_fatal("NO_VIF", {"Virtual interface 'gaussian_blur_if' not set for: ", get_full_name()})

        if (!uvm_config_db#(gaussian_blur_config)::get(this, "", "gaussian_blur_config", cfg))
            `uvm_fatal("NO_CFG", {"Config object 'gaussian_blur_config' not set for: ", get_full_name()})

         // Setting to configurartion base 
        uvm_config_db#(gaussian_blur_config)::set(this, "agent", "gaussian_blur_config", cfg);
        uvm_config_db#(gaussian_blur_config)::set(this, "scbd","gaussian_blur_config", cfg);
        uvm_config_db#(virtual gaussian_blur_if)::set(this, "agent", "gaussian_blur_if", vif);
        //uvm_config_db#(virtual gaussian_blur_if)::set(this, "axi_agent", "gaussian_blur_if", vif);

        agent = agent_pkg::gaussian_blur_agent::type_id::create("agent",this);
        if (agent == null) begin
            `uvm_fatal("AGENT_NULL", "Agent is null!")
        end
        //axi_agent = hough_axi_agent::type_id::create("axi_agent",this);
        
        //Adding scoreboard
        scbd = test_pkg::gaussian_blur_scoreboard::type_id::create("scbd",this);
        if (scbd == null) begin
            `uvm_fatal("SCBD_NULL", "Scoreboard is null!")
        end
    endfunction : build_phase   
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.mon.item_collected_port.connect(scbd.item_collected_import);
    endfunction
    
endclass : gaussian_blur_env

`endif
