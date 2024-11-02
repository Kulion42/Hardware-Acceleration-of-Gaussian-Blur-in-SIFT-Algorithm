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

entity check_gaussian_blur is
--  Port ( );
end check_gaussian_blur;

architecture Behavioral of check_gaussian_blur is
    constant DATA_WIDTH : integer :=16;
    constant BRAM_SIZE : integer :=30000;
    constant KERNEL_ROM_SIZE : integer :=76;

    --signali
    signal clk_s : std_logic ;
    signal reset_s : std_logic;
    signal start_s : std_logic;
    signal ready_s : std_logic;
    
    signal img_height_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_width_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_offset_up_s: std_logic_vector(DATA_WIDTH -1 downto 0); 
    signal img_offset_down_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_per_octave_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    
    --signal sigma_size_s: std_logic_vector(DATA_WIDTH/2 -1 downto 0);

    signal main_b_en_s: std_logic;
    signal main_b_we_s: std_logic_vector(3 downto 0);
    signal main_b_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal main_b_rdata_s: std_logic_vector(2 *(DATA_WIDTH -1) -1 downto 0);
    signal main_b_wdata_s: std_logic_vector(2 *(DATA_WIDTH -1) -1 downto 0);
    
    --signal kernel_rom_en_s: std_logic;
    --signal kernel_rom_addr_s: std_logic_vector(log2c(KERNEL_ROM_SIZE) - 1 downto 0);
    --signal kernel_rom_data_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    
    signal tmp_b_en_s: std_logic;
    signal tmp_b_we_s: std_logic_vector(3 downto 0);
    signal tmp_b_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal tmp_b_rdata_s: std_logic_vector(2 *(DATA_WIDTH -1) -1 downto 0);
    signal tmp_b_wdata_s: std_logic_vector(2 *(DATA_WIDTH -1) -1 downto 0);
    
    --signal rom_addr_off_next_s: std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    
    

begin
    
    --intanca HW dela koji radi konvoluciju po vertikali, sto je prva
    --konvolucija koja se radi u VP.
    --U ovoj konvoluciji se cita iz BRAM1 i KERNEL_BRAM a upisuje u BRAM2.
    
GAUSS: entity work.gaussian_blur(Mixed)
    generic map(DATA_WIDTH => DATA_WIDTH,
                KERNEL_ROM_SIZE => KERNEL_ROM_SIZE,
                BRAM_SIZE => BRAM_SIZE)
                
    port map (  clk => clk_s,
    reset => reset_s,
    start => start_s,
    
    --IMAGE ELEMENTS
    img_height => img_height_s,
    img_width => img_width_s,
    img_offset_up => img_offset_up_s, 
    img_offset_down => img_offset_down_s,
    img_per_octave => img_per_octave_s,
    
    --BRAMS
    main_bram_a_en => '0',
    main_bram_b_en => main_b_en_s,
    main_bram_b_we => main_b_we_s,
    main_bram_b_addr => main_b_addr_s,
    main_bram_b_rdata => main_b_rdata_s,
    main_bram_b_wdata => main_b_wdata_s, 
    
    tmp_bram_b_en => tmp_b_en_s,
    tmp_bram_b_we => tmp_b_we_s,
    tmp_bram_b_addr => tmp_b_addr_s,
    tmp_bram_b_rdata => tmp_b_rdata_s,
    tmp_bram_b_wdata => tmp_b_wdata_s,
    
    
    ready => ready_s);            
    
                 
    --iz ovog brama se iscitava orignal slika
BRAM1: entity work.bram1(Behavioral)
        generic map(WIDTH => DATA_WIDTH-1,
                    SIZE => BRAM_SIZE)
        port map(clk_a => clk_s,
                 clk_b => clk_s,
                 
                 en_a => '0',
                 we_a => (others => '0'),
                 addr_a => (others => '0'),
                 data_a_o => open,
                 data_a_i => (others => '0'),
                 
                 en_b => '1',
                 we_b => main_b_we_s,
                 addr_b => main_b_addr_s,
                 data_b_o => main_b_rdata_s,
                 data_b_i => main_b_wdata_s  );
       
    --u ovaj bram se upisuje tmp slika 
BRAM2: entity work.bram(Behavioral)
        generic map(WIDTH => DATA_WIDTH -1,
                    SIZE => BRAM_SIZE)
        port map(clk_a => clk_s,
                 clk_b => clk_s,
                 
                 en_a => '0',
                 we_a => (others => '0'),
                 addr_a => (others => '0'),
                 data_a_i => (others => '0'),
                 data_a_o => open,
                 
                 en_b => '1',
                 we_b => tmp_b_we_s,
                 addr_b => tmp_b_addr_s,
                 data_b_i => tmp_b_wdata_s,
                 data_b_o => tmp_b_rdata_s); 
                                   
    
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
    wait until falling_edge(clk_s);
    start_s <= '0';
           
    img_height_s <= std_logic_vector(TO_SIGNED(100, 16));
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

