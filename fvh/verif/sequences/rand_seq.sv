
`ifndef GAUSSIAN_BLUR_RAND_SEQ_SV
`define GAUSSIAN_BLUR_RAND_SEQ_SV
 
    parameter AXI_BASE = 5'b00000;  
    parameter IMG_WIDTH_REG_OFFSET = 5'b00000; 
    parameter IMG_HEIGHT_REG_OFFSET = 5'b00100;
    parameter IMG_OFFSET_UP_REG_OFFSET = 5'b01000; 
    parameter IMG_OFFSET_DOWN_REG_OFFSET = 5'b01100;
    parameter NUM_IMG_OCT_REG_OFFSET = 5'b10000;
    parameter START_REG_OFFSET = 5'b11000;
    parameter RESET_REG_OFFSET = 5'b10100;
    parameter READY_REG_OFFSET = 5'b11100;

    parameter MIN_PIX = 100;
    parameter MAX_PIX = 32767;    
class gaussian_blur_rand_seq extends seq_rand_pkg::gaussian_blur_base_seq_rand;

    int i = 0; 
    int j = 0;
    
    int img_width;
    int img_height;
    int img_offset_up;
    int img_offset_down;
    int num_img_per_oct;
    
    int fd;
    int unsigned pix_up, pix_down;

    string num, num1, num2, num3;
    
    covergroup img_data_cover();
        option.per_instance = 1;
        img_up_pix_value : coverpoint pix_up{
            bins group_up_1  = {[0:4096]};
            bins group_up_2  = {[4097:6144]};
            bins group_up_3  = {[6145:8192]};
            bins group_up_4  = {[8193:10240]};
            bins group_up_5  = {[10241:12288]};
            bins group_up_6  = {[12289:14336]};
            bins group_up_7  = {[14337:15360]};
            bins group_up_8  = {[15361:16384]};
            bins group_up_9  = {[16385:20480]};
            bins group_up_10 = {[20481:24576]};
            bins group_up_11 = {[24577:28672]};
            bins group_up_12 = {[28673:32767]};
            illegal_bins illegal_vals_up = {[32768:65536]};
        }
        
        img_down_pix_value : coverpoint pix_down{
            bins group_down_1 = {[0:4096]};
            bins group_down_2 = {[4097:6144]};
            bins group_down_3 = {[6145:8192]};
            bins group_down_4 = {[8193:10240]};
            bins group_down_5 = {[10241:12288]};
            bins group_down_6 = {[12289:14336]};
            bins group_down_7 = {[14337:15360]};
            bins group_down_8 = {[15361:16384]};
            bins group_up_9   = {[16385:20480]};
            bins group_up_10  = {[20481:24576]};
            bins group_up_11  = {[24577:28672]};
            bins group_up_12  = {[28673:32767]};
            illegal_bins illegal_vals_up = {[32768:65536]};
        }
    endgroup
    
    covergroup data_parity_cover();
        option.per_instance = 1;
        pix_up_parity : coverpoint pix_up%2{
            bins pix_up_odd = {1};
            bins pix_up_even = {0};
        }
        
        pix_down_parity : coverpoint pix_down%2{
            bins pix_down_odd = {1};
            bins pix_down_even = {0};
        }
    endgroup
    
    `uvm_object_utils(gaussian_blur_rand_seq)
    
    gaussian_blur_seq_item req_item;
       
    function new(string name = "gaussian_blur_rand_seq");
        super.new(name);
        img_data_cover = new();
        data_parity_cover = new();
    endfunction : new
    
    virtual task body();      
        
        req_item = gaussian_blur_seq_item::type_id::create("req_item");  
        if (req_item == null) begin
            `uvm_fatal("REQ_ITEM_NULL", "Req_item is null!")
        end
        
         //     INITALIZATION OF THE SYSTEM    
        
        $display("\nStarting AXI initialization...\n");
        `uvm_do_with(req_item,{   req_item.bram_axi_ctrl == 1;   req_item.s00_axi_awaddr == AXI_BASE+START_REG_OFFSET;     req_item.s00_axi_wdata == 32'd0;});  
        `uvm_do_with(req_item,{   req_item.bram_axi_ctrl == 1;   req_item.s00_axi_awaddr == AXI_BASE+RESET_REG_OFFSET;     req_item.s00_axi_wdata == 32'd1;});
        $display("\nAXI initialization finished!\n");
        // ----------------------------------------------------------------------------------------------------------------------------------------------
                
        //      LOADING AN IMAGE PART IN BRAM
        num.itoa(p_sequencer.cfg.rand_width);
        num1.itoa(p_sequencer.cfg.rand_height);
        num2.itoa(p_sequencer.cfg.rand_offset_up);
        num3.itoa(p_sequencer.cfg.rand_offset_down);
        $display("\nLoading image part begins...\n");
        fd = $fopen({"../../../../../result_files/res_file_img_width_", num, "_height_", num1, "_offset_up_", num2, "_offset_down_", num3, "_input.txt"}, "w+");
        if (fd) 
            `uvm_info(get_name(), $sformatf("Successfully opened main_bram_read_file"),UVM_HIGH)
        else
            `uvm_info(get_name(), $sformatf("Error opening main_bram_read_file"),UVM_HIGH)

         for (i = 0 ; i < p_sequencer.cfg.rand_width*p_sequencer.cfg.rand_height/2 ; i++)
            begin
            start_item(req_item);
                req_item.bram_axi_ctrl = 0;    
                req_item.main_bram_a_en_i = 1'b1;    
                req_item.main_bram_a_we_i = 4'b1111;    
                req_item.main_bram_a_addr_i = i*4;   
                pix_up = $urandom_range(MIN_PIX, MAX_PIX);
                pix_down = $urandom_range(MIN_PIX, MAX_PIX);
                $fdisplay(fd, "%0d\t%0d\t", pix_up, pix_down);
                p_sequencer.cfg.img_in_data_arr.push_back(pix_up);
                p_sequencer.cfg.img_in_data_arr.push_back(pix_down);
                req_item.main_bram_a_wdata_i = pix_up << 16 | pix_down;                  
                //$display("Data sent=%0d[%0d]", req_item.main_bram_a_wdata_i, i);
                //COLLECT COVERAGE
                img_data_cover.sample();
                data_parity_cover.sample();
            finish_item(req_item);     
            end
        $fclose(fd);
            start_item(req_item);
                req_item.bram_axi_ctrl = 0;    
                req_item.main_bram_a_en_i = 1'b0;    
                req_item.main_bram_a_we_i = 4'b0000;    
                req_item.main_bram_a_addr_i = 17'd0;
            finish_item(req_item); 

        $display("\nImage part loaded!\n");
        // ----------------------------------------------------------------------------------------------------------------------------------------------
         
         //     SETTING IMAGE PROPERTIES 
         $display("\nSetting image parameters...\n\n");
        `uvm_do_with(req_item,{   req_item.bram_axi_ctrl == 1;   req_item.s00_axi_awaddr == AXI_BASE+IMG_WIDTH_REG_OFFSET;          req_item.s00_axi_wdata == p_sequencer.cfg.rand_width;});                            
        `uvm_do_with(req_item,{   req_item.bram_axi_ctrl == 1;   req_item.s00_axi_awaddr == AXI_BASE+IMG_HEIGHT_REG_OFFSET;         req_item.s00_axi_wdata == p_sequencer.cfg.rand_height;});
        `uvm_do_with(req_item,{   req_item.bram_axi_ctrl == 1;   req_item.s00_axi_awaddr == AXI_BASE+IMG_OFFSET_UP_REG_OFFSET;      req_item.s00_axi_wdata == p_sequencer.cfg.rand_offset_up;});
        `uvm_do_with(req_item,{   req_item.bram_axi_ctrl == 1;   req_item.s00_axi_awaddr == AXI_BASE+IMG_OFFSET_DOWN_REG_OFFSET;    req_item.s00_axi_wdata == p_sequencer.cfg.rand_offset_down;});
        `uvm_do_with(req_item,{   req_item.bram_axi_ctrl == 1;   req_item.s00_axi_awaddr == AXI_BASE+NUM_IMG_OCT_REG_OFFSET;        req_item.s00_axi_wdata == p_sequencer.cfg.rand_img_per_octave;}); 
         $display("\nImage parameters set!\n");     
        // ----------------------------------------------------------------------------------------------------------------------------------------------
        
        //      STARTING GAUSSIAN BLUR
        $display("\nStarting gaussian blur...\n");
        `uvm_do_with(req_item,{   req_item.bram_axi_ctrl == 1;   req_item.s00_axi_awaddr == AXI_BASE+RESET_REG_OFFSET;     req_item.s00_axi_wdata == 32'd1;});
        `uvm_do_with(req_item,{   req_item.bram_axi_ctrl == 1; req_item.s00_axi_awaddr == AXI_BASE+START_REG_OFFSET; req_item.s00_axi_wdata == 32'd1;});
        // ----------------------------------------------------------------------------------------------------------------------------------------------
        
        //      READING BRAM AFTER PROCESSING
        $display("\nReading results from bram\n");
         for (i = 0 ; i < p_sequencer.cfg.rand_width*(p_sequencer.cfg.rand_height - p_sequencer.cfg.rand_offset_up - p_sequencer.cfg.rand_offset_down)/2 + 2 ; i++)
            begin
                `uvm_do_with(req_item,{   req_item.bram_axi_ctrl == 0;    req_item.main_bram_a_en_i == 1'b1;    req_item.main_bram_a_we_i == 4'b0000;    req_item.main_bram_a_addr_i == i*4;});
            end            
        // ----------------------------------------------------------------------------------------------------------------------------------------------        
        $display("\nFinished\n");
        
    endtask : body
    
endclass : gaussian_blur_rand_seq
    
`endif
