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
use std.textio.all;
use work.txt_util.all;
use work.utils_pkg.all;

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

    file BRAM1_txt : text open read_mode is "../../esl/vp/test/bram_init/bram_init.txt";
    file BRAM2_txt : text open write_mode is "../../esl/vp/test/bram_init/bram_init.txt";
    file KERNEL_BRAM_txt : text open read_mode is "../../esl/vp/test/kernel_bram/kernel_state_0.txt";

    --WIDTH OF DATA
    constant DATA_WIDTH : natural := 16; -- FIXED
    
    --IMAGE ELEMENTS
    constant IMG_WIDTH : natural := 450; -- VARIABLE 
    constant IMG_HEIGHT : natural := 100; -- VARIABLE 
    constant IMG_OFFSET_UP : natural := 10; -- VARIABLE 
    constant IMG_OFFSET_DOWN : natural := 10; -- VARIABLE 
    constant SIGMA_SIZE : natural := 19; --VARIABLE -- ALWAYS ODD -- MAX = KERNEL_BRAM_SIZE
    constant SIGMA_CENTER: natural := 10; --VARIABLE --ROUND(SIGMA_SIZE/2)
    
    --SIZE OF BRAMS
    constant KERNEL_BRAM_SIZE : natural := 20; --FIXED 
    constant BRAM1_SIZE : natural := 60000; --FIXED
    constant BRAM2_SIZE : natural := 59980; -- FIXED
    
    --BRAM
    constant WIDTH: positive := 16;
    constant W_R_BYTES: positive := 4;

    --signali
    signal clk_s : std_logic := '0';
    signal reset_s : std_logic;
    signal start_s : std_logic;
    signal ready_s : std_logic;
    
    signal bram1_a_en: std_logic;
    signal bram1_a_we: std_logic_vector(3 downto 0);
    signal bram1_a_raddr: std_logic_vector(log2c(BRAM1_SIZE) - 1 downto 0);
    signal bram1_a_rdata: std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    signal bram1_b_en: std_logic;
    signal bram1_b_we: std_logic_vector(3 downto 0);
    signal bram1_b_raddr: std_logic_vector(log2c(BRAM1_SIZE) - 1 downto 0);
    signal bram1_b_rdata: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    signal kernel_bram_en: std_logic;
    signal kernel_bram_we: std_logic_vector(3 downto 0);
    signal kernel_bram_raddr: std_logic_vector(log2c(KERNEL_BRAM_SIZE) - 1 downto 0);
    signal kernel_bram_rdata: std_logic_vector(DATA_WIDTH -1 downto 0);
    
    
    signal bram2_a_en: std_logic;
    signal bram2_a_we: std_logic_vector(3 downto 0);
    signal bram2_a_waddr: std_logic_vector(log2c(BRAM2_SIZE) - 1 downto 0);
    signal bram2_a_wdata: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    signal bram2_b_en: std_logic;
    signal bram2_b_we: std_logic_vector(3 downto 0);
    signal bram2_b_waddr: std_logic_vector(log2c(BRAM2_SIZE) - 1 downto 0);
    signal bram2_b_wdata: std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    

begin
    
    --intanca HW dela koji radi konvoluciju po vertikali, sto je prva
    --konvolucija koja se radi u VP.
    --U ovoj konvoluciji se cita iz BRAM1 i KERNEL_BRAM a upisuje u BRAM2.
    convolution_HW: entity work.convolute_loops(Mixed)
        generic map(DATA_WIDTH => DATA_WIDTH,
                    IMG_WIDTH => IMG_WIDTH,
                    IMG_HEIGHT => IMG_HEIGHT,
                    IMG_OFFSET_UP => IMG_OFFSET_UP,
                    IMG_OFFSET_DOWN => IMG_OFFSET_DOWN,
                    SIGMA_SIZE => SIGMA_SIZE,
                    SIGMA_CENTER => SIGMA_CENTER,
                    HORIZONTAL => false,
                    KERNEL_BRAM_SIZE => KERNEL_BRAM_SIZE,
                    BRAM1_SIZE => BRAM1_SIZE,
                    BRAM2_SIZE => BRAM2_SIZE)
        port map(clk => clk_s,
                 reset => reset_s,
                 start => start_s,
                 
                 bram1_a_en => bram1_a_en,
                 bram1_a_we => bram1_a_we,
                 bram1_a_raddr => bram1_a_raddr,
                 bram1_a_rdata => bram1_a_rdata,
                 
                 bram1_b_en => bram1_b_en,
                 bram1_b_we => bram1_b_we,
                 bram1_b_raddr => bram1_b_raddr,
                 bram1_b_rdata => bram1_b_rdata,
                 
                 kernel_bram_en => kernel_bram_en,
                 kernel_bram_we => kernel_bram_we,
                 kernel_bram_raddr => kernel_bram_raddr,
                 kernel_bram_rdata => kernel_bram_rdata,
                 
                 bram2_a_en => bram2_a_en,
                 bram2_a_we => bram2_a_we,
                 bram2_a_waddr => bram2_a_waddr,
                 bram2_a_wdata => bram2_a_wdata,
                 
                 bram2_b_en => bram2_b_en,
                 bram2_b_we => bram2_b_we,
                 bram2_b_waddr => bram2_b_waddr,
                 bram2_b_wdata => bram2_b_wdata,
                 
                 ready => ready_s);
                 
    --iz ovog brama se iscitava orignal slika
    BRAM1: entity work.bram1(Behavioral)
        generic map(WIDTH => WIDTH,
                    W_R_BYTES => W_R_BYTES,
                    SIZE => BRAM1_SIZE)
        port map(clk_a => clk_s,
                 clk_b => clk_s,
                 
                 en_a => bram1_a_en,
                 we_a => bram1_a_we,
                 addr_a => bram1_a_raddr,
                 data_a_o => bram1_a_rdata,
                 data_a_i => open,
                 
                 en_b => bram1_b_en,
                 we_b => bram1_b_we,
                 addr_b => bram1_b_raddr,
                 data_b_o => bram1_b_rdata,
                 data_b_i => open);
       
    --u ovaj bram se upisuje tmp slika 
    BRAM2: entity work.bram2(Behavioral)
        generic map(WIDTH => WIDTH,
                    W_R_BYTES => W_R_BYTES,
                    SIZE => BRAM2_SIZE)
        port map(clk_a => clk_s,
                 clk_b => clk_s,
                 
                 en_a => bram2_a_en,
                 we_a => bram2_a_we,
                 addr_a => bram2_a_waddr,
                 data_a_i => bram2_a_wdata,
                 data_a_o => open,
                 
                 en_b => bram2_b_en,
                 we_b => bram2_b_we,
                 addr_b => bram2_b_waddr,
                 data_b_i => bram2_b_wdata,
                 data_b_o => open); 
                 
    --iz ovog brama se iscitava kernel                     
    KERNEL_BRAM: entity work.bram_kernel(Behavioral)
        generic map(WIDTH => WIDTH,
                    W_R_BYTES => W_R_BYTES,
                    SIZE => BRAM2_SIZE)
        port map(clk_a => clk_s,
                 clk_b => open,
                 
                 en_a => kernel_bram_en,
                 we_a => kernel_bram_we,
                 addr_a => kernel_bram_raddr,
                 data_a_o => kernel_bram_rdata,
                 data_a_i => open,
                 
                 en_b => open,
                 we_b => open,
                 addr_b => open,
                 data_b_o => open,
                 data_b_i => open);  
                 
 
    

end Behavioral;
