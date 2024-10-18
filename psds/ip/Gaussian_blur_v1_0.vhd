library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils_pkg.ALL;

entity Gaussian_blur_v1_0 is
	generic (
		-- Users to add parameters here
  
        --DATA WIDTH
        DATA_WIDTH : natural := 16;
    
        --SIZE OF BRAMS AND ROM
        KERNEL_ROM_SIZE : natural := 76; --FIXED 
        BRAM_SIZE : natural := 60000; --FIXED
        
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 5;

		-- Parameters of Axi Slave Bus Interface S01_AXI
		C_S01_AXI_ID_WIDTH	: integer	:= 1;
		C_S01_AXI_DATA_WIDTH	: integer	:= 64; --menjano
		C_S01_AXI_ADDR_WIDTH	: integer	:= 16;
		C_S01_AXI_AWUSER_WIDTH	: integer	:= 1;
		C_S01_AXI_ARUSER_WIDTH	: integer	:= 1;
		C_S01_AXI_WUSER_WIDTH	: integer	:= 1;
		C_S01_AXI_RUSER_WIDTH	: integer	:= 1;
		C_S01_AXI_BUSER_WIDTH	: integer	:= 1
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S01_AXI
		s01_axi_aclk	: in std_logic;
		s01_axi_aresetn	: in std_logic;
		s01_axi_awid	: in std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
		s01_axi_awaddr	: in std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
		s01_axi_awlen	: in std_logic_vector(7 downto 0);
		s01_axi_awsize	: in std_logic_vector(2 downto 0);
		s01_axi_awburst	: in std_logic_vector(1 downto 0);
		s01_axi_awlock	: in std_logic;
		s01_axi_awcache	: in std_logic_vector(3 downto 0);
		s01_axi_awprot	: in std_logic_vector(2 downto 0);
		s01_axi_awqos	: in std_logic_vector(3 downto 0);
		s01_axi_awregion	: in std_logic_vector(3 downto 0);
		s01_axi_awuser	: in std_logic_vector(C_S01_AXI_AWUSER_WIDTH-1 downto 0);
		s01_axi_awvalid	: in std_logic;
		s01_axi_awready	: out std_logic;
		s01_axi_wdata	: in std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
		s01_axi_wstrb	: in std_logic_vector((C_S01_AXI_DATA_WIDTH/8)-1 downto 0);
		s01_axi_wlast	: in std_logic;
		s01_axi_wuser	: in std_logic_vector(C_S01_AXI_WUSER_WIDTH-1 downto 0);
		s01_axi_wvalid	: in std_logic;
		s01_axi_wready	: out std_logic;
		s01_axi_bid	: out std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
		s01_axi_bresp	: out std_logic_vector(1 downto 0);
		s01_axi_buser	: out std_logic_vector(C_S01_AXI_BUSER_WIDTH-1 downto 0);
		s01_axi_bvalid	: out std_logic;
		s01_axi_bready	: in std_logic;
		s01_axi_arid	: in std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
		s01_axi_araddr	: in std_logic_vector(C_S01_AXI_ADDR_WIDTH-1 downto 0);
		s01_axi_arlen	: in std_logic_vector(7 downto 0);
		s01_axi_arsize	: in std_logic_vector(2 downto 0);
		s01_axi_arburst	: in std_logic_vector(1 downto 0);
		s01_axi_arlock	: in std_logic;
		s01_axi_arcache	: in std_logic_vector(3 downto 0);
		s01_axi_arprot	: in std_logic_vector(2 downto 0);
		s01_axi_arqos	: in std_logic_vector(3 downto 0);
		s01_axi_arregion	: in std_logic_vector(3 downto 0);
		s01_axi_aruser	: in std_logic_vector(C_S01_AXI_ARUSER_WIDTH-1 downto 0);
		s01_axi_arvalid	: in std_logic;
		s01_axi_arready	: out std_logic;
		s01_axi_rid	: out std_logic_vector(C_S01_AXI_ID_WIDTH-1 downto 0);
		s01_axi_rdata	: out std_logic_vector(C_S01_AXI_DATA_WIDTH-1 downto 0);
		s01_axi_rresp	: out std_logic_vector(1 downto 0);
		s01_axi_rlast	: out std_logic;
		s01_axi_ruser	: out std_logic_vector(C_S01_AXI_RUSER_WIDTH-1 downto 0);
		s01_axi_rvalid	: out std_logic;
		s01_axi_rready	: in std_logic
	);
end Gaussian_blur_v1_0;

architecture arch_imp of Gaussian_blur_v1_0 is

    --signal declarations
    
    signal system_reset_s : std_logic;
  
    
    --Interface to the AXI LITE controller
    
    signal reg_data_s : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    signal img_height_we_s: std_logic;
    signal img_width_we_s: std_logic;
    signal img_offset_up_we_s: std_logic; 
    signal img_offset_down_we_s: std_logic;
    signal img_per_octave_we_s: std_logic;
            
    signal start_we_s : std_logic;
    signal reset_we_s : std_logic;
    --signal ready_wr_s : std_logic;
               
    --software read
    signal img_height_axi_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_width_axi_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_offset_up_axi_s: std_logic_vector(DATA_WIDTH -1 downto 0); 
    signal img_offset_down_axi_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_per_octave_axi_s: std_logic_vector(DATA_WIDTH -1 downto 0);
        
    signal ready_axi_s : std_logic;
    signal start_axi_s : std_logic;
    signal reset_axi_s : std_logic;
 
    
    --Interface to the AXI FULL controller
    signal main_mem_addr_axi_s : std_logic_vector(log2c(BRAM_SIZE)-1 downto 0);
    signal main_mem_wdata_axi_s : std_logic_vector(2*DATA_WIDTH - 1 downto 0);
    signal main_mem_we_axi_s : std_logic_vector(3 downto 0);
    signal main_mem_en_axi_s : std_logic;
        
    signal main_mem_rdata_axi_s : std_logic_vector(2*DATA_WIDTH-1 downto 0); --signal ka CPU
    
    
    --axi full interface towards main bram A port
    signal main_mem_a_addr_axi_s : std_logic_vector(log2c(BRAM_SIZE)-1 downto 0);
    signal main_mem_a_wdata_axi_s : std_logic_vector(2*DATA_WIDTH - 1 downto 0);
    signal main_mem_a_we_axi_s : std_logic_vector(3 downto 0);
    signal main_mem_a_en_axi_s : std_logic;
        
    signal main_mem_a_rdata_axi_s : std_logic_vector(2*DATA_WIDTH-1 downto 0); --signal ka CPU
    
    
    --axi full interface towards main bram B port
    signal main_mem_b_addr_axi_s : std_logic_vector(log2c(BRAM_SIZE)-1 downto 0);
    signal main_mem_b_wdata_axi_s : std_logic_vector(2*DATA_WIDTH - 1 downto 0);
    signal main_mem_b_we_axi_s : std_logic_vector(3 downto 0);
    signal main_mem_b_en_axi_s : std_logic;
        
    signal main_mem_b_rdata_axi_s : std_logic_vector(2*DATA_WIDTH-1 downto 0); --signal ka CPU
    
    
    --INPUT OF MEMORY SUBSYSTEM
    
    --signals outputs of muxes for main bram
    signal main_bram_a_en_s: std_logic;
    signal main_bram_a_we_s: std_logic_vector(3 downto 0);
    signal main_bram_a_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal main_bram_a_rdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    signal main_bram_a_wdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    signal main_bram_b_en_s: std_logic;
    signal main_bram_b_we_s: std_logic_vector(3 downto 0);
    signal main_bram_b_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal main_bram_b_rdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    signal main_bram_b_wdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    --signals between gausian blur and tmp bram
    signal tmp_bram_a_en_s: std_logic;
    signal tmp_bram_a_we_s: std_logic_vector(3 downto 0);
    signal tmp_bram_a_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal tmp_bram_a_rdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    signal tmp_bram_a_wdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    signal tmp_bram_b_en_s: std_logic;
    signal tmp_bram_b_we_s: std_logic_vector(3 downto 0);
    signal tmp_bram_b_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal tmp_bram_b_rdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    signal tmp_bram_b_wdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    
    --Interace to the Gaussian blur module
    
    signal reset_reg_s: std_logic;
    signal start_reg_s: std_logic;
    signal ready_reg_s: std_logic;
    
    --IMAGE ELEMENTS
    signal img_height_reg_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_width_reg_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_offset_up_reg_s: std_logic_vector(DATA_WIDTH -1 downto 0); 
    signal img_offset_down_reg_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_per_octave_reg_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    
    --signals of gaussian blur towards muxes for main bram
    signal main_bram_a_en_gaus_s: std_logic;
    signal main_bram_a_we_gaus_s: std_logic_vector(3 downto 0);
    signal main_bram_a_addr_gaus_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal main_bram_a_rdata_gaus_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    signal main_bram_a_wdata_gaus_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    signal main_bram_b_en_gaus_s: std_logic;
    signal main_bram_b_we_gaus_s: std_logic_vector(3 downto 0);
    signal main_bram_b_addr_gaus_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal main_bram_b_rdata_gaus_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    signal main_bram_b_wdata_gaus_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    --signals for tmp bram are already declared as common for tmp bram and gaus
    
    --selekt signal za mux-eve na port A i port B
    signal main_bram_select : std_logic;
    
    
    --dva signala koji se korite jer su wready i rvalid out portovi a potrebni su za proveru za muxeve
    signal s01_axi_wready_buffer : std_logic;
    signal s01_axi_rvalid_buffer : std_logic;
    
    
    --END OF USER SIGNALS
    
    
	-- component declaration
	component Gaussian_blur_v1_0_S00_AXI is
		generic (
		
		--DATA WIDTH
        DATA_WIDTH : natural := 16;    
		
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
		);
		port (
		
		--User ports added here
		reg_data_o : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    
        img_height_we_o: out std_logic;
        img_width_we_o: out std_logic;
        img_offset_up_we_o: out std_logic; 
        img_offset_down_we_o: out std_logic;
        img_per_octave_we_o: out std_logic;
        
        start_we_o : out std_logic;
        reset_we_o : out std_logic;
        --ready_wr_o : out std_logic;
               
        --software read
        img_height_axi_i: in std_logic_vector(DATA_WIDTH -1 downto 0);
        img_width_axi_i: in std_logic_vector(DATA_WIDTH -1 downto 0);
        img_offset_up_axi_i: in std_logic_vector(DATA_WIDTH -1 downto 0); 
        img_offset_down_axi_i: in std_logic_vector(DATA_WIDTH -1 downto 0);
        img_per_octave_axi_i: in std_logic_vector(DATA_WIDTH -1 downto 0);
        
        ready_axi_i : in std_logic;
        start_axi_i : in std_logic;
        reset_axi_i : in std_logic;
        
        --END user ports
        
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component Gaussian_blur_v1_0_S00_AXI;

	component Gaussian_blur_v1_0_S01_AXI is
		generic (
		--DATA WIDTH
        DATA_WIDTH : natural := 16;
    
        --SIZE OF BRAMS
        BRAM_SIZE : natural := 60000; --FIXED
        
		C_S_AXI_ID_WIDTH	: integer	:= 1;
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 10;
		C_S_AXI_AWUSER_WIDTH	: integer	:= 0;
		C_S_AXI_ARUSER_WIDTH	: integer	:= 0;
		C_S_AXI_WUSER_WIDTH	: integer	:= 0;
		C_S_AXI_RUSER_WIDTH	: integer	:= 0;
		C_S_AXI_BUSER_WIDTH	: integer	:= 0
		);
		port (
		
		--User ports
		
		main_mem_addr_axi_o : out std_logic_vector(log2c(BRAM_SIZE)-1 downto 0);
        main_mem_wdata_axi_o : out std_logic_vector(2*DATA_WIDTH - 1 downto 0);
        main_mem_we_axi_o : out std_logic_vector(3 downto 0);
        main_mem_en_axi_o : out std_logic;
    
        main_mem_rdata_axi_i : in std_logic_vector(2*DATA_WIDTH-1 downto 0); --software read
		
		--END user ports
		
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWID	: in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWLEN	: in std_logic_vector(7 downto 0);
		S_AXI_AWSIZE	: in std_logic_vector(2 downto 0);
		S_AXI_AWBURST	: in std_logic_vector(1 downto 0);
		S_AXI_AWLOCK	: in std_logic;
		S_AXI_AWCACHE	: in std_logic_vector(3 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWQOS	: in std_logic_vector(3 downto 0);
		S_AXI_AWREGION	: in std_logic_vector(3 downto 0);
		S_AXI_AWUSER	: in std_logic_vector(C_S_AXI_AWUSER_WIDTH-1 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WLAST	: in std_logic;
		S_AXI_WUSER	: in std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BID	: out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BUSER	: out std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARID	: in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARLEN	: in std_logic_vector(7 downto 0);
		S_AXI_ARSIZE	: in std_logic_vector(2 downto 0);
		S_AXI_ARBURST	: in std_logic_vector(1 downto 0);
		S_AXI_ARLOCK	: in std_logic;
		S_AXI_ARCACHE	: in std_logic_vector(3 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARQOS	: in std_logic_vector(3 downto 0);
		S_AXI_ARREGION	: in std_logic_vector(3 downto 0);
		S_AXI_ARUSER	: in std_logic_vector(C_S_AXI_ARUSER_WIDTH-1 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RID	: out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RLAST	: out std_logic;
		S_AXI_RUSER	: out std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component Gaussian_blur_v1_0_S01_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
Gaussian_blur_v1_0_S00_AXI_inst : Gaussian_blur_v1_0_S00_AXI
	generic map (
	   
	    --user generics
	    DATA_WIDTH => DATA_WIDTH,
	    --end user generics
	
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	   
	    --user ports
	    reg_data_o => reg_data_s,
    
        img_height_we_o => img_height_we_s,
        img_width_we_o => img_width_we_s,
        img_offset_up_we_o => img_offset_up_we_s,
        img_offset_down_we_o => img_offset_down_we_s,
        img_per_octave_we_o => img_per_octave_we_s,
        
        start_we_o => start_we_s,
        reset_we_o => reset_we_s, 
        --ready_wr_o => img_height_wr_s;
               
        --software read
        img_height_axi_i => img_height_axi_s,
        img_width_axi_i => img_width_axi_s,
        img_offset_up_axi_i => img_offset_up_axi_s,
        img_offset_down_axi_i => img_offset_down_axi_s,
        img_per_octave_axi_i => img_per_octave_axi_s,
        
        ready_axi_i => ready_axi_s, 
        start_axi_i => start_axi_s, 
        reset_axi_i => reset_axi_s, 
	
	
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

-- Instantiation of Axi Bus Interface S01_AXI
Gaussian_blur_v1_0_S01_AXI_inst : Gaussian_blur_v1_0_S01_AXI
	generic map (
	
	    --user generics
	    DATA_WIDTH => DATA_WIDTH,
        BRAM_SIZE => BRAM_SIZE,
	    --end user generics
	       
		C_S_AXI_ID_WIDTH	=> C_S01_AXI_ID_WIDTH,
		C_S_AXI_DATA_WIDTH	=> C_S01_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S01_AXI_ADDR_WIDTH,
		C_S_AXI_AWUSER_WIDTH	=> C_S01_AXI_AWUSER_WIDTH,
		C_S_AXI_ARUSER_WIDTH	=> C_S01_AXI_ARUSER_WIDTH,
		C_S_AXI_WUSER_WIDTH	=> C_S01_AXI_WUSER_WIDTH,
		C_S_AXI_RUSER_WIDTH	=> C_S01_AXI_RUSER_WIDTH,
		C_S_AXI_BUSER_WIDTH	=> C_S01_AXI_BUSER_WIDTH
	)
	port map (
	   
	    --user ports
	    main_mem_addr_axi_o => main_mem_addr_axi_s,  
        main_mem_wdata_axi_o => main_mem_wdata_axi_s,
        main_mem_we_axi_o => main_mem_we_axi_s,
        main_mem_en_axi_o => main_mem_en_axi_s,
    
        main_mem_rdata_axi_i => main_mem_rdata_axi_s, --software read
	    --end user ports
	
		S_AXI_ACLK	=> s01_axi_aclk,
		S_AXI_ARESETN	=> s01_axi_aresetn,
		S_AXI_AWID	=> s01_axi_awid,
		S_AXI_AWADDR	=> s01_axi_awaddr,
		S_AXI_AWLEN	=> s01_axi_awlen,
		S_AXI_AWSIZE	=> s01_axi_awsize,
		S_AXI_AWBURST	=> s01_axi_awburst,
		S_AXI_AWLOCK	=> s01_axi_awlock,
		S_AXI_AWCACHE	=> s01_axi_awcache,
		S_AXI_AWPROT	=> s01_axi_awprot,
		S_AXI_AWQOS	=> s01_axi_awqos,
		S_AXI_AWREGION	=> s01_axi_awregion,
		S_AXI_AWUSER	=> s01_axi_awuser,
		S_AXI_AWVALID	=> s01_axi_awvalid,
		S_AXI_AWREADY	=> s01_axi_awready,
		S_AXI_WDATA	=> s01_axi_wdata,
		S_AXI_WSTRB	=> s01_axi_wstrb,
		S_AXI_WLAST	=> s01_axi_wlast,
		S_AXI_WUSER	=> s01_axi_wuser,
		S_AXI_WVALID	=> s01_axi_wvalid,
		S_AXI_WREADY	=> s01_axi_wready_buffer, --menjano za buffer
		S_AXI_BID	=> s01_axi_bid,
		S_AXI_BRESP	=> s01_axi_bresp,
		S_AXI_BUSER	=> s01_axi_buser,
		S_AXI_BVALID	=> s01_axi_bvalid,
		S_AXI_BREADY	=> s01_axi_bready,
		S_AXI_ARID	=> s01_axi_arid,
		S_AXI_ARADDR	=> s01_axi_araddr,
		S_AXI_ARLEN	=> s01_axi_arlen,
		S_AXI_ARSIZE	=> s01_axi_arsize,
		S_AXI_ARBURST	=> s01_axi_arburst,
		S_AXI_ARLOCK	=> s01_axi_arlock,
		S_AXI_ARCACHE	=> s01_axi_arcache,
		S_AXI_ARPROT	=> s01_axi_arprot,
		S_AXI_ARQOS	=> s01_axi_arqos,
		S_AXI_ARREGION	=> s01_axi_arregion,
		S_AXI_ARUSER	=> s01_axi_aruser,
		S_AXI_ARVALID	=> s01_axi_arvalid,
		S_AXI_ARREADY	=> s01_axi_arready,
		S_AXI_RID	=> s01_axi_rid,
		S_AXI_RDATA	=> s01_axi_rdata,
		S_AXI_RRESP	=> s01_axi_rresp,
		S_AXI_RLAST	=> s01_axi_rlast,
		S_AXI_RUSER	=> s01_axi_ruser,
		S_AXI_RVALID	=> s01_axi_rvalid_buffer,  --menjano za buffer
		S_AXI_RREADY	=> s01_axi_rready
	);

	-- Add user logic here
    system_reset_s <= not s00_axi_aresetn;
    
    --memory subsystem
    mem_subsystem: entity work.memory_subsystem(struct)
        generic map(
            DATA_WIDTH => DATA_WIDTH,
            BRAM_SIZE => BRAM_SIZE
        )
        port map(
            clk => s00_axi_aclk,
            reset => system_reset_s,
            
            -----------------------------------------------------------------
            
            --INTERFACE TO AXI LITE
            
            reg_data_i => reg_data_s,
            
            img_height_we_i => img_height_we_s,
            img_width_we_i => img_width_we_s,
            img_offset_up_we_i => img_offset_up_we_s,
            img_offset_down_we_i => img_offset_down_we_s,
            img_per_octave_we_i => img_per_octave_we_s,
            
            start_we_i  => start_we_s,
            reset_we_i  => reset_we_s,
            --ready_wr_i  => ready_wr_s,
               
            --software read
            img_height_axi_o => img_height_axi_s,
            img_width_axi_o => img_width_axi_s,
            img_offset_up_axi_o => img_offset_up_axi_s,
            img_offset_down_axi_o => img_offset_down_axi_s,
            img_per_octave_axi_o => img_per_octave_axi_s,
            
            ready_axi_o => ready_axi_s,
            start_axi_o => start_axi_s,
            reset_axi_o => reset_axi_s,
            
            -----------------------------------------------------------------
            --MAIN BRAM INTERFACE
            
            --main bram interface A port
            main_mem_a_addr_i => main_bram_a_addr_s,
            main_mem_a_wdata_i => main_bram_a_wdata_s,
            main_mem_a_we_i => main_bram_a_we_s,
            main_mem_a_en_i => main_bram_a_en_s,
            
            main_mem_a_rdata_o => main_bram_a_rdata_s,
            
            --main bram interface B port
            main_mem_b_addr_i => main_bram_b_addr_s,
            main_mem_b_wdata_i => main_bram_a_wdata_s,
            main_mem_b_we_i => main_bram_b_we_s,
            main_mem_b_en_i => main_bram_b_en_s,
            
            main_mem_b_rdata_o => main_bram_b_rdata_s,
            
            -----------------------------------------------------------------
            
            --INTERFACE TO GAUSSIAN_BLUR
            
            --registers 
            img_height_o => img_height_reg_s,
            img_width_o => img_width_reg_s,
            img_offset_up_o => img_offset_up_reg_s,
            img_offset_down_o => img_offset_down_reg_s,
            img_per_octave_o => img_per_octave_reg_s,
            
            start_o => start_reg_s,
            reset_o => reset_reg_s,
            ready_i => ready_reg_s,

          
            --temp bram interface
            tmp_mem_a_addr_i => tmp_bram_a_addr_s, 
            tmp_mem_a_wdata_i => tmp_bram_a_wdata_s, 
            tmp_mem_a_we_i => tmp_bram_a_we_s, 
            tmp_mem_a_en_i => tmp_bram_a_en_s, 
            
            tmp_mem_a_rdata_o => tmp_bram_a_rdata_s,
            
         
            tmp_mem_b_addr_i => tmp_bram_b_addr_s, 
            tmp_mem_b_wdata_i => tmp_bram_b_wdata_s,
            tmp_mem_b_we_i => tmp_bram_b_we_s,
            tmp_mem_b_en_i => tmp_bram_b_en_s, 
            
            tmp_mem_b_rdata_o => tmp_bram_b_rdata_s
            ); 
           
    --Gaussian blur modul
    Gaussian_blur: entity work.gaussian_blur(Mixed)
        generic map(
            DATA_WIDTH => DATA_WIDTH,
            BRAM_SIZE =>  BRAM_SIZE,
            KERNEL_ROM_SIZE => KERNEL_ROM_SIZE)
        port map(
        
            clk => s00_axi_aclk,
            
            --IMAGE ELEMENTS
            img_height => img_height_reg_s,
            img_width => img_width_reg_s,
            img_offset_up => img_offset_up_reg_s,
            img_offset_down => img_offset_down_reg_s,
            img_per_octave => img_per_octave_reg_s,
            
            reset => reset_reg_s,
            start => start_reg_s,
            ready => ready_reg_s,
            
            --BRAMS
            main_bram_a_en => main_bram_a_en_gaus_s,
            main_bram_a_we => main_bram_a_we_gaus_s,
            main_bram_a_addr => main_bram_a_addr_gaus_s,
            main_bram_a_rdata => main_bram_a_rdata_gaus_s,
            
            main_bram_a_wdata => main_bram_a_wdata_gaus_s,
            
            
            main_bram_b_en => main_bram_b_en_gaus_s,
            main_bram_b_we => main_bram_b_we_gaus_s,
            main_bram_b_addr => main_bram_b_addr_gaus_s,
            main_bram_b_rdata => main_bram_b_rdata_gaus_s,
            
            main_bram_b_wdata => main_bram_b_wdata_gaus_s,
            
            
            tmp_bram_a_en => tmp_bram_a_en_s,
            tmp_bram_a_we => tmp_bram_a_we_s,
            tmp_bram_a_addr => tmp_bram_a_addr_s,
            tmp_bram_a_rdata => tmp_bram_a_rdata_s,
            
            tmp_bram_a_wdata => tmp_bram_a_wdata_s,
            
            
            tmp_bram_b_en => tmp_bram_b_en_s,
            tmp_bram_b_we => tmp_bram_b_we_s,
            tmp_bram_b_addr => tmp_bram_b_addr_s,
            tmp_bram_b_rdata => tmp_bram_b_rdata_s,
            
            tmp_bram_b_wdata => tmp_bram_b_wdata_s);
  
  main_bram_mux_portA:
    main_bram_a_en_s <= main_mem_a_en_axi_s when main_bram_select = '1' else main_bram_a_en_gaus_s;
    main_bram_a_we_s <= main_mem_a_we_axi_s when main_bram_select = '1' else main_bram_a_we_gaus_s;
    main_bram_a_addr_s <= main_mem_a_addr_axi_s when main_bram_select = '1' else main_bram_a_addr_gaus_s;
    main_bram_a_wdata_s <= main_mem_a_wdata_axi_s when main_bram_select = '1' else main_bram_a_wdata_gaus_s;
  
  main_bram_mux_portB:
    main_bram_b_en_s <= main_mem_b_en_axi_s when main_bram_select = '1' else main_bram_b_en_gaus_s;
    main_bram_b_we_s <= main_mem_b_we_axi_s when main_bram_select = '1' else main_bram_b_we_gaus_s;
    main_bram_b_addr_s <= main_mem_b_addr_axi_s when main_bram_select = '1' else main_bram_b_addr_gaus_s;
    main_bram_b_wdata_s <= main_mem_b_wdata_axi_s when main_bram_select = '1' else main_bram_b_wdata_gaus_s;
    
    --ovo su muxevi koji vode ka main bram-u
    
    --potreban demux koji vodi od main bram-a ka ili ip ili cpu
    
    
  mux_select_gen:
    process (s01_axi_wvalid, s01_axi_wready_buffer, s01_axi_rvalid_buffer, s01_axi_rready)
    begin
        if (s01_axi_wvalid = '1' and s01_axi_wready_buffer = '1') or (s01_axi_rvalid_buffer = '1' and s01_axi_rready = '1') then
            main_bram_select <= '1';  -- Assert mux selection signal when write address or data is valid
        else
            main_bram_select <= '0';  -- De-assert when no write transaction is taking place
        end if;
    end process;  
    
    s01_axi_wready <= s01_axi_wready_buffer;
    s01_axi_rvalid <= s01_axi_rvalid_buffer;
    
    
             --Dva signala za proveru treba umetnuti tamo gde su originali
             
             --proces za mux treba podeliti, jedno je za mux jedno je za demux
         
            --Treba razdeliti podatke sa axija na podatke koji se vuku u bram
            --rutirati po 30 bitnim podacima
    
            --potrebno prebaciti logiku iz top.vhd
            
            
            --dodati demux za povratne vrednosti
            
	-- User logic ends

end arch_imp;
