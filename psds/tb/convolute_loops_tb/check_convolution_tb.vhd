----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/03/2024 06:05:04 PM
-- Design Name: 
-- Module Name: check_convolution_tb - Behavioral
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_textio.ALL;
use std.textio.all;
use work.txt_util.all;
use work.utils_pkg.all;

library std;
use std.textio.all;
use work.txt_util.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity check_convolution_tb is
--  Port ( );
end check_convolution_tb;

architecture Behavioral of check_convolution_tb is
    constant DATA_WIDTH : integer :=16;
    constant BRAM_SIZE : integer :=60000;
    constant KERNEL_ROM_SIZE : integer :=76;

    --signali
    signal clk_s : std_logic ;
    signal reset_s : std_logic;
    signal start_s, start_main : std_logic;
    signal ready_s : std_logic;
    
    signal img_height_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_width_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_offset_up_s: std_logic_vector(DATA_WIDTH -1 downto 0); 
    signal img_offset_down_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_per_octave_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    
    signal sigma_size_s: std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    
    signal bram1_a_en_s: std_logic;
    signal bram1_a_we_s: std_logic_vector(3 downto 0);
    signal bram1_a_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal bram1_a_rdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    signal bram1_a_wdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    signal bram1_b_en_s: std_logic;
    signal bram1_b_we_s: std_logic_vector(3 downto 0);
    signal bram1_b_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal bram1_b_rdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    signal bram1_b_wdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    signal kernel_rom_en_s: std_logic;
    signal kernel_rom_addr_s: std_logic_vector(log2c(KERNEL_ROM_SIZE) - 1 downto 0);
    signal kernel_rom_data_s: std_logic_vector(DATA_WIDTH -1 downto 0);
     
    signal bram2_a_en_s: std_logic;
    signal bram2_a_we_s: std_logic_vector(3 downto 0);
    signal bram2_a_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal bram2_a_rdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    signal bram2_a_wdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    signal bram2_b_en_s: std_logic;
    signal bram2_b_we_s: std_logic_vector(3 downto 0);
    signal bram2_b_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal bram2_b_rdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    signal bram2_b_wdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    signal rom_addr_off_next_s: std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    
    

begin
    
    --intanca HW dela koji radi konvoluciju po vertikali, sto je prva
    --konvolucija koja se radi u VP.
    --U ovoj konvoluciji se cita iz BRAM1 i KERNEL_BRAM a upisuje u BRAM2.
    convolution_HW: entity work.convolute_loops(Mixed)
        generic map(DATA_WIDTH => DATA_WIDTH,                
                    HORIZONTAL => false,
                    KERNEL_ROM_SIZE => KERNEL_ROM_SIZE,
                    BRAM_SIZE => BRAM_SIZE)
        port map(clk => clk_s,
                 reset => reset_s,
                 start => start_s,
                 
                 img_height => img_height_s,
                 img_width => img_width_s,
                 img_offset_up => img_offset_up_s,
                 img_offset_down => img_offset_down_s,
                
                 sigma_size => sigma_size_s,
                 
                 bram1_a_en => bram1_a_en_s,
                 bram1_a_we => bram1_a_we_s,
                 bram1_a_addr => bram1_a_addr_s,
                 bram1_a_rdata => bram1_a_rdata_s,
                 
                 bram1_b_en => bram1_b_en_s,
                 bram1_b_we => bram1_b_we_s,
                 bram1_b_addr => bram1_b_addr_s,
                 bram1_b_rdata => bram1_b_rdata_s,
                 
                 kernel_rom_en => kernel_rom_en_s,
                 kernel_rom_addr => kernel_rom_addr_s,
                 kernel_rom_data => kernel_rom_data_s,
                 
                 bram2_a_en => bram2_a_en_s,
                 bram2_a_we => bram2_a_we_s,
                 bram2_a_addr => bram2_a_addr_s,
                 bram2_a_wdata => bram2_a_wdata_s,
                 
                 bram2_b_en => bram2_b_en_s,
                 bram2_b_we => bram2_b_we_s,
                 bram2_b_addr => bram2_b_addr_s,
                 bram2_b_wdata => bram2_b_wdata_s,
                 
                 ready => ready_s);
                 
    --iz ovog brama se iscitava orignal slika
    BRAM1: entity work.bram1(Behavioral)
        generic map(WIDTH => DATA_WIDTH,
                    SIZE => BRAM_SIZE)
        port map(clk_a => clk_s,
                 clk_b => clk_s,
                 
                 en_a => bram1_a_en_s,
                 we_a => bram1_a_we_s,
                 addr_a => bram1_a_addr_s,
                 data_a_o => bram1_a_rdata_s,
                 data_a_i => (others => '0'),
                 
                 en_b => bram1_b_en_s,
                 we_b => bram1_b_we_s,
                 addr_b => bram1_b_addr_s,
                 data_b_o => bram1_b_rdata_s,
                 data_b_i => (others => '0')  );
       
    --u ovaj bram se upisuje tmp slika 
    BRAM2: entity work.bram2(Behavioral)
        generic map(WIDTH => DATA_WIDTH,
                    SIZE => BRAM_SIZE)
        port map(clk_a => clk_s,
                 clk_b => clk_s,
                 
                 en_a => bram2_a_en_s,
                 we_a => bram2_a_we_s,
                 addr_a => bram2_a_addr_s,
                 data_a_i => bram2_a_wdata_s,
                 data_a_o => bram2_a_rdata_s,
                 
                 en_b => bram2_b_en_s,
                 we_b => bram2_b_we_s,
                 addr_b => bram2_b_addr_s,
                 data_b_i => bram2_b_wdata_s,
                 data_b_o => bram2_a_rdata_s); 
                 
    --iz ovog brama se iscitava kernel                     
    KERNEL_ROM: entity work.kernel_rom(Mixed)
        generic map(DATA_WIDTH => DATA_WIDTH,
                    KERNEL_ROM_SIZE => KERNEL_ROM_SIZE)
        port map(clk => clk_s,
                 reset => reset_s,
                 
                 img_number => img_per_octave_s,
    
                 kernel_rom_a_en => kernel_rom_en_s,
                 kernel_rom_a_addr => kernel_rom_addr_s,
                 kernel_rom_b_en => '0',
                 kernel_rom_b_addr => (others => '0') ,
                
                 kernel_rom_a_data => kernel_rom_data_s,
                 kernel_rom_b_data => open ,
                
                 kernel_rom_addr_off_prev => "00001001" ,
                 kernel_rom_addr_off_next => rom_addr_off_next_s,
                
                 sigma_size => sigma_size_s
                 );  
                 
    
clk_gen: process
begin
    clk_s <= '0','1' after 9 ns;
    wait for 18 ns;
end process;

stim_gen: process
begin
    reset_s <= '1';
    wait for 45 ns;
    reset_s <= '0';
    kernel_rom_en_s <= '1'; 
    wait until falling_edge(clk_s);
    bram1_a_en_s <= '1';
    bram1_b_en_s <= '1';
    
    bram1_a_we_s <= "0000";
    bram1_b_we_s <= "0000";
    
    bram2_a_en_s <= '1';
    bram2_b_en_s <= '1';
    
    img_height_s <= std_logic_vector(TO_SIGNED(90, 16));
    img_width_s <= std_logic_vector(TO_SIGNED(225, 16));
    img_offset_up_s <= std_logic_vector(TO_SIGNED(0, 16));
    img_offset_down_s <= std_logic_vector(TO_SIGNED(0, 16));
    img_per_octave_s <= std_logic_vector(TO_SIGNED(1, 16));  
    
    start_s <= '1';
    wait until falling_edge(clk_s);
    start_s <= '0';

wait;
end process;
                 
 


end Behavioral;
