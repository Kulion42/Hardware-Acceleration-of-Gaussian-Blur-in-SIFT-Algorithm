
`ifndef SCOREBOARD_RAND_SV
`define SCOREBOARD_RAND_SV

class gaussian_blur_scoreboard_rand extends uvm_scoreboard;

    bit checks_enable = 1;
    bit coverage_enable = 1;
    
    gaussian_blur_config_rand cfg;
    int num_of_tr, num_of_missed = 0;
    int fd;
    int pixel_data_of = 1;

    uvm_analysis_imp#(agent_pkg::gaussian_blur_seq_item, gaussian_blur_scoreboard_rand) item_collected_import;
    
     `uvm_component_utils_begin(gaussian_blur_scoreboard_rand)
        `uvm_field_int(checks_enable, UVM_DEFAULT)
        `uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end
    
    
    function new(string name = "gaussian_blur_scoreboard_rand", uvm_component parent = null);
        super.new(name, parent);
        item_collected_import = new("item_collected_import", this);       
    endfunction 
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(gaussian_blur_config_rand)::get(this, "", "gaussian_blur_config_rand", cfg))
            `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"}) 
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase             

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        gaussian_blur_ref(cfg.img_in_data_arr, cfg.rand_width, cfg.rand_height,
                        cfg.rand_offset_up, cfg.rand_offset_down,
                        cfg.rand_img_per_octave, cfg.ref_out_data_arr);
    endfunction : start_of_simulation_phase
    
    function void gaussian_blur_ref(int img_in_data_arr [$], int img_width, int img_height, int img_offset_up, int img_offset_down, int num_img_per_octave, ref int output_data_arr[$]);
        int tmp_arr[60000];
        int sigma_vals[6] = {9, 9, 11, 13, 15, 19};
        int size = sigma_vals[num_img_per_octave];
        int center = size/2;
        int c_x;
        int c_y;
        int kernel_vals[6][];
        int SHIFT = 15; // Shift value for normalization
        
        // Kernel values for Gaussian blur
        // These values are derived from the Gaussian function and normalized
        // Kernel values for Gaussian blur (sum normalized to 1 << SHIFT)
        kernel_vals[0] = '{61, 584, 2904, 7597, 10468, 7597, 2904, 584, 61};
        kernel_vals[1] = '{52, 534, 2819, 7645, 10661, 7645, 2819, 534, 52};
        kernel_vals[2] = '{44, 296, 1284, 3661, 6864, 8463, 6864, 3661, 1284, 296, 44};
        kernel_vals[3] = '{57, 247, 813, 2049, 3964, 5889, 6720, 5889, 3964, 2049, 813, 247, 57};
        kernel_vals[4] = '{90, 267, 668, 1412, 2527, 3829, 4915, 5340, 4915, 3829, 2527, 1412, 668, 267, 90};
        kernel_vals[5] = '{60, 148, 325, 643, 1144, 1833, 2646, 3437, 4022, 4238, 4022, 3437, 2646, 1833, 1144, 643, 325, 148, 60};
        
        
        for (int y = img_offset_up; y < img_height - img_offset_down; y++) begin
            for (int x = 0; x < img_width; x+=2) begin
                int sum1 = 0; int sum2 = 0;
                for (int k = 0; k < size; k++) begin
                    int dy = -center + k;
                    
                    if (y+dy < 0 && img_offset_up == 0)
                        c_y = 0;
                    else if (y+dy < img_offset_up  && img_offset_up != 0)
                        c_y = img_offset_up + dy;                 
                    else if (y+dy >= img_height && img_offset_down == 0)
                        c_y = img_height - 1;
                    else if (y+dy >= img_height-img_offset_down && img_offset_down != 0)
                        c_y = img_height-img_offset_down + dy;
                    else
                        c_y = y + dy;
                        
                    sum1 += int'((img_in_data_arr[c_y * img_width + x] * kernel_vals[num_img_per_octave][k]) / (1 << SHIFT));
                    sum2 += int'((img_in_data_arr[c_y * img_width + x + 1] * kernel_vals[num_img_per_octave][k]) / (1 << SHIFT));
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
        
                    sum1 += int'((tmp_arr[y * img_width + c_x] * kernel_vals[num_img_per_octave][k]) / (1 << SHIFT));
                    sum2 += int'((tmp_arr[y * img_width + c_x + 1] * kernel_vals[num_img_per_octave][k]) / (1 << SHIFT));
                end
                output_data_arr.push_back(sum1);
                output_data_arr.push_back(sum2);
            end
        end
        
    endfunction : gaussian_blur_ref       
    
    function void write(agent_pkg::gaussian_blur_seq_item curr_it);

        `uvm_info(get_type_name(),$sformatf("\n[Scoreboard] Scoreboard function write called..."),UVM_MEDIUM);
        if(checks_enable) begin
            ass_check_pix_up : assert((((curr_it.main_bram_a_rdata_o >> 16) & 16'hffff) >= (cfg.ref_out_data_arr[curr_it.main_bram_a_addr_i/2]) -pixel_data_of) && (((curr_it.main_bram_a_rdata_o >> 16) & 16'hffff) <= ((cfg.ref_out_data_arr[curr_it.main_bram_a_addr_i/2]) + pixel_data_of)))
            `uvm_info(get_type_name(),$sformatf("\nComparison match succesfull\nObserved value is %0d, expected is %0d.\n",        
                                                    (curr_it.main_bram_a_rdata_o >> 16) & 16'hffff, 
                                                    cfg.ref_out_data_arr[curr_it.main_bram_a_addr_i/2]),UVM_MEDIUM)
                                                         
             else begin 
                `uvm_error(get_type_name(),$sformatf("\nComparison mismatch for main_bram address[%0d]\nObserved value is %0d, expected is %0d.\n",
                                                        curr_it.main_bram_a_addr_i/4,
                                                        (curr_it.main_bram_a_rdata_o >> 16)& 16'hffff, 
                                                        cfg.ref_out_data_arr[curr_it.main_bram_a_addr_i/2]))
                 ++num_of_missed; 
                                                       
             end
             
             ass_check_pix_down : assert(((curr_it.main_bram_a_rdata_o & 16'hffff) >= (cfg.ref_out_data_arr[curr_it.main_bram_a_addr_i/2 + 1]) - pixel_data_of) && ((curr_it.main_bram_a_rdata_o & 16'hffff) <= ((cfg.ref_out_data_arr[curr_it.main_bram_a_addr_i/2 + 1]) + pixel_data_of)))
            `uvm_info(get_type_name(),$sformatf("\nComparison match succesfull\nObserved value is %0d, expected is %0d.\n",
                                                    curr_it.main_bram_a_rdata_o & 16'hffff, 
                                                    cfg.ref_out_data_arr[curr_it.main_bram_a_addr_i/2 + 1]),UVM_MEDIUM)
                                                    
             
             else begin
                `uvm_error(get_type_name(),$sformatf("\nComparison mismatch for main_bram address[%0d]\nObserved value is %0d, expected is %0d.\n",
                                                        curr_it.main_bram_a_addr_i/4,
                                                        curr_it.main_bram_a_rdata_o & 16'hffff, 
                                                        cfg.ref_out_data_arr[curr_it.main_bram_a_addr_i/2 + 1]))
                 ++num_of_missed;
                                            
             end
            ++num_of_tr;
         end    
    endfunction : write
    
    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Gaussian blur scoreboard examined: %0d transactions(%0d pixels), %0d succesfull pixel matches, %0d pixel mismatches", num_of_tr,2 *num_of_tr, 2 *num_of_tr - num_of_missed, num_of_missed), UVM_LOW);
         
         fd = $fopen("../../../../../regression_log_rand.txt", "a+");
           if (fd) 
                 `uvm_info(get_name(), $sformatf("Successfully opened log file"),UVM_HIGH)
           else
                 `uvm_info(get_name(), $sformatf("Error log file"),UVM_HIGH)
         $fdisplay(fd, "File ../result_files/res_file_img_width_%0d_height_%0d_offest_up_%0d_offset_down_%0d_output.txt examined: %0d pixels, %0d succesfull pixel matches, %0d pixel mismatches",cfg.rand_width, cfg.rand_height, cfg.rand_offset_up , cfg.rand_offset_down, 2 *num_of_tr, 2 *num_of_tr - num_of_missed, num_of_missed);
        $fclose(fd); 
        cfg.ref_out_data_arr.delete();    
    endfunction : report_phase
    
endclass : gaussian_blur_scoreboard_rand

`endif
