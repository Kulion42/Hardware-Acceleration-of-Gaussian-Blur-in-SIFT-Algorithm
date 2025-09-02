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
    
    -- Img per scale parameter
    img_number: in std_logic_vector(DATA_WIDTH- 1 downto 0);
    
    -- Read address and enable signals
    kernel_rom_a_en: in std_logic;
    kernel_rom_a_addr: in std_logic_vector(log2c(KERNEL_ROM_SIZE) -1 downto 0);
    kernel_rom_b_en: in std_logic;
    kernel_rom_b_addr: in std_logic_vector(log2c(KERNEL_ROM_SIZE) -1 downto 0);
    
    -- Output read values
    kernel_rom_a_data: out std_logic_vector(DATA_WIDTH -1 downto 0); 
    kernel_rom_b_data: out std_logic_vector(DATA_WIDTH -1 downto 0);    
    
    -- sigma_size -> f(img_number)
    sigma_size: out std_logic_vector(DATA_WIDTH/2 -1 downto 0) 
    
);
end kernel_rom;

architecture Mixed of kernel_rom is
    attribute use_dsp : string;
    attribute use_dsp of Mixed : architecture is "yes";

    -- Out of date.
    constant LUT_DEPTH : natural := 3;
    -- Width of word used to describe number of values and offsets
    constant LUT_WIDTH : natural := 8; 
    
    -- Data type used to represent number of values and offsets
    type sigma_lut is array (0 to 5) of std_logic_vector(LUT_WIDTH -1 downto 0);
    
    -- Number of values in each row
    signal SIGMA_VALS : sigma_lut := (
       "00001001", "00001001", "00001011", "00001101", "00001111", "00010011"
    );	

-- Out of date. Not used anymore. It was used for addr. gen.
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

-- Address signals
signal addr_a_out, addr_b_out: std_logic_vector(DATA_WIDTH/2 -1 downto 0);

-- ROM memory
type rom_type is array (0 to KERNEL_ROM_SIZE-1) of std_logic_vector(DATA_WIDTH -1 downto 0);
signal ROM: rom_type := (
    -- First row: 9 elements
    "0000000000111101", "0000001001001000", "0000101101011000", "0001110110101101", "0010100011100100", "0001110110101101", "0000101101011000", "0000001001001000", "0000000000111101",
    -- Second row: 9 elements
    "0000000000110100", "0000001000010110", "0000101100000011", "0001110111011101", "0010100110100101", "0001110111011101", "0000101100000011", "0000001000010110", "0000000000110100",
    -- Third row: 11 elements
    "0000000000101100", "0000000100101000", "0000010100000100", "0000111001001101", "0001101011010000", "0010000100001111", "0001101011010000", "0000111001001101", "0000010100000100", "0000000100101000", "0000000000101100",
    -- Fourth row: 13 elements
    "0000000000111001", "0000000011110111", "0000001100101101", "0000100000000001", "0000111101111100", "0001011100000001", "0001101001000000", "0001011100000001", "0000111101111100", "0000100000000001", "0000001100101101", "0000000011110111", "0000000000111001",
    -- Fifth row: 15 elements
    "0000000001011010", "0000000100001011", "0000001010011100", "0000010110000100", "0000100111011111", "0000111011110101", "0001001100110011", "0001010011011100", "0001001100110011", "0000111011110101", "0000100111011111", "0000010110000100", "0000001010011100", "0000000100001011", "0000000001011010",
    -- Sixth row: 19 elements
    "0000000000111100", "0000000010010100", "0000000101000101", "0000001010000011", "0000010001111000", "0000011100101001", "0000101001010110", "0000110101101101", "0000111110110110", "0001000010001110", "0000111110110110", "0000110101101101", "0000101001010110", "0000011100101001", "0000010001111000", "0000001010000011", "0000000101000101", "0000000010010100", "0000000000111100",
    --Dummy values to fill the rest of the ROM
    "0000000000000000", "0000000000000000"
    );

-- Values of offsets. 0, 9, 18, 29, 42, 57
signal ROM_ADDR_OFF: sigma_lut := ( "00000000", "00001001", "00010010", "00011101", "00101010", "00111001") ;                           
begin

-- Kernel ROM
-- The kernel ROM is a 2D array of size KERNEL_ROM_SIZE x DATA_WIDTH
-- The kernel ROM is used to store the kernel values for the convolution operation
-- The kernel ROM is divided into 6 sections, each section has a different size
clk_proc: process(clk, reset)
begin
    if (reset = '1') then
        kernel_rom_a_data <= (others => '0');
        kernel_rom_b_data <= (others => '0');

    -- On rising edge of clock, use address calculated below to access ROM and recieve data
    elsif (rising_edge(clk)) then
         if ( kernel_rom_a_en= '1') then
                kernel_rom_a_data <= ROM(to_integer(unsigned(addr_a_out)));
        end if;
        if ( kernel_rom_b_en= '1') then
                kernel_rom_b_data <= ROM(to_integer(unsigned(addr_b_out)));
        end if;
    
    end if;

end process;
-- Address offset for the kernel ROM
-- The kernel ROM is divided into 6 sections, each section has a different size
-- The address offset is used to select the correct section based on the image number
-- The address offset is added to the kernel ROM address to get the correct address for the kernel ROM
addr_a_out <= std_logic_vector(unsigned(kernel_rom_a_addr) + unsigned(ROM_ADDR_OFF(TO_INTEGER(unsigned(img_number)))));
addr_b_out <= std_logic_vector(unsigned(kernel_rom_b_addr) + unsigned(ROM_ADDR_OFF(TO_INTEGER(unsigned(img_number)))));

-- Value used to calculate center and to know k loop range
sigma_size <= SIGMA_VALS(TO_INTEGER(unsigned(img_number)));
                                                       
end Mixed;
