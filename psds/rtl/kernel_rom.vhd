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
    attribute use_dsp : string;
    attribute use_dsp of Mixed : architecture is "yes";

    constant LUT_DEPTH : natural := 3;
    constant LUT_WIDTH : natural := 32; 
    
    type sigma_lut is array (0 to 5) of unsigned(LUT_WIDTH -1 downto 0);
    
    constant SIGMA_VALS : sigma_lut := (
        X"03BF3B56", X"03ADC730", X"04A290E6", X"05D712C8", X"075B8E66", X"094521D8"
    );
     
component dsp_unit_mul_shift_23 is

    generic (WIDTH1: natural := 32;
             WIDTH2: natural := 32;
             OUT_WIDTH: natural :=32);
    port (clk: in std_logic;
          rst: in std_logic;
          in_1: in std_logic_vector(WIDTH1 - 1 downto 0);
          in_2: in std_logic_vector(WIDTH2 - 1 downto 0);
          out_res: out std_logic_vector(OUT_WIDTH - 1 downto 0)
          );

end component;

component dsp_unit_add is
    generic (WIDTH1: natural := 16;
             WIDTH2: natural := 16
             );
    port (clk: in std_logic;
          rst: in std_logic;
          in_1: in std_logic_vector(WIDTH1 - 1 downto 0);
          in_2: in std_logic_vector(WIDTH2 - 1 downto 0);
          out_res: out std_logic_vector(WIDTH1 - 1 downto 0));
end component;

signal size_s, size_shift: unsigned(DATA_WIDTH/2 -1 downto 0);
signal add1_in1, add1_in2 : unsigned(2 *DATA_WIDTH -1 downto 0);
signal add1_out: unsigned(2*DATA_WIDTH -1 downto 0);
signal addr_a_out, addr_b_out, kernel_rom_addr_off_next_s: std_logic_vector(DATA_WIDTH/2 -1 downto 0);
type rom_type is array (0 to KERNEL_ROM_SIZE-1) of unsigned(DATA_WIDTH -1 downto 0);
signal ROM: rom_type := (
                            X"001E", X"0124", X"05AC", X"0ED7", X"1472", X"0ED7", X"05AC", X"0124", X"001E", 
                            X"001A", X"010B", X"0581", X"0EEF", X"14D3", X"0EEF", X"0581", X"010B", X"001A", 
                            X"0016", X"0094", X"0282", X"0726", X"0D68", X"1087", X"0D68", X"0726", X"0282", X"0094", X"0016", 
                            X"001C", X"007B", X"0196", X"0400", X"07BE", X"0B81", X"0D20", X"0B81", X"07BE", X"0400", X"0196", X"007B", X"001C", 
                            X"002D", X"0085", X"014E", X"02C2", X"04EF", X"077B", X"0999", X"0A6E", X"0999", X"077B", X"04EF", X"02C2", X"014E", X"0085", X"002D", 
                            X"001E", X"004A", X"00A2", X"0141", X"023C", X"0395", X"052A", X"06B7", X"07DB", X"0847", X"07DB", X"06B7", X"052A", X"0395", X"023C", X"0141", X"00A2", X"004A", X"001E"    
                         );
begin


clk_proc: process(clk, reset)
begin
    if (reset = '1') then
        kernel_rom_a_data <= (others => '0');
        kernel_rom_b_data <= (others => '0');
    
    elsif (rising_edge(clk)) then
         if ( kernel_rom_a_en= '1') then
                kernel_rom_a_data <= std_logic_vector(ROM(to_integer(unsigned(addr_a_out))));
        end if;
        if ( kernel_rom_b_en= '1') then
                kernel_rom_b_data <= std_logic_vector(ROM(to_integer(unsigned(addr_b_out))));
        end if;
    
    end if;

end process;
--size_shift <= shift_right(SIGMA_VALS(TO_INTEGER(unsigned(img_number))), 23)(DATA_WIDTH/2 -1 downto 0);

add1_out <= shift_right(SIGMA_VALS(TO_INTEGER(unsigned(img_number))), 23);
           
size_s <= add1_out(DATA_WIDTH/2 -1 downto 0) when add1_out(0) = '1' else
          add1_out(DATA_WIDTH/2 -1 downto 0) + 1; 
                       
addr1_gen: dsp_unit_add 
    generic map(
          WIDTH1 => DATA_WIDTH/2 ,
          WIDTH2 => log2c(KERNEL_ROM_SIZE) 
         )
    port map(
          clk => clk,
          rst => reset,
          in_1 => kernel_rom_addr_off_prev,
          in_2 => std_logic_vector(kernel_rom_a_addr),
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
          in_2 => std_logic_vector(kernel_rom_b_addr),
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
          in_2 => std_logic_vector(size_s),
          out_res => kernel_rom_addr_off_next_s
           );

sigma_proc: process(size_s, img_number, kernel_rom_addr_off_next_s)
begin              
sigma_size <= std_logic_vector(size_s) when TO_INTEGER(unsigned(img_number)) = 4 or TO_INTEGER(unsigned(img_number)) = 5
              else std_logic_vector(size_s + 2);
kernel_rom_addr_off_next <= (others => '0') when TO_INTEGER(unsigned(img_number)) = 5
                            else std_logic_vector(size_s) when TO_INTEGER(unsigned(img_number)) = 0
                            else kernel_rom_addr_off_next_s;
end process;
                            
--ready <= '0' when kernel_rom_addr_off_prev = kernel_rom_addr_off_next_s
            --else '1';                             
end Mixed;
