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
    KERNEL_ROM_SIZE : natural := 76; --FIXED 
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
    main_bram_a_en: out std_logic;
    main_bram_a_we: out std_logic_vector(3 downto 0);
    main_bram_a_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    main_bram_a_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    main_bram_a_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    main_bram_b_en: out std_logic;
    main_bram_b_we: out std_logic_vector(3 downto 0);
    main_bram_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    main_bram_b_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    main_bram_b_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    tmp_bram_a_en: out std_logic;
    tmp_bram_a_we: out std_logic_vector(3 downto 0);
    tmp_bram_a_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    tmp_bram_a_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    tmp_bram_a_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    tmp_bram_b_en: out std_logic;
    tmp_bram_b_we: out std_logic_vector(3 downto 0);
    tmp_bram_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    tmp_bram_b_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    tmp_bram_b_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    
    ready: out std_logic
    
);
end gaussian_blur;

architecture Mixed of gaussian_blur is
component convolute_loops is
Generic(
    --WIDTH OF DATA
    DATA_WIDTH : natural := 16; -- FIXED
    
    --DIRECTION OF CONVOLUTION
    HORIZONTAL: boolean := true;
    
    --SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE : natural := 76; --FIXED 
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
    img_per_octave: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    sigma_size : in std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    
    bram1_a_en: out std_logic;
    bram1_a_we: out std_logic_vector(3 downto 0);
    bram1_a_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram1_a_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    bram1_a_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    bram1_b_en: out std_logic;
    bram1_b_we: out std_logic_vector(3 downto 0);
    bram1_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram1_b_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    bram1_b_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    kernel_rom_en: out std_logic;
    kernel_rom_addr: out std_logic_vector(log2c(KERNEL_ROM_SIZE) - 1 downto 0);
    kernel_rom_data: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    
    bram2_a_en: out std_logic;
    bram2_a_we: out std_logic_vector(3 downto 0);
    bram2_a_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram2_a_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    bram2_a_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    bram2_b_en: out std_logic;
    bram2_b_we: out std_logic_vector(3 downto 0);
    bram2_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram2_b_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    bram2_b_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    ready : out std_logic
      
);    
end component;

component kernel_rom is
Generic (
    DATA_WIDTH : natural := 16; -- FIXED
    KERNEL_ROM_SIZE : natural := 76 --FIXED     
);
Port ( 
    clk: in std_logic;
    reset: in std_logic;
    start: in std_logic;
    
    img_number: in std_logic_vector(DATA_WIDTH- 1 downto 0);
      
    kernel_rom_a_en: in std_logic;
    kernel_rom_a_addr: in std_logic_vector(log2c(KERNEL_ROM_SIZE) -1 downto 0);
    kernel_rom_b_en: in std_logic;
    kernel_rom_b_addr: in std_logic_vector(log2c(KERNEL_ROM_SIZE) -1 downto 0);
    
    kernel_rom_a_data: out std_logic_vector(DATA_WIDTH -1 downto 0); 
    kernel_rom_b_data: out std_logic_vector(DATA_WIDTH -1 downto 0); 
    
    kernel_rom_addr_off_prev: in std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    kernel_rom_addr_off_next: out std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    
    sigma_size: out std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    
    ready: out std_logic
);
end component;

signal rom_en, start_x_conv, start_y_conv: std_logic;
signal rom_addr: std_logic_vector(log2c(KERNEL_ROM_SIZE) -1 downto 0);
signal rom_data: std_logic_vector(DATA_WIDTH -1 downto 0);
signal rom_addr_off_prev, rom_addr_off, size: std_logic_vector(DATA_WIDTH/2 -1 downto 0);
signal write1_a_addr, read1_a_addr, write1_b_addr, read1_b_addr: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
signal write2_a_addr, read2_a_addr, write2_b_addr, read2_b_addr: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);

begin

kernel_rom_gen: kernel_rom 
    Generic map(
        DATA_WIDTH => DATA_WIDTH,
        KERNEL_ROM_SIZE => KERNEL_ROM_SIZE
    ) 
    Port map(
        clk => clk,
        reset => reset,
        start => start,
        
        img_number => img_per_octave,
        
        kernel_rom_a_en => rom_en,
        kernel_rom_a_addr => rom_addr,
        kernel_rom_b_en => '0',
        kernel_rom_b_addr => (others => '0'),
    
        kernel_rom_a_data => rom_data,
        kernel_rom_b_data => open,
    
        kernel_rom_addr_off_prev => rom_addr_off_prev,
        kernel_rom_addr_off_next => rom_addr_off,
        sigma_size => size,
    
        ready  => start_y_conv
    );
    
y_conv_gen: convolute_loops
    Generic map(
        DATA_WIDTH => DATA_WIDTH,
        HORIZONTAL => false,
        KERNEL_ROM_SIZE => KERNEL_ROM_SIZE,
        BRAM_SIZE => BRAM_SIZE  
    )
    Port map(
        clk => clk,
        reset => reset,
        start => start_y_conv,

        img_height => img_height,
        img_width => img_width,
        img_offset_up => img_offset_up,
        img_offset_down => img_offset_down,
        img_per_octave => img_per_octave,
        
        sigma_size => size,
        
        --bram1_a_en => main_bram_a_en,
        bram1_a_we => open,
        bram1_a_addr => read1_a_addr,
        bram1_a_rdata => main_bram_a_rdata,
        bram1_a_wdata => open,
        
        --bram1_b_en => main_bram_b_en,
        bram1_b_we => open,
        bram1_b_addr => read1_b_addr,
        bram1_b_rdata => main_bram_b_rdata,
        bram1_b_wdata => open,
         
        kernel_rom_en => rom_en,
        kernel_rom_addr => rom_addr,
        kernel_rom_data => rom_data,
        
        
        --bram2_a_en => tmp_bram_a_en,
        --bram2_a_we => tmp_bram_a_we,
        bram2_a_addr => write2_a_addr,
        bram2_a_rdata => (others => '0'),
        bram2_a_wdata => tmp_bram_a_wdata,
        
        --bram2_b_en => tmp_bram_b_en,
        --bram2_b_we => tmp_bram_b_we,
        bram2_b_addr => write2_b_addr,
        bram2_b_rdata => (others => '0'),
        bram2_b_wdata => tmp_bram_b_wdata,
        
        ready => start_x_conv
    );

x_conv_gen: convolute_loops
    Generic map(
        DATA_WIDTH => DATA_WIDTH,
        HORIZONTAL => true,
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
        img_per_octave => img_per_octave,
        
        sigma_size => size,
        
        --bram1_a_en => tmp_bram_a_en,
        bram1_a_we => open,
        bram1_a_addr => read2_a_addr,
        bram1_a_rdata => tmp_bram_a_rdata,
        bram1_a_wdata => open,
        
        --bram1_b_en => tmp_bram_b_en,
        bram1_b_we => open,
        bram1_b_addr => read2_b_addr,
        bram1_b_rdata => tmp_bram_b_rdata,
        bram1_b_wdata => open,
        
        kernel_rom_en => rom_en,
        kernel_rom_addr => rom_addr,
        kernel_rom_data => rom_data,
        
        
        --bram2_a_en => main_bram_a_en,
        --bram2_a_we => main_bram_a_we,
        bram2_a_addr => write1_a_addr,
        bram2_a_rdata => (others => '0'),
        bram2_a_wdata => main_bram_a_wdata,
        
        --bram2_b_en => main_bram_b_en,
        --bram2_b_we => main_bram_b_we,
        bram2_b_addr => write1_b_addr,
        bram2_b_rdata => (others => '0'),
        bram2_b_wdata => main_bram_b_wdata,
        
        ready => ready
    );
    
    
    main_bram_a_addr <= read1_a_addr when start_y_conv = '1' and start_x_conv = '0'
                        else write1_a_addr when start_x_conv = '1' and start_y_conv = '1'
                        else (others => '1');
    main_bram_b_addr <= read1_b_addr when start_y_conv = '1' and start_x_conv = '0'
                        else write1_b_addr when start_x_conv = '1' and start_y_conv = '1'
                        else (others => '1');                    
    tmp_bram_a_addr <= read2_a_addr when start_x_conv = '1' and start_y_conv = '1'
                        else write2_a_addr when start_y_conv = '1' and start_x_conv = '0'
                        else (others => '1');
    tmp_bram_b_addr <= read2_b_addr when start_x_conv = '1' and start_y_conv = '1'
                        else write2_b_addr when start_y_conv = '1' and start_x_conv = '0'
                        else (others => '1');    
rom_offset: process(rom_addr_off)
begin
     rom_addr_off_prev <= rom_addr_off;   
end process;  
             
    main_bram_a_en <= '1';
    main_bram_b_en <= '1';
    tmp_bram_a_en <= '1';
    tmp_bram_b_en <= '1';   
    
    main_bram_a_we <= "1111";
    main_bram_b_we <= "1111";
    tmp_bram_a_we <= "1111";
    tmp_bram_b_we <= "1111";
                   
end Mixed;
