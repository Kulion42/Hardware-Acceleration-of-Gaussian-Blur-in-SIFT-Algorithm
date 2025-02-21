`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2025 10:34:50 AM
// Design Name: 
// Module Name: seq_item
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

`ifndef SEQ_ITEM_SV
`define SEQ_ITEM_SV

    parameter DATA_WIDTH = 16;
    parameter KERNEL_ROM_SIZE = 77;
    parameter BRAM_SIZE = 30000;
    parameter BRAM_ADDR_WIDTH = 15;
    parameter BYTE_OFFSET = 2;
    
    parameter AXI_BASE = 5'b00000;  
    parameter IMG_WIDTH_REG_OFFSET = 5'b00000; 
    parameter IMG_HEIGHT_REG_OFFSET = 5'b00100;
    parameter IMG_OFFSET_UP_REG_OFFSET = 5'b01000; 
    parameter IMG_OFFSET_DOWN_REG_OFFSET = 5'b01100;
    parameter NUM_IMG_OCT_REG_OFFSET = 5'b10000;
    parameter START_REG_OFFSET = 5'b11000;
    parameter RESET_REG_OFFSET = 5'b10100;
    parameter READY_REG_OFFSET = 5'b11100;
    
    parameter C_S00_AXI_DATA_WIDTH = 32;
    parameter C_S00_AXI_ADDR_WIDTH = 5;
    
class gaussian_blur_seq_item extends uvm_sequence_item;    
    
    //Control signal
    rand logic bram_axi_ctrl;
    
    //Interface signals
    rand logic main_bram_a_en_i;
    rand logic [3 : 0] main_bram_a_we_i;
    rand logic [BRAM_ADDR_WIDTH + BYTE_OFFSET -1 : 0] main_bram_a_addr_i;
    rand logic [2 * DATA_WIDTH -1 : 0] main_bram_a_rdata_o;
    rand logic [2 * DATA_WIDTH -1 : 0] main_bram_a_wdata_i;
    
    //Ports of Axi Slave Bus Interface S00_AXI
    rand logic [C_S00_AXI_ADDR_WIDTH -1:0] s00_axi_awaddr;
    rand logic [2:0] s00_axi_awprot;
    rand logic s00_axi_awvalid;
    rand logic s00_axi_awready;
    rand logic [C_S00_AXI_DATA_WIDTH -1:0] s00_axi_wdata;
    rand logic [(C_S00_AXI_DATA_WIDTH/8) -1:0] s00_axi_wstrb;
    rand logic s00_axi_wvalid;
    rand logic s00_axi_wready;
    rand logic [1:0] s00_axi_bresp;
    rand logic s00_axi_bvalid;
    rand logic s00_axi_bready;
    rand logic [C_S00_AXI_ADDR_WIDTH -1:0] s00_axi_araddr;
    rand logic [2:0] s00_axi_arprot;
    rand logic s00_axi_arvalid;
    rand logic s00_axi_arready;
    rand logic [C_S00_AXI_DATA_WIDTH - 1:0] s00_axi_rdata;
    rand logic [1:0] s00_axi_rresp;
    rand logic s00_axi_rvalid;
    rand logic s00_axi_rready;

    `uvm_object_utils_begin(gaussian_blur_seq_item)
    
		`uvm_field_int(main_bram_a_en_i, UVM_DEFAULT)	   
		`uvm_field_int(main_bram_a_we_i, UVM_DEFAULT)
		`uvm_field_int(main_bram_a_addr_i, UVM_DEFAULT)
		`uvm_field_int(main_bram_a_rdata_o, UVM_DEFAULT)
		`uvm_field_int(main_bram_a_wdata_i, UVM_DEFAULT)
		
		`uvm_field_int(s00_axi_awaddr, UVM_DEFAULT)
		`uvm_field_int(s00_axi_awprot, UVM_DEFAULT)
		`uvm_field_int(s00_axi_awvalid, UVM_DEFAULT)
		`uvm_field_int(s00_axi_awready, UVM_DEFAULT)
		`uvm_field_int(s00_axi_wdata, UVM_DEFAULT)
		`uvm_field_int(s00_axi_wstrb, UVM_DEFAULT)
		`uvm_field_int(s00_axi_wvalid, UVM_DEFAULT)
		`uvm_field_int(s00_axi_wready, UVM_DEFAULT)
		`uvm_field_int(s00_axi_bresp, UVM_DEFAULT)
		`uvm_field_int(s00_axi_bvalid, UVM_DEFAULT)
		`uvm_field_int(s00_axi_bready, UVM_DEFAULT)
		`uvm_field_int(s00_axi_araddr, UVM_DEFAULT)
		`uvm_field_int(s00_axi_arprot, UVM_DEFAULT)
		`uvm_field_int(s00_axi_arvalid, UVM_DEFAULT)
		`uvm_field_int(s00_axi_arready, UVM_DEFAULT)
		`uvm_field_int(s00_axi_rdata, UVM_DEFAULT)
		`uvm_field_int(s00_axi_rresp, UVM_DEFAULT)
		`uvm_field_int(s00_axi_rvalid, UVM_DEFAULT)
		`uvm_field_int(s00_axi_rready, UVM_DEFAULT)
   	`uvm_object_utils_end
   	
   	//Constraint for write enabling bytes bram 
   	constraint main_bram_we_constr {main_bram_a_we_i inside {4'b1111, 4'b0000};};
   	
   	//Constraint for write enabling bytes axi
   	constraint axi_wstrb_constr {s00_axi_wstrb inside {4'b1111, 4'b0000};};
   	
   	//Constraint for bram adress
   	constraint main_bram_addr_constr {main_bram_a_addr_i < 4*BRAM_SIZE; };
   	
   	//Constraints for bram data
   	constraint main_bram_wdata_up_constr {main_bram_a_wdata_i[2 * DATA_WIDTH -1] == 1'b0; main_bram_a_wdata_i[2 * DATA_WIDTH -2] == 1'b0;};
   	constraint main_bram_wdata_down_constr {main_bram_a_wdata_i[DATA_WIDTH -1] == 1'b0; main_bram_a_wdata_i[DATA_WIDTH -2] == 1'b0;};
   	
   	function new( string name = "gaussian_blur_seq_item");
        super.new(name);
    endfunction 

   	 
endclass : gaussian_blur_seq_item

`endif

