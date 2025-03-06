----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/03/2024 08:22:12 PM
-- Design Name: 
-- Module Name: kernel_init - Behavioral
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


entity kernel_rom is
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
end kernel_rom;

architecture Mixed of kernel_rom is
    constant LUT_DEPTH : natural := 3;
    constant LUT_WIDTH : natural := 8; 
    
    type sigma_lut is array (0 to 5) of std_logic_vector(LUT_WIDTH -1 downto 0);
    
    signal SIGMA_VALS : sigma_lut := (
       "00001001", "00001001", "00001011", "00001101", "00001111", "00010011"
    );	
component dsp_unit_add
    generic (WIDTH1: natural := 16;
             WIDTH2: natural := 16
             );
    port (clk: in std_logic;
          rst: in std_logic;
          in_1: in std_logic_vector(WIDTH1 - 1 downto 0);
          in_2: in std_logic_vector(WIDTH2 - 1 downto 0);
          out_res: out std_logic_vector(WIDTH1 - 1 downto 0));
end component;

signal addr_a_out, addr_b_out: std_logic_vector(DATA_WIDTH/2 -1 downto 0);
type rom_type is array (0 to KERNEL_ROM_SIZE-1) of std_logic_vector(DATA_WIDTH -1 downto 0);
signal ROM: rom_type := (   "0000000000011110", "0000000100100100", "0000010110101100", "0000111011010111", "0001010001110010", "0000111011010111", "0000010110101100", "0000000100100100", "0000000000011110", 
                            "0000000000011010", "0000000100001011", "0000010110000001", "0000111011101111", "0001010011010011", "0000111011101111", "0000010110000001", "0000000100001011", "0000000000011010", 
                            "0000000000010110", "0000000010010100", "0000001010000010", "0000011100100110", "0000110101101000", "0001000010000111", "0000110101101000", "0000011100100110", "0000001010000010", "0000000010010100", "0000000000010110", 
                            "0000000000011100", "0000000001111011", "0000000110010110", "0000010000000000", "0000011110111110", "0000101110000001", "0000110100100000", "0000101110000001", "0000011110111110", "0000010000000000", "0000000110010110", "0000000001111011", "0000000000011100", 
                            "0000000000101101", "0000000010000101", "0000000101001110", "0000001011000010", "0000010011101111", "0000011101111011", "0000100110011001", "0000101001101110", "0000100110011001", "0000011101111011", "0000010011101111", "0000001011000010", "0000000101001110", "0000000010000101", "0000000000101101", 
                            "0000000000011110", "0000000001001010", "0000000010100010", "0000000101000001", "0000001000111100", "0000001110010101", "0000010100101010", "0000011010110111", "0000011111011011", "0000100001000111", "0000011111011011", "0000011010110111", "0000010100101010", "0000001110010101", "0000001000111100", "0000000101000001", "0000000010100010", "0000000001001010", "0000000000011110", "0000000000000000" , "0000000000000000"
                            );
signal ROM_ADDR_OFF: sigma_lut := ( "00000000", "00001001", "00010010", "00011101", "00101010", "00111001") ;                           
begin


clk_proc: process(clk, reset)
begin
    if (reset = '1') then
        kernel_rom_a_data <= (others => '0');
        kernel_rom_b_data <= (others => '0');

    elsif (rising_edge(clk)) then
         if ( kernel_rom_a_en= '1') then
                kernel_rom_a_data <= ROM(to_integer(unsigned(addr_a_out)));
        end if;
        if ( kernel_rom_b_en= '1') then
                kernel_rom_b_data <= ROM(to_integer(unsigned(addr_b_out)));
        end if;
    
    end if;

end process;
                       
addr1_gen: dsp_unit_add 
    generic map(
          WIDTH1 => DATA_WIDTH/2 ,
          WIDTH2 => log2c(KERNEL_ROM_SIZE) 
         )
    port map(
          clk => clk,
          rst => reset,
          in_1 => ROM_ADDR_OFF(TO_INTEGER(unsigned(img_number))),
          in_2 => kernel_rom_a_addr,
          out_res => addr_a_out
           );
           
addr2_gen: dsp_unit_add 
    generic map(
          WIDTH1 => DATA_WIDTH/2 ,
          WIDTH2 => log2c(KERNEL_ROM_SIZE) 
         )
    port map(
          clk => clk,
          rst => reset,
          in_1 => ROM_ADDR_OFF(TO_INTEGER(unsigned(img_number))),
          in_2 => kernel_rom_b_addr,
          out_res => addr_b_out
           );
             
sigma_size <= SIGMA_VALS(TO_INTEGER(unsigned(img_number)));
                                                       
end Mixed;
