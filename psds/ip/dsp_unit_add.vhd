library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dsp_unit_add is
    generic (WIDTH1: natural := 16;
             WIDTH2: natural := 16
             );
    port (clk: in std_logic;
          rst: in std_logic;
          in_1: in std_logic_vector(WIDTH1 - 1 downto 0);
          in_2: in std_logic_vector(WIDTH2 - 1 downto 0);
          out_res: out std_logic_vector(WIDTH1 - 1 downto 0));
end dsp_unit_add;

architecture Behavioral of dsp_unit_add is
    attribute use_dsp : string;
    attribute use_dsp of Behavioral : architecture is "yes";
    
    signal res_reg: std_logic_vector(WIDTH1 - 1 downto 0);
begin
    process(clk) is
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                res_reg <= (others => '0');
            else
                res_reg <= std_logic_vector(unsigned(in_1) + unsigned(in_2));
            end if;
        end if;
    end process;
    out_res <= res_reg;
end Behavioral;
