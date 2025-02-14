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
    gaussian_blur_config cfg;
    int num_of_tr, num_of_missed = 0;
    int fp;
    
    uvm_analysis_imp#(gaussian_blur_seq_item, gaussian_blur_scoreboard) item_collected_import;
    
     `uvm_component_utils_begin(gaussian_blur_scoreboard)
        `uvm_field_int(checks_enable, UVM_DEFAULT)
        //`uvm_field_int(coverage_enable, UVM_DEFAULT)
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
    
    function void write(gaussian_blur_seq_item curr_it);
        if(checks_enable) begin
            `uvm_info(get_type_name(),$sformatf("\n[Scoreboard] Scoreboard function write called..."),UVM_MEDIUM);
            ass_check_main : assert(curr_it.main_bram_a_rdata_o == cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i])
            `uvm_info(get_type_name(),$sformatf("\nComparison match succesfull\nObserved value is %d, expected is %d.\n",
                                                    curr_it.main_bram_a_rdata_o, 
                                                    cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i]),UVM_MEDIUM)
         
             else begin
                `uvm_error(get_type_name(),$sformatf("\nComparison mismatch for main_bram address[%d]\nObserved value is %d, expected is %d.\n",
                                                        curr_it.main_bram_a_addr_i,
                                                        curr_it.main_bram_a_rdata_o, 
                                                        cfg.main_bram_gv_arr[curr_it.main_bram_a_addr_i]))
                 ++num_of_missed;                                       
             end
            ++num_of_tr;
         end    
    endfunction : write
    
    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Gaussian blur scoreboard examined: %0d transactions, %0d mismatches", num_of_tr, num_of_missed), UVM_LOW);
    endfunction : report_phase
    
endclass : gaussian_blur_scoreboard

`endif