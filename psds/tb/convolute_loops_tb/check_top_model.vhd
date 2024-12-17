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
    constant BRAM_SIZE : integer :=60000;
    constant KERNEL_ROM_SIZE : integer :=77;
    constant SHIFT_W1: integer := 1;
    constant SHIFT_W2: integer := 15;
        
    file init_txt : text open write_mode is "/home/luka/sift-cpp-master/psds/tb/saved/bram_init_top.txt";
    file save_txt : text open write_mode is "/home/luka/sift-cpp-master/psds/tb/saved/bram_save_top.txt";

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
    signal bram_a_en_s: std_logic;
    signal main_a_we_s: std_logic_vector(3 downto 0);
    signal main_a_addr_s: std_logic_vector(log2c(BRAM_SIZE/2) - 1 downto 0);  
    signal main_a_rdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    signal bram2_a_rdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    signal main_a_wdata_s: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    
begin
    
    --intanca HW dela koji radi konvoluciju po vertikali, sto je prva
    --konvolucija koja se radi u VP.
    --U ovoj konvoluciji se cita iz BRAM1 i KERNEL_BRAM a upisuje u BRAM2.
    
TOP: entity work.top_model(Structural)
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
        generic map(WIDTH => DATA_WIDTH,
                    R_W_BYTES => 2,
                    SIZE => BRAM_SIZE)
        port map(clk_a => clk_s,
                 clk_b => clk_s,
                 
                 en_a => '1',
                 we_a => "0000",
                 addr_a => main_a_addr_s,
                 data_a_o => main_a_wdata_s,
                 data_a_i => (others => '0'),
                 
                 en_b => '0',
                 we_b => (others => '0'),
                 addr_b => (others => '0'),
                 data_b_o => open,
                 data_b_i => (others => '0')  );
BRAM2: entity work.bram2(Behavioral)
        generic map(WIDTH => DATA_WIDTH,
                    SIZE => BRAM_SIZE)
        port map(clk_a => clk_s,
                 clk_b => clk_s,
                 
                 en_a => bram_a_en_s,
                 we_a => "1111",
                 addr_a => main_a_addr_s,
                 data_a_o => open,
                 data_a_i => main_a_rdata_s,
                 
                 en_b => bram_a_en_s,
                 we_b => (others => '0'),
                 addr_b => main_a_addr_s,
                 data_b_o => bram2_a_rdata_s,
                 data_b_i => (others => '0')  );
        
clk_gen: process
begin
    clk_s <= '0','1' after 5 ns;
    wait for 10 ns;
end process;

stim_gen: process
begin
    start_s <= '0';
    main_a_en_s <= '0';  
    main_a_we_s <= "0000";   
    reset_s <= '1';
    bram_a_en_s <= '0';
    wait for 63 ns;
    reset_s <= '0';
    
    img_height_s <= std_logic_vector(TO_SIGNED(100, DATA_WIDTH));
    wait until rising_edge(clk_s);    
    img_width_s <= std_logic_vector(TO_SIGNED(450, DATA_WIDTH));
    wait until rising_edge(clk_s);
    img_offset_up_s <= std_logic_vector(TO_SIGNED(0, DATA_WIDTH));
    wait until rising_edge(clk_s);
    img_offset_down_s <= std_logic_vector(TO_SIGNED(10, DATA_WIDTH));
    wait until rising_edge(clk_s);
    img_per_octave_s <= std_logic_vector(TO_SIGNED(0, DATA_WIDTH)); 
    wait until rising_edge(clk_s);
    
    main_a_we_s <= "1111"; 
    main_a_en_s <= '1';
    main_a_addr_s <= (others => '0'); 
    wait until rising_edge(clk_s); 
    for i in 1 to BRAM_SIZE/2-1 loop
        main_a_addr_s <= std_logic_vector(TO_UNSIGNED(i-1, log2c(BRAM_SIZE/2))); 
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
    end loop;  
    wait until rising_edge(clk_s);
    main_a_we_s <= "0000";     
    main_a_en_s <= '0';  

    start_s <= '1'; 
    wait until rising_edge(clk_s);
    start_s <= '0';
    wait until rising_edge(clk_s);
    
    wait until ready_s = '1';
    bram_a_en_s <= '1';
    main_a_we_s <= "0000"; 
    main_a_en_s <= '1';   
    for i in 0 to BRAM_SIZE/2-1 loop
        main_a_addr_s <= std_logic_vector(TO_UNSIGNED(i , log2c(BRAM_SIZE/2))); 
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
    end loop;
    main_a_en_s <= '0';             
wait;
end process;  
              
write_proc_y: process(main_a_wdata_s, main_a_addr_s, main_a_we_s)
variable row: line;
begin
if main_a_we_s = "1111" then
    write(row, string'("Write_Pix1: "), left, SHIFT_W1);
    write(row, TO_INTEGER(unsigned(main_a_wdata_s(2 * DATA_WIDTH -1 downto DATA_WIDTH))), left , SHIFT_W2);
    write(row, string'("Write_Pix2: "), left, SHIFT_W1);
    write(row, TO_INTEGER(unsigned(main_a_wdata_s(DATA_WIDTH -1 downto 0))), left , SHIFT_W2);       
    write(row, string'("Write_Pixs_addr: "), left, SHIFT_W1);
    write(row, TO_INTEGER(unsigned(main_a_addr_s)), left , SHIFT_W2);
    writeline(init_txt, row);
end if;
end process;

write_proc_x: process(bram2_a_rdata_s, main_a_addr_s, main_a_we_s)
variable row: line;
begin
if bram_a_en_s = '1' and TO_INTEGER(unsigned(bram2_a_rdata_s)) /= 0 then
    write(row, string'("Read_Pix1: "), left, SHIFT_W1);
    write(row, TO_INTEGER(unsigned(bram2_a_rdata_s(2 * DATA_WIDTH -1 downto DATA_WIDTH))), left , SHIFT_W2);
    write(row, string'("Read_Pix2: "), left, SHIFT_W1);
    write(row, TO_INTEGER(unsigned(bram2_a_rdata_s(DATA_WIDTH -1 downto 0))), left , SHIFT_W2);    
    write(row, string'("Read_Pixs_addr: "), left, SHIFT_W1);
    write(row, TO_INTEGER(unsigned(main_a_addr_s)), left , SHIFT_W2);
    writeline(save_txt, row); 
end if;     
end process;

end Behavioral;

