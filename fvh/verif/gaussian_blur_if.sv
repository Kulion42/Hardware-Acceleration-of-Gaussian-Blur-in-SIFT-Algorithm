
`ifndef GAUSSIAN_BLUR_IF_SV
`define GAUSSIAN_BLUR_IF_SV

interface gaussian_blur_if (input clk, logic rst);

    localparam DATA_WIDTH = 16;
    localparam KERNEL_ROM_SIZE = 77;
    localparam BRAM_SIZE = 60000;
    localparam BRAM_ADDR_WIDTH = 15;
    localparam BYTE_OFFSET = 2;
    
    localparam C_S00_AXI_DATA_WIDTH = 32;
    localparam C_S00_AXI_ADDR_WIDTH = 5;
    
    //User ports
    logic main_bram_a_en_i;
    logic [3 : 0] main_bram_a_we_i;
    logic [BRAM_ADDR_WIDTH + BYTE_OFFSET -1 : 0] main_bram_a_addr_i;
    logic [2 * DATA_WIDTH -1 : 0] main_bram_a_rdata_o;
    logic [2 * DATA_WIDTH -1 : 0] main_bram_a_wdata_i;
    
    //Ports of Axi Slave Bus Interface S00_AXI
    logic [C_S00_AXI_ADDR_WIDTH -1:0] s00_axi_awaddr;
    logic [2:0] s00_axi_awprot;
    logic s00_axi_awvalid;
    logic s00_axi_awready;
    logic [C_S00_AXI_DATA_WIDTH -1:0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8) -1:0] s00_axi_wstrb;
    logic s00_axi_wvalid;
    logic s00_axi_wready;
    logic [1:0] s00_axi_bresp;
    logic s00_axi_bvalid;
    logic s00_axi_bready;
    logic [C_S00_AXI_ADDR_WIDTH -1:0] s00_axi_araddr;
    logic [2:0] s00_axi_arprot;
    logic s00_axi_arvalid;
    logic s00_axi_arready;
    logic [C_S00_AXI_DATA_WIDTH - 1:0] s00_axi_rdata;
    logic [1:0] s00_axi_rresp;
    logic s00_axi_rvalid;
    logic s00_axi_rready;

endinterface : gaussian_blur_if

`endif
