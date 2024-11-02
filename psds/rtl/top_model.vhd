----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/17/2024 10:01:03 AM
-- Design Name: 
-- Module Name: top_model - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_model is
Generic(
    --DATA WIDTH
    DATA_WIDTH : natural := 16;
    
    --SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE : natural := 76; --FIXED 
    BRAM_SIZE : natural := 30000 --FIXED
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
    main_bram_a_cpu_addr: in std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    main_bram_a_cpu_rdata: out std_logic_vector(2 *(DATA_WIDTH-1) -1 downto 0);
    main_bram_a_cpu_wdata: in std_logic_vector(2 *(DATA_WIDTH-1) -1 downto 0); 
    
    ready: out std_logic
);
end top_model;

architecture Structural of top_model is
component gaussian_blur
Generic(
    --DATA WIDTH
    DATA_WIDTH : natural := 16;
    
    --SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE : natural := 76; --FIXED 
    BRAM_SIZE : natural := 30000 --FIXED
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
    main_bram_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    main_bram_b_rdata: in std_logic_vector(2 *(DATA_WIDTH-1) -1 downto 0);
    main_bram_b_wdata: out std_logic_vector(2 *(DATA_WIDTH-1) -1 downto 0); 

    tmp_bram_b_en: out std_logic;
    tmp_bram_b_we: out std_logic_vector(3 downto 0);
    tmp_bram_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    tmp_bram_b_rdata: in std_logic_vector(2 *(DATA_WIDTH-1) -1 downto 0);
    tmp_bram_b_wdata: out std_logic_vector(2 *(DATA_WIDTH-1) -1 downto 0);
    
    
    ready: out std_logic
    
);
end component;

component bram 
    generic (WIDTH: positive := 15;
             SIZE: positive := 30000);
    port (clk_a : in std_logic;
          clk_b : in std_logic;
          en_a: in std_logic;
          en_b: in std_logic;
          we_a: in std_logic_vector(3 downto 0);
          we_b: in std_logic_vector(3 downto 0);
          addr_a: in std_logic_vector(log2c(SIZE) -1 downto 0);
          addr_b: in std_logic_vector(log2c(SIZE) -1 downto 0);
          data_a_i: in std_logic_vector(2 *WIDTH-1 downto 0);
          data_b_i: in std_logic_vector(2 *WIDTH-1 downto 0);
          data_a_o: out std_logic_vector(2 *WIDTH-1 downto 0);
          data_b_o: out std_logic_vector(2 *WIDTH-1 downto 0));
end component;

signal main_bram_a_en_blur_s, main_bram_b_en_blur_s, tmp_bram_a_en_blur_s, tmp_bram_b_en_blur_s: std_logic;
signal main_bram_a_we_blur_s, main_bram_b_we_blur_s, tmp_bram_a_we_blur_s, tmp_bram_b_we_blur_s: std_logic_vector(3 downto 0);
signal main_bram_a_addr_blur_s, main_bram_b_addr_blur_s, tmp_bram_a_addr_blur_s, tmp_bram_b_addr_blur_s: std_logic_vector(log2c(BRAM_SIZE) -1 downto 0);
signal main_bram_a_rdata_blur_s, main_bram_b_rdata_blur_s, tmp_bram_a_rdata_blur_s, tmp_bram_b_rdata_blur_s: std_logic_vector(2*(DATA_WIDTH-1) -1 downto 0);
signal main_bram_a_wdata_blur_s, main_bram_b_wdata_blur_s, tmp_bram_a_wdata_blur_s, tmp_bram_b_wdata_blur_s: std_logic_vector(2*(DATA_WIDTH-1) -1 downto 0);

begin 

gauss_blur: gaussian_blur
Generic map(
    --DATA WIDTH
    DATA_WIDTH => DATA_WIDTH,
    
    --SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE => KERNEL_ROM_SIZE,
    BRAM_SIZE => BRAM_SIZE)
    
Port map( 
    clk => clk,
    reset => reset,
    start => start,
    
    --IMAGE ELEMENTS
    img_height => img_height,
    img_width => img_width,
    img_offset_up => img_offset_up,
    img_offset_down => img_offset_down,
    img_per_octave => img_per_octave,
    
    --BRAMS
    main_bram_a_en => main_bram_a_cpu_en,
    main_bram_b_en => main_bram_b_en_blur_s,
    main_bram_b_we => main_bram_b_we_blur_s,
    main_bram_b_addr => main_bram_b_addr_blur_s,
    main_bram_b_rdata => main_bram_b_rdata_blur_s,
    main_bram_b_wdata => main_bram_b_wdata_blur_s,
    
    tmp_bram_b_en => tmp_bram_b_en_blur_s, 
    tmp_bram_b_we => tmp_bram_b_we_blur_s,
    tmp_bram_b_addr => tmp_bram_b_addr_blur_s,
    tmp_bram_b_rdata => tmp_bram_b_rdata_blur_s,
    tmp_bram_b_wdata => tmp_bram_b_wdata_blur_s,
       
    ready => ready
    
);

main_bram: bram
Generic map(
    WIDTH => DATA_WIDTH -1,
    SIZE => BRAM_SIZE
    )
Port map(
    clk_a => clk,
    clk_b => clk,
    en_a => main_bram_a_cpu_en ,
    en_b => main_bram_b_en_blur_s,
    we_a => main_bram_a_cpu_we,
    we_b => main_bram_b_we_blur_s,
    addr_a => main_bram_a_cpu_addr,
    addr_b => main_bram_b_addr_blur_s,
    data_a_i => main_bram_a_cpu_wdata,
    data_b_i => main_bram_b_wdata_blur_s,
    data_a_o => main_bram_a_cpu_rdata,
    data_b_o => main_bram_b_rdata_blur_s 
    );
    
tmp_bram: bram
Generic map(
    WIDTH => DATA_WIDTH-1,
    SIZE => BRAM_SIZE
    )
Port map(
    clk_a => clk,
    clk_b => clk,
    en_a => tmp_bram_a_en_blur_s,
    en_b => tmp_bram_b_en_blur_s,
    we_a => tmp_bram_a_we_blur_s,
    we_b => tmp_bram_b_we_blur_s,
    addr_a => tmp_bram_a_addr_blur_s,
    addr_b => tmp_bram_b_addr_blur_s,
    data_a_i => tmp_bram_a_wdata_blur_s,
    data_b_i => tmp_bram_b_wdata_blur_s,
    data_a_o => open,
    data_b_o => tmp_bram_b_rdata_blur_s 
    );
    
    tmp_bram_a_en_blur_s <= '0';   
    tmp_bram_a_we_blur_s <= (others => '0');
    tmp_bram_a_addr_blur_s <= (others => '0');     
    tmp_bram_a_wdata_blur_s <= (others => '0');
end Structural;


