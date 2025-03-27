`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/03/2025 12:58:32 PM
// Design Name: 
// Module Name: gaussian_blur_top
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

`ifndef GAUSSIAN_BLUR_TOP_RAND_SV
`define GAUSSIAN_BLUR_TOP_RAND_SV

module gaussian_blur_top_rand;

    `include "uvm_macros.svh"
    import uvm_pkg::*;
    
    import test_rand_pkg::*;
    
    logic clk;
    logic rst;
    
   //Interface
   gaussian_blur_if gaussian_blur_vif(clk, rst);
   
   //DUT
   GAUSSIAN_BLUR_v1_0  DUT(
                      .s00_axi_aclk     (clk),
                      .s00_axi_aresetn  (rst),
                      .main_bram_a_en_i (gaussian_blur_vif.main_bram_a_en_i),
                      .main_bram_a_we_i (gaussian_blur_vif.main_bram_a_we_i),
                      .main_bram_a_addr_i   (gaussian_blur_vif.main_bram_a_addr_i),
                      .main_bram_a_rdata_o  (gaussian_blur_vif.main_bram_a_rdata_o),
                      .main_bram_a_wdata_i  (gaussian_blur_vif.main_bram_a_wdata_i),
                      
                      .s00_axi_awaddr      (gaussian_blur_vif.s00_axi_awaddr),
                      .s00_axi_awprot      (gaussian_blur_vif.s00_axi_awprot),
                      .s00_axi_awvalid      (gaussian_blur_vif.s00_axi_awvalid),
                      .s00_axi_awready      (gaussian_blur_vif.s00_axi_awready),
                      .s00_axi_wdata      (gaussian_blur_vif.s00_axi_wdata),
                      .s00_axi_wstrb      (gaussian_blur_vif.s00_axi_wstrb),
                      .s00_axi_wvalid      (gaussian_blur_vif.s00_axi_wvalid),
                      .s00_axi_wready     (gaussian_blur_vif.s00_axi_wready),
                      .s00_axi_bresp      (gaussian_blur_vif.s00_axi_bresp),
                      .s00_axi_bvalid      (gaussian_blur_vif.s00_axi_bvalid),
                      .s00_axi_bready      (gaussian_blur_vif.s00_axi_bready),
                      .s00_axi_araddr      (gaussian_blur_vif.s00_axi_araddr),
                      .s00_axi_arprot      (gaussian_blur_vif.s00_axi_arprot),
                      .s00_axi_arvalid      (gaussian_blur_vif.s00_axi_arvalid),
                      .s00_axi_arready      (gaussian_blur_vif.s00_axi_arready),
                      .s00_axi_rdata      (gaussian_blur_vif.s00_axi_rdata),
                      .s00_axi_rresp      (gaussian_blur_vif.s00_axi_rresp),
                      .s00_axi_rvalid      (gaussian_blur_vif.s00_axi_rvalid),
                      .s00_axi_rready      (gaussian_blur_vif.s00_axi_rready)
                      ); 
    
     // run test
   initial begin      
      uvm_config_db#(virtual gaussian_blur_if)::set(null, "uvm_test_top.env_rand", "gaussian_blur_if", gaussian_blur_vif);
      run_test("gaussian_blur_rand_test");
   end
    
   // clock and reset init.
   initial begin
      clk <= 0;
      rst <= 0;
      #50 rst <= 1;
   end

   // clock generation
   always #50 clk = ~clk;                      
    
endmodule : gaussian_blur_top_rand

`endif
