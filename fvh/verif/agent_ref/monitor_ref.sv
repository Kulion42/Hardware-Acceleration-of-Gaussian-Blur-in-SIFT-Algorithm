`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2025 10:34:50 AM
// Design Name: 
// Module Name: monitor
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

`ifndef MONITOR_REF_SV
`define MONITOR_REF_SV

class gaussian_blur_monitor_ref extends uvm_monitor;

    bit checks_enable = 1;
    bit coverage_enable = 1;
    int fd;
    int tmp, tmp1, tmp2;
    string num1, num2, num3;
    string result_file;
    gaussian_blur_config_ref cfg;
    
    uvm_analysis_port #(gaussian_blur_seq_item) item_collected_port;
        
    `uvm_component_utils_begin(gaussian_blur_monitor_ref)
        `uvm_field_int(checks_enable, UVM_DEFAULT)
        `uvm_field_int(coverage_enable, UVM_DEFAULT)       
    `uvm_component_utils_end
    
    virtual interface gaussian_blur_if vif;
    
    gaussian_blur_seq_item curr_it;
    
    
    function new(string name = "gaussian_blur_monitor_ref", uvm_component parent = null);
        super.new(name, parent);
        
        item_collected_port = new("item_collected_port", this);
                
         if (!uvm_config_db#(virtual gaussian_blur_if)::get(this, "", "gaussian_blur_if", vif))
            `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
        
        //Geting from configuration database
         if(!uvm_config_db#(gaussian_blur_config_ref)::get(this, "", "gaussian_blur_config_ref", cfg))
            `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
        //----------------------------------------------------------------------------------
   
    endfunction    
    
    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
    endfunction : connect_phase
   
    task main_phase(uvm_phase phase);
        @(posedge vif.clk)
        wait(vif.s00_axi_rdata == 0)
        wait(vif.s00_axi_rdata == 1)
        wait(vif.s00_axi_rdata == 0)
        wait(vif.s00_axi_rdata == 1)
        
        num1.itoa(cfg.rand_width);
        num2.itoa(cfg.rand_height);
        num3.itoa(cfg.rand_img_per_octave);
        
        result_file = {"../../../../../result_files/res_file_iwidth_", num1, "_iheight_", num2, "_ipo_", num3, ".txt"};
        
        fd = $fopen(result_file, "w+");
        if (fd) 
            `uvm_info(get_name(), $sformatf("Successfully opened main_bram_read_file"),UVM_HIGH)
        else
            `uvm_info(get_name(), $sformatf("Error opening main_bram_read_file"),UVM_HIGH)
                          
        forever begin
        @(posedge vif.clk);
        if(vif.rst)
        begin
            curr_it = gaussian_blur_seq_item::type_id::create("curr_it",this);
            if (curr_it == null) begin
                `uvm_fatal("CURR_IT_NULL", "Curr_it is null!")
            end
            if(vif.s00_axi_rdata == 1 && vif.s00_axi_araddr == 0 && vif.main_bram_a_addr_i > 0)
            begin
                //COLLECT COVERAGE
                //bram_cover.sample();
                `uvm_info(get_type_name(), $sformatf("[Monitor] Gathering information..."), UVM_MEDIUM);
                
                curr_it.main_bram_a_addr_i = vif.main_bram_a_addr_i - 4;
                curr_it.main_bram_a_rdata_o = vif.main_bram_a_rdata_o;
                
                //MAIN BRAM READING      
                
                if (fd) begin                  
                    tmp = vif.main_bram_a_rdata_o;
                    tmp1 = (tmp >> 16) & 16'hffff;
                    tmp2 = tmp & 16'hffff;
                    $fdisplay(fd, "%0d\t%0d\t\t\t%0d", tmp1, tmp2, curr_it.main_bram_a_addr_i/4);
                end 
                item_collected_port.write(curr_it);
            end 
        end
        end
        $fclose(fd);    
   endtask 

endclass : gaussian_blur_monitor_ref

`endif
