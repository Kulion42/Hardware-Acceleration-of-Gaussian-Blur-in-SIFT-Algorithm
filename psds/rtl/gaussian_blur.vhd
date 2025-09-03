----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/13/2024 07:28:04 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils_pkg.ALL;

entity gaussian_blur is
Generic(
    -- DATA WIDTH
    DATA_WIDTH : natural := 16;
    
    -- SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE : natural := 77;  
    BRAM_SIZE : natural := 60000 
);
Port ( 
    clk: in std_logic;
    reset: in std_logic;
    start: in std_logic;
    
    -- IMAGE ELEMENTS
    img_height: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_width: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_offset_up: in std_logic_vector(DATA_WIDTH -1 downto 0); 
    img_offset_down: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_per_octave: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    -- BRAMS
    -- Main BRAM Port A is used by CPU
    main_bram_b_en: out std_logic;
    main_bram_b_we: out std_logic_vector(3 downto 0);
    main_bram_b_addr: out std_logic_vector(log2c(BRAM_SIZE/2) - 1 downto 0);
    main_bram_b_rdata: in std_logic_vector(2 *(DATA_WIDTH-1) -1 downto 0);
    main_bram_b_wdata: out std_logic_vector(2 *(DATA_WIDTH-1) -1 downto 0);    
    
    tmp_bram_a_en: out std_logic;
    tmp_bram_a_we: out std_logic_vector(3 downto 0);
    tmp_bram_a_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    tmp_bram_a_rdata: in std_logic_vector((DATA_WIDTH-1) -1 downto 0);
    tmp_bram_a_wdata: out std_logic_vector((DATA_WIDTH-1) -1 downto 0);
    
    tmp_bram_b_en: out std_logic;
    tmp_bram_b_we: out std_logic_vector(3 downto 0);
    tmp_bram_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    tmp_bram_b_rdata: in std_logic_vector((DATA_WIDTH-1) -1 downto 0);
    tmp_bram_b_wdata: out std_logic_vector((DATA_WIDTH-1) -1 downto 0);
    
    -- Ready signal of whole gaussian_blur module. High when
    -- both convolutions are finished and no edge detected.
    ready: out std_logic
    
);
end gaussian_blur;

architecture Mixed of gaussian_blur is

component convolute_loops 
Generic(
    -- WIDTH OF DATA
    DATA_WIDTH : natural := 16;
    
    -- CONVOLUTION DIRECTION
    HORIZONTAL: boolean := true;
    
    -- PARAMETRS OF CONVOLUTION
    R_PIXEL: natural := 1;
    W_PIXEL: natural := 2;  
    
    -- SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE : natural := 77;  
    BRAM_SIZE : natural := 60000 

);
Port ( 
    clk : in std_logic;
    reset: in std_logic;
    start: in std_logic;
    
    -- IMAGE ELEMENTS
    img_height: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_width: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_offset_up: in std_logic_vector(DATA_WIDTH -1 downto 0); 
    img_offset_down: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    sigma_size : in std_logic_vector(DATA_WIDTH/2 -1 downto 0);
      
    bram1_a_en: out std_logic;
    bram1_a_we: out std_logic_vector(3 downto 0);
    bram1_a_addr: out std_logic_vector(log2c(BRAM_SIZE/R_PIXEL) - 1 downto 0);
    bram1_a_rdata: in std_logic_vector(R_PIXEL *(DATA_WIDTH -1) -1 downto 0);
    bram1_b_en: out std_logic;
    bram1_b_we: out std_logic_vector(3 downto 0);
    bram1_b_addr: out std_logic_vector(log2c(BRAM_SIZE/R_PIXEL) - 1 downto 0);
    bram1_b_rdata: in std_logic_vector(R_PIXEL *(DATA_WIDTH -1) -1 downto 0);
    
    kernel_rom_en: out std_logic;
    kernel_rom_addr: out std_logic_vector(log2c(KERNEL_ROM_SIZE) - 1 downto 0);
    kernel_rom_data: in std_logic_vector(DATA_WIDTH -1 downto 0);
       
    bram2_a_en: out std_logic;
    bram2_a_we: out std_logic_vector(3 downto 0);
    bram2_a_addr: out std_logic_vector(log2c(BRAM_SIZE/W_PIXEL) - 1 downto 0);
    bram2_a_wdata: out std_logic_vector(W_PIXEL *(DATA_WIDTH -1) -1 downto 0);
    bram2_b_en: out std_logic;
    bram2_b_we: out std_logic_vector(3 downto 0);
    bram2_b_addr: out std_logic_vector(log2c(BRAM_SIZE/W_PIXEL) - 1 downto 0);
    bram2_b_wdata: out std_logic_vector(W_PIXEL *(DATA_WIDTH -1) -1 downto 0);
    
    ready : out std_logic
      
);    
end component;

component kernel_rom 
Generic (
    DATA_WIDTH : natural := 16;
    KERNEL_ROM_SIZE : natural := 77      
);
Port ( 
    clk: in std_logic;
    reset: in std_logic;
    
    img_number: in std_logic_vector(DATA_WIDTH- 1 downto 0);
      
    kernel_rom_a_en: in std_logic;
    kernel_rom_a_addr: in std_logic_vector(log2c(KERNEL_ROM_SIZE) -1 downto 0);
    kernel_rom_b_en: in std_logic;
    kernel_rom_b_addr: in std_logic_vector(log2c(KERNEL_ROM_SIZE) -1 downto 0);
    
    kernel_rom_a_data: out std_logic_vector(DATA_WIDTH -1 downto 0); 
    kernel_rom_b_data: out std_logic_vector(DATA_WIDTH -1 downto 0); 
    
    sigma_size: out std_logic_vector(DATA_WIDTH/2 -1 downto 0)
);
end component;

-- ROM enable signals. 
signal rom_a_en,rom_b_en: std_logic;
-- Start signal for Horizontal convolution, ready signals from both convolutions.
signal start_x_conv, end_x_conv, end_y_conv: std_logic;
-- Edge detector register signal
signal edge_reg_o: std_logic;

-- ROM signals for address and data
signal rom_a_addr, rom_b_addr: std_logic_vector(log2c(KERNEL_ROM_SIZE) -1 downto 0);
signal rom_a_data, rom_b_data: std_logic_vector(DATA_WIDTH -1 downto 0);

-- Size signal read from ROM
signal size: std_logic_vector(DATA_WIDTH/2 -1 downto 0);

-- BRAM write enable signals.
signal main_we_x, tmp_we_a_y, tmp_we_b_y, tmp_we_a_x, tmp_we_b_x, main_we_y: std_logic_vector(3 downto 0);

-- BRAM signals towards 30.000 locations BRAM (32 bit BRAM)
signal write_x_b_addr, read_y_b_addr: std_logic_vector(log2c(BRAM_SIZE/2) - 1 downto 0);

-- BRAM signals towards 60.000 locations BRAM (16 bit BRAM)
signal write_y_a_addr, write_y_b_addr, read_x_a_addr, read_x_b_addr: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);

-- dummy signal used for Xcelium simulator.
signal dummy : std_logic_vector(2*(DATA_WIDTH-1) -1 downto 0) := (others => '0');

begin

kernel_rom_gen: kernel_rom 
    Generic map(
        DATA_WIDTH => DATA_WIDTH,
        KERNEL_ROM_SIZE => KERNEL_ROM_SIZE
    ) 
    Port map(
        clk => clk,
        reset => reset,
        
        img_number => img_per_octave,
        
        kernel_rom_a_en => rom_a_en,
        kernel_rom_a_addr => rom_a_addr,
        kernel_rom_b_en => rom_b_en,
        kernel_rom_b_addr => rom_b_addr,
    
        kernel_rom_a_data => rom_a_data,
        kernel_rom_b_data => rom_b_data,
        sigma_size => size
    );

-- For Vertical convolution, Read BRAM is Main BRAM, Write BRAM is Tmp BRAM.
-- Main BRAM is 32 bit with 30k locations, Tmp BRAM is 16 bit with 60k locations.
-- For this purpise R_PIXEL=2 (Read 2 Pixels - 32 bits), W_PIXEL=1 (Write 1 Pixel - 16 bits).
y_conv_gen: convolute_loops
    Generic map(
        DATA_WIDTH => DATA_WIDTH,
        HORIZONTAL => false,
        R_PIXEL => 2,
        W_PIXEL => 1,
        KERNEL_ROM_SIZE => KERNEL_ROM_SIZE,
        BRAM_SIZE => BRAM_SIZE  
    )
    Port map(
        clk => clk,
        reset => reset,
        start => start,

        -- Image parameters
        img_height => img_height,
        img_width => img_width,
        img_offset_up => img_offset_up,
        img_offset_down => img_offset_down,
        
        -- Output value from Kernel ROM. size = f(img_number)
        sigma_size => size,     
        
        -- BRAM 1 Port A is used by CPU (Main BRAM for Vertical convolution)
        bram1_a_en => open,
        bram1_a_we => open,
        bram1_a_addr => open,
        bram1_a_rdata => dummy,
        
        -- Enable signals and addresses for Main BRAM Port B, And Tmp BRAM both Port A and Port B
        -- Are calculated in the combinatorial logic on the end.
        bram1_b_en => main_bram_b_en,
        bram1_b_we => main_we_y,
        bram1_b_addr => read_y_b_addr,
        bram1_b_rdata => main_bram_b_rdata,
         
        kernel_rom_en => rom_a_en,
        kernel_rom_addr => rom_a_addr,
        kernel_rom_data => rom_a_data,

        bram2_a_en => tmp_bram_a_en,
        bram2_a_we => tmp_we_a_y,
        bram2_a_addr => write_y_a_addr,
        bram2_a_wdata => tmp_bram_a_wdata,
        
        bram2_b_en => tmp_bram_b_en,
        bram2_b_we => tmp_we_b_y,
        bram2_b_addr => write_y_b_addr,
        bram2_b_wdata => tmp_bram_b_wdata,
        
        ready => end_y_conv
    );

-- For Horizontal convolution, Read BRAM is Tmp BRAM, Write BRAM is Main BRAM.
-- Main BRAM is 32 bit with 30k locations, Tmp BRAM is 16 bit with 60k locations.
-- For this purpise R_PIXEL=1 (Read 1 Pixel - 16 bits), W_PIXEL=2 (Write 2 Pixels - 32 bits).
x_conv_gen: convolute_loops
    Generic map(
        DATA_WIDTH => DATA_WIDTH,
        HORIZONTAL => true,
        R_PIXEL => 1,
        W_PIXEL => 2,
        KERNEL_ROM_SIZE => KERNEL_ROM_SIZE,
        BRAM_SIZE => BRAM_SIZE  
    )
    Port map(
        clk => clk,
        reset => reset,
        start => start_x_conv,

        -- Image parameters
        img_height => img_height,
        img_width => img_width,
        img_offset_up => img_offset_up,
        img_offset_down => img_offset_down,
        
        -- Output value from Kernel ROM. size = f(img_number)
        sigma_size => size,     
        
        -- Enable signals and addresses for Main BRAM Port B, And Tmp BRAM both Port A and Port B
        -- Are calculated in the combinatorial logic on the end.
        bram1_a_en => tmp_bram_a_en,
        bram1_a_we => tmp_we_a_x,
        bram1_a_addr => read_x_a_addr,
        bram1_a_rdata => tmp_bram_a_rdata,
        
        bram1_b_en => tmp_bram_b_en,
        bram1_b_we => tmp_we_b_x,
        bram1_b_addr => read_x_b_addr,
        bram1_b_rdata => tmp_bram_b_rdata,
         
        kernel_rom_en => rom_b_en,
        kernel_rom_addr => rom_b_addr,
        kernel_rom_data => rom_b_data,
        
        -- BRAM 2 Port A is used by CPU (Main BRAM for Horizontal convolution)
        bram2_a_en => open,
        bram2_a_we => open,
        bram2_a_addr => open,
        bram2_a_wdata => open,
        
        bram2_b_en => main_bram_b_en,
        bram2_b_we => main_we_x,
        bram2_b_addr => write_x_b_addr,
        bram2_b_wdata => main_bram_b_wdata,
        
        ready => end_x_conv
    );

-- Main BRAM Port B and Tmp BRAM both Port A and Port B address and write enable signals are calculated here.
write_read_ctrl_hazard_solve: process(end_y_conv, end_x_conv, main_we_y, tmp_we_a_y, tmp_we_b_y, read_y_b_addr, write_y_b_addr, 
write_y_a_addr, main_we_x, tmp_we_a_x, tmp_we_b_x, write_x_b_addr, read_x_b_addr, read_x_a_addr)
begin
    -- If vertical convolution is not finished, and horizontal is finished all signals for 
    -- Main BRAM Port B and Tmp BRAM Port A and Port B should be used from vertical convolution.  
    if (end_y_conv = '0' and end_x_conv = '1') then
        main_bram_b_we <= main_we_y;
        tmp_bram_a_we <= tmp_we_a_y;
        tmp_bram_b_we <= tmp_we_b_y;
                          
        main_bram_b_addr <= read_y_b_addr;                   
        tmp_bram_b_addr <= write_y_b_addr;
        tmp_bram_a_addr <= write_y_a_addr;
    
    -- If horizontal convolution is not finished, and vertical is finished all signals for 
    -- Main BRAM Port B and Tmp BRAM Port A and Port B should be used from horizontal convolution. 
    elsif (end_y_conv = '1' and end_x_conv = '0') then
        main_bram_b_we <= main_we_x;
        tmp_bram_a_we <= tmp_we_a_x;
        tmp_bram_b_we <= tmp_we_b_x;
                          
        main_bram_b_addr <= write_x_b_addr;                   
        tmp_bram_b_addr <= read_x_b_addr;
        tmp_bram_a_addr <= read_x_a_addr;
    else
        main_bram_b_we <= (others => '0');
        tmp_bram_a_we <= (others => '0');
        tmp_bram_b_we <= (others => '0');
                          
        main_bram_b_addr <= (others => '0');                   
        tmp_bram_b_addr <= (others => '0');
        tmp_bram_a_addr <= (others => '0');    
    end if;              

end process;                        
              
-- To start horizontal (2nd) convolution, start signal from CPU is not used but instead output of edge detector 
-- used on end_y_conv (ready of vertical convolution) determines start of horizontal convolution
start_x_proc: process(clk)
begin    
    if rising_edge(clk) then
        edge_reg_o <= not(end_y_conv);   
    end if;
end process;


start_x_conv <= edge_reg_o and end_y_conv;

-- Ready state of the system is high when both convolutions are finished and
-- no edge detected on vertical convolution ready signal (not in between convolutions).
ready <= end_y_conv and end_x_conv and not(edge_reg_o);                                                                                    
                                
end Mixed;
