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

entity check_top_model  is
--  Port ( );
end check_top_model;

architecture Behavioral of check_top_model is
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
    
    signal main_a_en_s: std_logic;
    signal main_a_we_s: std_logic_vector(3 downto 0);
    signal main_a_addr_s: std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    signal main_a_rdata_s: std_logic_vector(2 *(DATA_WIDTH -1) -1 downto 0); 
    signal main_a_wdata_s: std_logic_vector(2 *(DATA_WIDTH -1) -1 downto 0);
    
    
begin
    
    --intanca HW dela koji radi konvoluciju po vertikali, sto je prva
    --konvolucija koja se radi u VP.
    --U ovoj konvoluciji se cita iz BRAM1 i KERNEL_BRAM a upisuje u BRAM2.
    
GAUSS: entity work.top_model(Structural)
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
    main_bram_a_cpu_en => main_a_en_s,
    main_bram_a_cpu_we => main_a_we_s,
    main_bram_a_cpu_addr => main_a_addr_s,
    main_bram_a_cpu_rdata => main_a_rdata_s,
    main_bram_a_cpu_wdata => main_a_wdata_s, 
    
    ready => ready_s);            
    
                 
    --iz ovog brama se iscitava orignal slika
BRAM1: entity work.bram1(Behavioral)
        generic map(WIDTH => DATA_WIDTH-1,
                    SIZE => BRAM_SIZE)
        port map(clk_a => clk_s,
                 clk_b => clk_s,
                 
                 en_a => main_a_en_s,
                 we_a => not(main_a_we_s),
                 addr_a => main_a_addr_s,
                 data_a_o => main_a_wdata_s,
                 data_a_i => main_a_rdata_s,
                 
                 en_b => '0',
                 we_b => (others => '0'),
                 addr_b => (others => '0'),
                 data_b_o => open,
                 data_b_i => (others => '0')  );
    
clk_gen: process
begin
    clk_s <= '0','1' after 9 ns;
    wait for 18 ns;
end process;

stim_gen: process
begin
    start_s <= '0';
    main_a_en_s <= '0';    
    reset_s <= '1';
    wait for 45 ns;
    reset_s <= '0';
    
    img_height_s <= std_logic_vector(TO_SIGNED(100, DATA_WIDTH));
    img_width_s <= std_logic_vector(TO_SIGNED(225, DATA_WIDTH));
    img_offset_up_s <= std_logic_vector(TO_SIGNED(0, DATA_WIDTH));
    img_offset_down_s <= std_logic_vector(TO_SIGNED(0, DATA_WIDTH));
    img_per_octave_s <= std_logic_vector(TO_SIGNED(0, DATA_WIDTH)); 
    
    wait until falling_edge(clk_s);
    main_a_we_s <= "1111"; 
    main_a_en_s <= '1';    
    for i in 0 to BRAM_SIZE-1 loop
        wait until rising_edge(clk_s);
        main_a_addr_s <= std_logic_vector(TO_UNSIGNED(i, log2c(BRAM_SIZE))); 
    end loop;    
    wait until rising_edge(clk_s);
    main_a_en_s <= '0'; 

    start_s <= '1'; 
    wait until rising_edge(clk_s);
    start_s <= '0';
    wait until rising_edge(clk_s);

    
    wait until ready_s = '1' and main_a_en_s = '0';
    main_a_we_s <= "0000";
    main_a_en_s <= '1'; 
    for i in 0 to BRAM_SIZE-1 loop
        wait until rising_edge(clk_s); 
        main_a_addr_s <= std_logic_vector(TO_UNSIGNED(i, log2c(BRAM_SIZE)));
    end loop;
    wait until rising_edge(clk_s);
    main_a_we_s <= "1111";
    main_a_en_s <= '0';
        
     
wait;
end process;  
              


end Behavioral;


