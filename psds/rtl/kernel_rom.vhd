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
    KERNEL_ROM_SIZE : natural := 76 --FIXED     
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
    
    kernel_rom_addr_off_prev: in std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    kernel_rom_addr_off_next: out std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    
    sigma_size: out std_logic_vector(DATA_WIDTH/2 -1 downto 0) 
    
);
end kernel_rom;

architecture Mixed of kernel_rom is
    constant LUT_DEPTH : natural := 3;
    constant LUT_WIDTH : natural := 32; 
    
    type sigma_lut is array (0 to 5) of std_logic_vector(LUT_WIDTH -1 downto 0);
    
    signal SIGMA_VALS : sigma_lut := (
       "00000011101111110011101101010110", "00000011101011011100011100110000", "00000100101000101001000011100110", "00000101110101110001001011001000", "00000111010110111000111001100110", 	   	 	"00001001010001010010000111011000"
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

signal size_s, size_shift, size_odd: std_logic_vector(DATA_WIDTH/2 -1 downto 0);
--signal add1_in1, add1_in2 : std_logic_vector(2 *DATA_WIDTH -1 downto 0);
signal add1_out: std_logic_vector(2*DATA_WIDTH -1 downto 0);
signal addr_a_out, addr_b_out, kernel_rom_addr_off_next_s, kernel_rom_addr_off_prev_s: std_logic_vector(DATA_WIDTH/2 -1 downto 0);
type rom_type is array (0 to KERNEL_ROM_SIZE-1) of std_logic_vector(DATA_WIDTH -1 downto 0);
signal ROM: rom_type := (   "0000000000011110", "0000000100100100", "0000010110101100", "0000111011010111", "0001010001110010", "0000111011010111", "0000010110101100", "0000000100100100", "0000000000011110", 
                            "0000000000011010", "0000000100001011", "0000010110000001", "0000111011101111", "0001010011010011", "0000111011101111", "0000010110000001", "0000000100001011", "0000000000011010", 
                            "0000000000010110", "0000000010010100", "0000001010000010", "0000011100100110", "0000110101101000", "0001000010000111", "0000110101101000", "0000011100100110", "0000001010000010", "0000000010010100", "0000000000010110", 
                            "0000000000011100", "0000000001111011", "0000000110010110", "0000010000000000", "0000011110111110", "0000101110000001", "0000110100100000", "0000101110000001", "0000011110111110", "0000010000000000", "0000000110010110", "0000000001111011", "0000000000011100", 
                            "0000000000101101", "0000000010000101", "0000000101001110", "0000001011000010", "0000010011101111", "0000011101111011", "0000100110011001", "0000101001101110", "0000100110011001", "0000011101111011", "0000010011101111", "0000001011000010", "0000000101001110", "0000000010000101", "0000000000101101", 
                            "0000000000011110", "0000000001001010", "0000000010100010", "0000000101000001", "0000001000111100", "0000001110010101", "0000010100101010", "0000011010110111", "0000011111011011", "0000100001000111", "0000011111011011", "0000011010110111", "0000010100101010", "0000001110010101", "0000001000111100", "0000000101000001", "0000000010100010", "0000000001001010", "0000000000011110"
                            );
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
--size_shift <= shift_right(SIGMA_VALS(TO_INTEGER(unsigned(img_number))), 23)(DATA_WIDTH/2 -1 downto 0);

add1_out <= std_logic_vector(shift_right(unsigned(SIGMA_VALS(TO_INTEGER(unsigned(img_number)))), 23));
           
size_odd <= add1_out(DATA_WIDTH/2 -1 downto 0) when add1_out(0) = '1' else
          std_logic_vector(unsigned(add1_out(DATA_WIDTH/2 -1 downto 0)) + 1); 
                       
addr1_gen: dsp_unit_add 
    generic map(
          WIDTH1 => DATA_WIDTH/2 ,
          WIDTH2 => log2c(KERNEL_ROM_SIZE) 
         )
    port map(
          clk => clk,
          rst => reset,
          in_1 => kernel_rom_addr_off_prev,
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
          in_1 => kernel_rom_addr_off_prev,
          in_2 => kernel_rom_b_addr,
          out_res => addr_b_out
           );
           
next_off_gen: dsp_unit_add 
    generic map(
          WIDTH1 => DATA_WIDTH/2 ,
          WIDTH2 => DATA_WIDTH/2 
         )
    port map(
          clk => clk,
          rst => reset,
          in_1 => kernel_rom_addr_off_prev,
          in_2 => size_s,
          out_res => kernel_rom_addr_off_next_s
           );
             
size_s <= size_odd when TO_INTEGER(unsigned(img_number)) = 4 or TO_INTEGER(unsigned(img_number)) = 5
              else std_logic_vector(unsigned(size_odd) + 2);
sigma_size <= size_s;
kernel_rom_addr_off_next <= (others => '0') when TO_INTEGER(unsigned(img_number)) = 0
                            else size_s when TO_INTEGER(unsigned(img_number)) = 1
                            else kernel_rom_addr_off_next_s;
                                                       
end Mixed;