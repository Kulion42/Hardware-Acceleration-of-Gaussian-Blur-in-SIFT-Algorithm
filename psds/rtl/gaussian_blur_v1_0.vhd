library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils_pkg.all;

entity gaussian_blur_v1_0 is
	generic (
		-- Users to add parameters here
        
        --DATA WIDTH
        DATA_WIDTH : natural := 16;
    
        --SIZE OF BRAMS AND ROM
        KERNEL_ROM_SIZE : natural := 77; --FIXED 
        BRAM_SIZE : natural := 60000; --FIXED


        BRAM_ADDR_WIDTH : natural := 15; --log2c(BRAM_SIZE = 30.000) = 15. Iz nekog razloga ne moze ova funckija u portove
        BYTE_OFFSET : natural := 2;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 5
	);
	port (
		-- Users to add ports here
    
        --Ports for bram controller
        main_bram_a_en_i: in std_logic;
        main_bram_a_we_i: in std_logic_vector(3 downto 0);
        main_bram_a_addr_i: in std_logic_vector(BRAM_ADDR_WIDTH + BYTE_OFFSET - 1 downto 0);    --17 bit
        main_bram_a_rdata_o: out std_logic_vector(2*DATA_WIDTH - 1 downto 0);                   --32 bit
        main_bram_a_wdata_i: in std_logic_vector(2*DATA_WIDTH - 1 downto 0);                    --32 bit



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
		s00_axi_rready	: in std_logic
	);
end gaussian_blur_v1_0;

architecture arch_imp of gaussian_blur_v1_0 is
    
    --signal declaration
    
    signal system_reset_s : std_logic; --koristi se samo za memorijski podsistem
    
    
    --Interface to the AXI LITE controller
    
    signal reg_data_s : std_logic_vector(DATA_WIDTH - 1 downto 0); --izlaz axi lite, ulaz u memorijski podsistem
    
    signal img_height_we_s: std_logic; --izlazni axi lite a ulazni u memorijski podsistem
    signal img_width_we_s: std_logic;
    signal img_offset_up_we_s: std_logic; 
    signal img_offset_down_we_s: std_logic;
    signal img_per_octave_we_s: std_logic;
            
    signal start_we_s : std_logic;
    signal reset_we_s : std_logic;
    --signal ready_we_s : std_logic;
               
    --software read
    signal img_height_axi_s: std_logic_vector(DATA_WIDTH -1 downto 0);          --16 bit
    signal img_width_axi_s: std_logic_vector(DATA_WIDTH -1 downto 0);           --16 bit
    signal img_offset_up_axi_s: std_logic_vector(DATA_WIDTH -1 downto 0);       --16 bit
    signal img_offset_down_axi_s: std_logic_vector(DATA_WIDTH -1 downto 0);     --16 bit
    signal img_per_octave_axi_s: std_logic_vector(DATA_WIDTH -1 downto 0);      --16 bit
        
    signal ready_axi_s : std_logic;
    signal start_axi_s : std_logic;
    signal reset_axi_s : std_logic;
           
    --Interace to the Gaussian blur module
    
    signal reset_reg_s: std_logic;
    signal start_reg_s: std_logic;
    signal ready_reg_s: std_logic;
    
    --IMAGE ELEMENTS
    signal img_height_reg_s: std_logic_vector(DATA_WIDTH -1 downto 0);          --16 bit     
    signal img_width_reg_s: std_logic_vector(DATA_WIDTH -1 downto 0);           --16 bit
    signal img_offset_up_reg_s: std_logic_vector(DATA_WIDTH -1 downto 0);       --16 bit
    signal img_offset_down_reg_s: std_logic_vector(DATA_WIDTH -1 downto 0);     --16 bit
    signal img_per_octave_reg_s: std_logic_vector(DATA_WIDTH -1 downto 0);      --16 bit


    --signal main_bram_a_wdata_i_s: std_logic_vector(2*(DATA_WIDTH-1)-1 downto 0); --30 bit
    --signal main_bram_a_rdata_o_s: std_logic_vector(2*(DATA_WIDTH-1)-1 downto 0); --30 bit
    --end of user signals


	-- component declaration
	component gaussian_blur_v1_0_S00_AXI is
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
        --ready_we_o : out std_logic;
               
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
	end component gaussian_blur_v1_0_S00_AXI;
        
     
    component top_model is
    Generic(
    --DATA WIDTH
    DATA_WIDTH : natural := 16;
    
    --SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE : natural := 77; --FIXED 
    BRAM_SIZE : natural := 60000 --FIXED
    );
    Port ( 
    clk: in std_logic;
    reset: in std_logic;
    start: in std_logic;
    
    --IMAGE ELEMENTS
    img_height: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_width: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_offset_up: in std_logic_vector(DATA_WIDTH -1 downto 0); 
    img_offset_down: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_per_octave: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    --CPU PORTS FOR MAIN_BRAM
    main_bram_a_cpu_en: in std_logic;
    main_bram_a_cpu_we: in std_logic_vector(3 downto 0);
    main_bram_a_cpu_addr: in std_logic_vector(log2c(BRAM_SIZE/2) - 1 downto 0);
    main_bram_a_cpu_rdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    main_bram_a_cpu_wdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    ready: out std_logic
    );
    end component top_model;
    
    component memory_subsystem is
    Generic(
    --DATA WIDTH
    DATA_WIDTH : natural := 16);

    Port (
    clk: in std_logic;
    reset: in std_logic;
    
    -----------------------------------------------------------------
    
    --INTERFACE TO AXI LITE
    
    reg_data_i : in std_logic_vector(DATA_WIDTH - 1 downto 0); --16 bita
    
    img_height_we_i: in std_logic; 
    img_width_we_i: in std_logic;
    img_offset_up_we_i: in std_logic; 
    img_offset_down_we_i: in std_logic;
    img_per_octave_we_i: in std_logic;
    
    start_we_i : in std_logic;
    reset_we_i : in std_logic;
    --ready_wr_i : in std_logic;
       
    --software read
    img_height_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);         --16 bita
    img_width_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);          --16 bita
    img_offset_up_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);      --16 bita
    img_offset_down_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);    --16 bita
    img_per_octave_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);     --16 bita
    
    ready_axi_o : out std_logic;
    start_axi_o : out std_logic; --ako treba da se cita od strane softvera, treba dodati
    reset_axi_o : out std_logic;
     
    --INTERFACE TO GAUSSIAN_BLUR
    
    --registers 
    img_height_o: out std_logic_vector(DATA_WIDTH -1 downto 0);                 --16 bita
    img_width_o: out std_logic_vector(DATA_WIDTH -1 downto 0);                  --16 bita
    img_offset_up_o: out std_logic_vector(DATA_WIDTH -1 downto 0);              --16 bita
    img_offset_down_o: out std_logic_vector(DATA_WIDTH -1 downto 0);            --16 bita
    img_per_octave_o: out std_logic_vector(DATA_WIDTH -1 downto 0);             --16 bita
    
    start_o : out std_logic;
    reset_o : out std_logic;
    
    ready_i : in std_logic
   );

    end component memory_subsystem;
    
begin

-- Instantiation of Axi Bus Interface S00_AXI
gaussian_blur_v1_0_S00_AXI_inst : gaussian_blur_v1_0_S00_AXI
	generic map (
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
        --ready_we_o => ready_we_s;
               
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

	-- Add user logic here
	
    system_reset_s <= not s00_axi_aresetn;
    
           
    --Top modul
    top_model_instance: top_model
    generic map(
    DATA_WIDTH => DATA_WIDTH,
    KERNEL_ROM_SIZE => KERNEL_ROM_SIZE,
    BRAM_SIZE => BRAM_SIZE)
                
    port map (
    clk => s00_axi_aclk,
    reset => reset_reg_s,
    start => start_reg_s,
    
    --IMAGE ELEMENTS
    img_height => img_height_reg_s,
    img_width => img_width_reg_s,
    img_offset_up => img_offset_up_reg_s, 
    img_offset_down => img_offset_down_reg_s,
    img_per_octave => img_per_octave_reg_s,
    
    --BRAMS
    main_bram_a_cpu_en => main_bram_a_en_i,
    main_bram_a_cpu_we => main_bram_a_we_i,
    main_bram_a_cpu_addr => main_bram_a_addr_i(BRAM_ADDR_WIDTH + BYTE_OFFSET - 1 downto BYTE_OFFSET),
    main_bram_a_cpu_rdata => main_bram_a_rdata_o,
    main_bram_a_cpu_wdata => main_bram_a_wdata_i,    --odsecanje? 
    
    ready => ready_reg_s);
    
    
    memory_subsystem_instsance: memory_subsystem
    generic map(
            DATA_WIDTH => DATA_WIDTH
          
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
            --ready_we_i  => ready_we_s,
               
            --software read
            img_height_axi_o => img_height_axi_s,
            img_width_axi_o => img_width_axi_s,
            img_offset_up_axi_o => img_offset_up_axi_s,
            img_offset_down_axi_o => img_offset_down_axi_s,
            img_per_octave_axi_o => img_per_octave_axi_s,
            
            ready_axi_o => ready_axi_s,
            start_axi_o => start_axi_s,
            reset_axi_o => reset_axi_s,
            
            
            --INTERFACE TO GAUSSIAN_BLUR
            
            --registers 
            img_height_o => img_height_reg_s,
            img_width_o => img_width_reg_s,
            img_offset_up_o => img_offset_up_reg_s,
            img_offset_down_o => img_offset_down_reg_s,
            img_per_octave_o => img_per_octave_reg_s,
            
            start_o => start_reg_s,
            reset_o => reset_reg_s,
            ready_i => ready_reg_s
            ); 
    
    
    
    --Addition to instaces
    
    
    
    
    --15 bit data concatenation
    --main_bram_a_rdata_o <= '0'&main_bram_a_rdata_o_s(29 downto 15)&'0'&main_bram_a_rdata_o_s(14 downto 0);
    --main_bram_a_wdata_i_s <= main_bram_a_wdata_i(30 downto 16)&main_bram_a_wdata_i(14 downto 0);
    
    
	-- User logic ends

end arch_imp;




