library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dsp_unit_mac_shift is
    generic (WIDTH_IN: natural := 16;
             WIDTH_OUT:natural := 16 );
    port (clk: in std_logic;
          rst: in std_logic;
          in_1: in std_logic_vector(WIDTH_IN - 1 downto 0);
          in_2: in std_logic_vector(WIDTH_IN - 1 downto 0);
          in_3: in std_logic_vector(WIDTH_IN - 1 downto 0);
          out_res: out std_logic_vector(WIDTH_OUT - 1 downto 0)
          );
end dsp_unit_mac_shift;

architecture Behavioral of dsp_unit_mac_shift is
    attribute use_dsp : string;
    attribute use_dsp of Behavioral : architecture is "yes";
    
    signal mult_reg, alu_reg: std_logic_vector(2 *WIDTH_IN - 1 downto 0);
    signal tmp_reg: std_logic_vector(WIDTH_IN - 1 downto 0);
begin
    process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                mult_reg <= (others => '0');
                tmp_reg <= (others => '0');
                alu_reg <= (others => '0');
             else
                tmp_reg <= in_3;
                mult_reg <= std_logic_vector(unsigned(in_1) * unsigned(in_2));
                alu_reg <= std_logic_vector(unsigned(mult_reg) + unsigned(tmp_reg));
            end if;
        end if;
    end process;
    out_res <= alu_reg(WIDTH_OUT-1 downto 0);
end Behavioral;
