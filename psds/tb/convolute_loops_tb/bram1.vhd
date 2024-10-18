library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_textio.ALL;
use work.utils_pkg.ALL;

library std;
use std.textio.all;
use work.txt_util.all;

entity bram1 is
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
          data_a_o: out std_logic_vector(2*WIDTH-1 downto 0);
          data_b_o: out std_logic_vector(2 *WIDTH-1 downto 0));
          
end bram1;

architecture Behavioral of bram1 is
 
    type ram_type is array(SIZE/2-1 downto 0) of bit_vector(2*WIDTH-1 downto 0);     
    impure function InitRamFromFile(RamFileName : in string) return ram_type is
        FILE RamFile : text is in RamFileName;
        variable RamFileLine : line;
        variable RAM : ram_type;
        variable i : integer;
    begin
        i := 0;
        while not endfile(RamFile) loop
            readline(RamFile, RamFileLine);
            read(RamFileLine, RAM(i));
            i := i + 1;
        end loop;
        return RAM;
    end function;

    signal RAM : ram_type := InitRamFromFile("/home/luka/y24-g10/psds/tb/bram_init/bram_state_1_init.txt");  
    attribute ram_style: string;
    attribute ram_style of RAM: signal is "block";   
begin


    process(clk_a, clk_b)
    begin
        if (rising_edge(clk_a)) then
            if (en_a = '1') then
                    data_a_o <= to_stdlogicvector(RAM(to_integer(unsigned(addr_a))));
                    if (we_a /= "0000") then
                        RAM(to_integer(unsigned(addr_a))) <= to_bitvector(data_a_i);
                    end if;
            end if;
        end if;
        
        if (rising_edge(clk_b)) then
            if (en_b = '1') then                   
                    data_b_o <= to_stdlogicvector(RAM(to_integer(unsigned(addr_b))));
                    if (we_b /= "0000") then
                        RAM(to_integer(unsigned(addr_b))) <= to_bitvector(data_b_i);
                    end if;   
            end if;
        end if;
    
    end process;

end Behavioral;
