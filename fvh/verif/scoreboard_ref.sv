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


`ifndef SCOREBOARD_REF_SV
`define SCOREBOARD_REF_SV

class gaussian_blur_scoreboard_ref extends uvm_scoreboard;

    bit checks_enable = 1;
    bit coverage_enable = 1;
    
    gaussian_blur_config_ref cfg;
    int num_of_tr, num_of_missed = 0;
    int num_of_zeros = 0;
    int fd;
    int blur_out_data_arr[$];
    int pixel_data_of = 1;
    int ref_d = 1;
    int ref_model;
    uvm_analysis_imp#(agent_ref_pkg::gaussian_blur_seq_item, gaussian_blur_scoreboard_ref) item_collected_import;
    
     `uvm_component_utils_begin(gaussian_blur_scoreboard_ref)
        `uvm_field_int(checks_enable, UVM_DEFAULT)
        `uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end
    
    
    function new(string name = "gaussian_blur_scoreboard_ref", uvm_component parent = null);
        super.new(name, parent);
        item_collected_import = new("item_collected_import", this);       
         
        if(!uvm_config_db#(gaussian_blur_config_ref)::get(this, "", "gaussian_blur_config_ref", cfg))
            `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})          
    endfunction 
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase               
    
    function int gaussian_blur_ref(int img_in_data_arr [$], int img_width, int img_height, int img_offset_up, int img_offset_down, int num_img_per_octave, ref int output_data_arr[$]);
        int tmp_arr[60000];
        int filtered_arr[60000];
        //int filtered_arr[];
        int sigma_vals[6] = {9, 9, 11, 13, 15, 19};
        int size = sigma_vals[num_img_per_octave];
        int center = size/2;
        int c_x;
        int c_y;
        int kernel_vals[6][];
        
        kernel_vals[0] = {30, 292, 1452, 3799, 5234, 3799, 1452, 292, 30, 0};
        kernel_vals[1] = {26, 267, 1409, 3823, 5331, 3823, 1409, 267, 26, 0};
        kernel_vals[2] = {22, 148, 642, 1830, 3432, 4231, 3432, 1830, 642, 148, 22, 0};
        kernel_vals[3] = {28, 123, 406, 1024, 1982, 2945, 3360, 2945, 1982, 1024, 406, 123, 28, 0};
        kernel_vals[4] = {45, 133, 334, 706, 1263, 1915, 2457, 2670, 2457, 1915, 1263, 706, 334, 133, 45, 0};
        kernel_vals[5] = {30, 74, 162, 321, 572, 917, 1322, 1719, 2011, 2119, 2011, 1719, 1322, 917, 572, 321, 162, 74, 30, 0};
        
        for (int y = img_offset_up; y < img_height - img_offset_down; y++) begin
            for (int x = 0; x < img_width; x+=2) begin
                int sum1 = 0; int sum2 = 0;
                for (int k = 0; k < size; k++) begin
                    int dy = -center + k;
                    
                    if (y+dy < 0 && img_offset_up == 0)
                        c_y = 0;
                    else if (y+dy < img_offset_up  && img_offset_up == 10)
                        c_y = img_offset_up + dy;                 
                    else if (y+dy >= img_height && img_offset_down == 0)
                        c_y = img_height - 1;
                    else if (y+dy >= img_height-img_offset_down && img_offset_down == 10)
                        c_y = img_height-img_offset_down + dy;
                    else
                        c_y = y + dy;
                        
                    sum1 += int'((cfg.img_in_data_arr[c_y * img_width + x] * kernel_vals[num_img_per_octave][k]) / (1 << 14));
                    sum2 += int'((cfg.img_in_data_arr[c_y * img_width + x + 1] * kernel_vals[num_img_per_octave][k]) / (1 << 14));
                end
                tmp_arr[(y - img_offset_up) * img_width + x] = sum1;
                tmp_arr[(y - img_offset_up) * img_width + x + 1] = sum2;
            end
        end    
        
        for (int y = 0; y < img_height - img_offset_up - img_offset_down; y++) begin
            for (int x = 0; x < img_width; x+=2) begin
                int sum1 = 0; int sum2 = 0;
                for (int k = 0; k < size; k++) begin
                    int dx = -center + k; 
                           
                    if (x+dx < 0 )
                        c_x = 0;
                    else if (x+dx >=img_width)
                        c_x = img_width - 1;
                    else
                        c_x = x + dx;
        
                    sum1 += int'((tmp_arr[y * img_width + c_x] * kernel_vals[num_img_per_octave][k]) / (1 << 14));
                    sum2 += int'((tmp_arr[y * img_width + c_x + 1] * kernel_vals[num_img_per_octave][k]) / (1 << 14));
                end
                filtered_arr[y * img_width + x] = sum1;
                filtered_arr[y * img_width + x + 1] = sum2;
            end
        end
        
        for(int i = 0; i < (img_height - img_offset_up - img_offset_down) *  img_width; i++) begin
            output_data_arr.push_back(filtered_arr[i]);
        end
        
        return 1;
        
    endfunction : gaussian_blur_ref
    
    task body(gaussian_blur_config_ref_pkg::gaussian_blur_config_ref cfg);
        
        
    endtask : body;
    
    function void write(agent_ref_pkg::gaussian_blur_seq_item curr_it);
        if (ref_d) begin
            ref_model = gaussian_blur_ref(cfg.img_in_data_arr, cfg.rand_width, cfg.rand_height, cfg.rand_offset_up, cfg.rand_offset_down, cfg.rand_img_per_octave, blur_out_data_arr);
            ref_d = 0;  
        end    
        if(checks_enable && ref_model && !ref_d) begin
            `uvm_info(get_type_name(),$sformatf("\n[Scoreboard] Scoreboard function write called..."),UVM_MEDIUM);
            
            if (curr_it.main_bram_a_rdata_o >> 16 == 0) begin
                    //`uvm_error(get_type_name(),$sformatf("\nObserved value is 0"));
                    ++num_of_zeros;
                end
            
            if (curr_it.main_bram_a_rdata_o & 16'hffff == 0) begin
                    //`uvm_error(get_type_name(),$sformatf("\nObserved value is 0"));
                    ++num_of_zeros;
            end
            
            ass_check_pix_up : assert((((curr_it.main_bram_a_rdata_o >> 16) & 16'hffff) >= (blur_out_data_arr[curr_it.main_bram_a_addr_i/2]) -pixel_data_of) && (((curr_it.main_bram_a_rdata_o >> 16) & 16'hffff) <= ((blur_out_data_arr[curr_it.main_bram_a_addr_i/2]) + pixel_data_of)))
            `uvm_info(get_type_name(),$sformatf("\nComparison match succesfull\nObserved value is %0d, expected is %0d.\n",
                                                    (curr_it.main_bram_a_rdata_o >> 16) & 16'hffff, 
                                                    blur_out_data_arr[curr_it.main_bram_a_addr_i/2]),UVM_MEDIUM)
                                                         
             else begin 
                `uvm_error(get_type_name(),$sformatf("\nComparison mismatch for main_bram address[%0d]\nObserved value is %0d, expected is %0d.\n",
                                                        curr_it.main_bram_a_addr_i/4,
                                                        (curr_it.main_bram_a_rdata_o >> 16)& 16'hffff, 
                                                        blur_out_data_arr[curr_it.main_bram_a_addr_i/2]))
                 ++num_of_missed; 
                                                       
             end
             
             ass_check_pix_down : assert(((curr_it.main_bram_a_rdata_o & 16'hffff) >= (blur_out_data_arr[curr_it.main_bram_a_addr_i/2 + 1]) - pixel_data_of) && ((curr_it.main_bram_a_rdata_o & 16'hffff) <= ((blur_out_data_arr[curr_it.main_bram_a_addr_i/2 + 1]) + pixel_data_of)))
            `uvm_info(get_type_name(),$sformatf("\nComparison match succesfull\nObserved value is %0d, expected is %0d.\n",
                                                    curr_it.main_bram_a_rdata_o & 16'hffff, 
                                                    blur_out_data_arr[curr_it.main_bram_a_addr_i/2 + 1]),UVM_MEDIUM)
                                                    
             
             else begin
                `uvm_error(get_type_name(),$sformatf("\nComparison mismatch for main_bram address[%0d]\nObserved value is %0d, expected is %0d.\n",
                                                        curr_it.main_bram_a_addr_i/4,
                                                        curr_it.main_bram_a_rdata_o & 16'hffff, 
                                                        blur_out_data_arr[curr_it.main_bram_a_addr_i/2 + 1]))
                 ++num_of_missed;
                                              
             end
            ++num_of_tr;
         end    
    endfunction : write
    
    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Gaussian blur scoreboard examined: %0d transactions(%0d pixels), %0d succesfull pixel matches, %0d pixel mismatches", num_of_tr,2 *num_of_tr, 2 *num_of_tr - num_of_missed, num_of_missed), UVM_LOW);
         
         fd = $fopen("../../../../../regression_log_ref.txt", "a+");
           if (fd) 
                 `uvm_info(get_name(), $sformatf("Successfully opened log file"),UVM_HIGH)
           else
                 `uvm_info(get_name(), $sformatf("Error log file"),UVM_HIGH)
         $fdisplay(fd, "File img_file_iwidth_%0d_iheight_%0d_ipo_%0d.txt examined: %0d pixels, %0d succesfull pixel matches, %0d pixel mismatches",cfg.rand_width, cfg.rand_height, cfg.rand_img_per_octave, 2 *num_of_tr, 2 *num_of_tr - num_of_missed, num_of_missed);
        $fclose(fd); 
            
    endfunction : report_phase
    
endclass : gaussian_blur_scoreboard_ref

`endif
