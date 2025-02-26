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
    
    --BRAMS  
    main_bram_a_en: in std_logic; 
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
    
    
    ready: out std_logic
    
);
end gaussian_blur;

architecture Mixed of gaussian_blur is

component convolute_loops is
Generic(
    --WIDTH OF DATA
    DATA_WIDTH : natural := 16; -- FIXED
    
    --PARAMETRS OF CONVOLUTION
    R_PIXEL: natural := 1;
    W_PIXEL: natural := 2;  
    
    --SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE : natural := 77; --FIXED 
    BRAM_SIZE : natural := 60000 --FIXED

);
Port ( 
    clk : in std_logic;
    reset: in std_logic;
    start: in std_logic;
    
    --IMAGE ELEMENTS
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
    DATA_WIDTH : natural := 16; -- FIXED
    KERNEL_ROM_SIZE : natural := 77 --FIXED     
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

signal rom_a_en,rom_b_en, start_x_conv, end_x_conv, end_y_conv, edge_reg_o: std_logic;
signal rom_a_addr, rom_b_addr: std_logic_vector(log2c(KERNEL_ROM_SIZE) -1 downto 0);
signal rom_a_data, rom_b_data: std_logic_vector(DATA_WIDTH -1 downto 0);
signal size: std_logic_vector(DATA_WIDTH/2 -1 downto 0);
signal main_we_x, tmp_we_a_y, tmp_we_b_y, tmp_we_a_x, tmp_we_b_x, main_we_y: std_logic_vector(3 downto 0);
signal write_x_b_addr, read_y_b_addr: std_logic_vector(log2c(BRAM_SIZE/2) - 1 downto 0);
signal write_y_a_addr, write_y_b_addr, read_x_a_addr, read_x_b_addr: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);

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
    
y_conv_gen: convolute_loops
    Generic map(
        DATA_WIDTH => DATA_WIDTH,
        R_PIXEL => 2,
        W_PIXEL => 1,
        KERNEL_ROM_SIZE => KERNEL_ROM_SIZE,
        BRAM_SIZE => BRAM_SIZE  
    )
    Port map(
        clk => clk,
        reset => reset,
        start => start,

        img_height => img_height,
        img_width => img_width,
        img_offset_up => img_offset_up,
        img_offset_down => img_offset_down,
        
        sigma_size => size,     
        
        bram1_a_en => open,
        bram1_a_we => open,
        bram1_a_addr => open,
        bram1_a_rdata => (others => '0'),
        
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

x_conv_gen: convolute_loops
    Generic map(
        DATA_WIDTH => DATA_WIDTH,
        R_PIXEL => 1,
        W_PIXEL => 2,
        KERNEL_ROM_SIZE => KERNEL_ROM_SIZE,
        BRAM_SIZE => BRAM_SIZE  
    )
    Port map(
        clk => clk,
        reset => reset,
        start => start_x_conv,

        img_height => img_height,
        img_width => img_width,
        img_offset_up => img_offset_up,
        img_offset_down => img_offset_down,
        
        sigma_size => size,     
        
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
    
write_read_ctrl: process(end_y_conv, main_we_y, tmp_we_a_y, tmp_we_b_y, read_y_b_addr, write_y_b_addr, 
write_y_a_addr, main_we_x, tmp_we_a_x, tmp_we_b_x, write_x_b_addr, read_x_b_addr, read_x_a_addr)
begin    
    if (end_y_conv = '0') then
        main_bram_b_we <= main_we_y;
        tmp_bram_a_we <= tmp_we_a_y;
        tmp_bram_b_we <= tmp_we_b_y;
                          
        main_bram_b_addr <= read_y_b_addr;                   
        tmp_bram_b_addr <= write_y_b_addr;
        tmp_bram_a_addr <= write_y_a_addr;
    else
        main_bram_b_we <= main_we_x;
        tmp_bram_a_we <= tmp_we_a_x;
        tmp_bram_b_we <= tmp_we_b_x;
                          
        main_bram_b_addr <= write_x_b_addr;                   
        tmp_bram_b_addr <= read_x_b_addr;
        tmp_bram_a_addr <= read_x_a_addr;
    end if;              

end process;                        
                        
start_x_proc: process(clk)
begin    
    if rising_edge(clk) then
        edge_reg_o <= not(end_y_conv);   
    end if;
    start_x_conv <= edge_reg_o and end_y_conv;
end process;

ready <= end_y_conv and end_x_conv and not(edge_reg_o);                                                                                    
                                
end Mixed;
