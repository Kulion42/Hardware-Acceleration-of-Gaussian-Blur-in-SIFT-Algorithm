`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/09/2025 04:57:14 PM
// Design Name: 
// Module Name: simple_seq
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

`ifndef GAUSSIAN_BLUR_SIMPLE_SEQ_SV
`define GAUSSIAN_BLUR_SIMPLE_SEQ_SV

    parameter AXI_BASE = 5'b00000;
    parameter START_REG_OFFSET = 0;
    parameter RESET_REG_OFFSET = 4;  
    parameter IMG_WIDTH_REG_OFFSET = 8; 
    parameter IMG_HEIGHT_REG_OFFSET = 12;
    parameter IMG_OFFSET_UP_REG_OFFSET = 16; 
    parameter IMG_OFFSET_DOWN_REG_OFFSET = 20;
    parameter NUM_IMG_OCT_REG_OFFSET = 24;
    parameter READY_REG_OFFSET = 28;
    
class gaussian_blur_simple_seq extends gaussian_blur_base_seq;
    int i = 0; 
    int j = 0;
    int img_width, img_height;
    int img_offset_up;
    int img_offset_down;
    int num_img_per_oct;
    
    `uvm_object_utils(gaussian_blur_simple_seq)
    gaussian_blur_seq_item seq_item;
       
    function new(string name = "gaussian_blur_simple_seq");
        super.new(name);
    
    endfunction : new
    
    virtual task body();
        
        img_width = p_sequencer.cfg.img_width;
        img_height = p_sequencer.cfg.img_height;
        img_offset_up = p_sequencer.cfg.img_offset_up;
        img_offset_down = p_sequencer.cfg.img_offset_down;
        num_img_per_oct = p_sequencer.cfg.num_img_per_oct;
        
        seq_item = gaussian_blur_seq_item::type_id::create("gaussian_blur_seq_item");  
        
         //     INITALIZATION OF THE SYSTEM    
        
        $display("AXI initialization starts...\n");
        `uvm_do_with(seq_item,{   seq_item.bram_axi_ctrl == 1;   seq_item.s00_axi_awaddr == AXI_BASE+START_REG_OFFSET;     seq_item.s00_axi_wdata == 32'd0;});                       
        `uvm_do_with(seq_item,{   seq_item.bram_axi_ctrl == 1;   seq_item.s00_axi_awaddr == AXI_BASE+RESET_REG_OFFSET;     seq_item.s00_axi_wdata == 32'd1;});
        // ----------------------------------------------------------------------------------------------------------------------------------------------
         
         //     SETTING IMAGE PROPERTIES 
         $display("\nSetting image parameters...\n");
        `uvm_do_with(seq_item,{   seq_item.bram_axi_ctrl == 1;   seq_item.s00_axi_awaddr == AXI_BASE+IMG_WIDTH_REG_OFFSET;          seq_item.s00_axi_wdata == img_width;});                            
        `uvm_do_with(seq_item,{   seq_item.bram_axi_ctrl == 1;   seq_item.s00_axi_awaddr == AXI_BASE+IMG_HEIGHT_REG_OFFSET;         seq_item.s00_axi_wdata == img_height;});
        `uvm_do_with(seq_item,{   seq_item.bram_axi_ctrl == 1;   seq_item.s00_axi_awaddr == AXI_BASE+IMG_OFFSET_UP_REG_OFFSET;      seq_item.s00_axi_wdata == img_offset_up;});
        `uvm_do_with(seq_item,{   seq_item.bram_axi_ctrl == 1;   seq_item.s00_axi_awaddr == AXI_BASE+IMG_OFFSET_DOWN_REG_OFFSET;    seq_item.s00_axi_wdata == img_offset_down;});
        `uvm_do_with(seq_item,{   seq_item.bram_axi_ctrl == 1;   seq_item.s00_axi_awaddr == AXI_BASE+NUM_IMG_OCT_REG_OFFSET;        seq_item.s00_axi_wdata == num_img_per_oct;});       
        // ----------------------------------------------------------------------------------------------------------------------------------------------
        
        //      LOADING AN IMAGE PART IN BRAM
         $display("\nLoading image part begins...\n");
         for (i = 0 ; i < p_sequencer.cfg.img_width*p_sequencer.cfg.img_height ; i++)
            begin
                start_item(seq_item);
                seq_item.main_bram_a_we_i = 4'b1111;
                seq_item.main_bram_a_addr_i = i;         
                seq_item.main_bram_a_wdata_i = p_sequencer.cfg.main_bram_wdata_arr[i];
                //img_data_cover.sample();
                finish_item(seq_item);
            end

         start_item(seq_item);
             seq_item.bram_axi_ctrl = 0;
             
             seq_item.main_bram_a_we_i = 4'b0000;
             seq_item.main_bram_a_addr_i = 15'd0;
             seq_item.main_bram_a_wdata_i = 32'd0;
         finish_item(seq_item);  

        $display("\nImage part loaded!\n");
        // ----------------------------------------------------------------------------------------------------------------------------------------------
        
        //      STARTING GAUSSIAN BLUR
        $display("\nStarting with gaussian blur...\n");
        `uvm_do_with(seq_item,{   seq_item.bram_axi_ctrl == 1; seq_item.s00_axi_awaddr == AXI_BASE+START_REG_OFFSET; seq_item.s00_axi_wdata == 32'd1;});
        // ----------------------------------------------------------------------------------------------------------------------------------------------
        
        //      READING BRAM AFTER PROCESSING
        $display("\nReading results from bram\n");
         for (i = 0 ; i < p_sequencer.cfg.img_width*p_sequencer.cfg.img_height ; i++)
            begin
                start_item(seq_item);
                seq_item.main_bram_a_we_i = 4'b0000;
                seq_item.main_bram_a_addr_i = i;         
                //p_sequencer.cfg.main_bram_rdata_arr[i] = seq_item.main_bram_a_rdata_o;
                //img_data_cover.sample();
                finish_item(seq_item);
            end
        // ----------------------------------------------------------------------------------------------------------------------------------------------        
        $display("\nFinished\n");
        
    endtask : body
    
endclass : gaussian_blur_simple_seq
    
`endif
