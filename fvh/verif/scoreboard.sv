`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2025 04:05:17 PM
// Design Name: 
// Module Name: scoreboard
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


`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

class gaussian_blur_scoreboard extends uvm_scoreboard;

    bit checks_enable = 1;
    bit coverage_enable = 1;
    gaussian_blur_config cfg;
    int num_of_tr, num_of_missed = 0;
    int num_of_zeros = 0;
    int fp;
    
    int pixel_data_of = 50;
    uvm_analysis_imp#(agent_pkg::gaussian_blur_seq_item, gaussian_blur_scoreboard) item_collected_import;
    
     `uvm_component_utils_begin(gaussian_blur_scoreboard)
        `uvm_field_int(checks_enable, UVM_DEFAULT)
        `uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end
    
    function new(string name = "gaussian_blur_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_collected_import = new("item_collected_import", this);
        
        if(!uvm_config_db#(gaussian_blur_config)::get(this, "", "gaussian_blur_config", cfg))
            `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})          
    endfunction 
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase
    
    function void write(agent_pkg::gaussian_blur_seq_item curr_it);
        if(checks_enable) begin
            `uvm_info(get_type_name(),$sformatf("\n[Scoreboard] Scoreboard function write called..."),UVM_MEDIUM);
            
            if (curr_it.main_bram_a_rdata_o >> 16 == 0) begin
                    //`uvm_error(get_type_name(),$sformatf("\nObserved value is 0"));
                    ++num_of_zeros;
                end
            
            if (curr_it.main_bram_a_rdata_o & 16'hffff == 0) begin
                    //`uvm_error(get_type_name(),$sformatf("\nObserved value is 0"));
                    ++num_of_zeros;
            end
            
            ass_check_pix_up : assert((((curr_it.main_bram_a_rdata_o >> 16) & 16'hffff) > (((cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i/4] >> 16) & 16'hffff) -pixel_data_of)) && (((curr_it.main_bram_a_rdata_o >> 16) & 16'hffff) < (((cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i/4] >> 16) & 16'hffff) + pixel_data_of)))
            `uvm_info(get_type_name(),$sformatf("\nComparison match succesfull\nObserved value is %0d, expected is %0d.\n",
                                                    (curr_it.main_bram_a_rdata_o >> 16) & 16'hffff, 
                                                    cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i/4] >> 16),UVM_MEDIUM)
                                                         
             else begin 
                `uvm_error(get_type_name(),$sformatf("\nComparison mismatch for main_bram address[%0d]\nObserved value is %0d, expected is %0d.\n",
                                                        curr_it.main_bram_a_addr_i/4,
                                                        (curr_it.main_bram_a_rdata_o >> 16)& 16'hffff, 
                                                        cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i/4] >> 16))
                 ++num_of_missed; 
                                                       
             end
             
             ass_check_pix_down : assert(((curr_it.main_bram_a_rdata_o & 16'hffff) > ((cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i/4] & 16'hffff) - pixel_data_of)) && ((curr_it.main_bram_a_rdata_o & 16'hffff) < ((cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i/4] & 16'hffff) + pixel_data_of)))
            `uvm_info(get_type_name(),$sformatf("\nComparison match succesfull\nObserved value is %0d, expected is %0d.\n",
                                                    curr_it.main_bram_a_rdata_o & 16'hffff, 
                                                    cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i/4] & 16'hffff),UVM_MEDIUM)
                                                    
             
             else begin
                `uvm_error(get_type_name(),$sformatf("\nComparison mismatch for main_bram address[%0d]\nObserved value is %0d, expected is %0d.\n",
                                                        curr_it.main_bram_a_addr_i/4,
                                                        curr_it.main_bram_a_rdata_o & 16'hffff, 
                                                        cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i/4] & 16'hffff))
                 ++num_of_missed;
                                              
             end
            ++num_of_tr;
         end    
    endfunction : write
    
    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Gaussian blur scoreboard examined: %0d transactions(%0d pixels), %0d succesfull pixel matches, %0d pixel mismatches, %0d observed zeros found", num_of_tr,2 *num_of_tr, 2 *num_of_tr - num_of_missed, num_of_missed, num_of_zeros), UVM_LOW);
    endfunction : report_phase
    
endclass : gaussian_blur_scoreboard

`endif
