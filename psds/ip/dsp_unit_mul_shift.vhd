library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dsp_unit_mul_shift is
    generic (WIDTH1: natural := 16;
	     WIDTH2: natural := 15;
             SHIFT: natural := 14);
    port (clk: in std_logic;
          rst: in std_logic;
          in_1: in std_logic_vector(WIDTH2 - 1 downto 0);
          in_2: in std_logic_vector(WIDTH1 - 1 downto 0);
          out_res: out std_logic_vector(WIDTH1 - 1 downto 0)
          );
end dsp_unit_mul_shift;

architecture Behavioral of dsp_unit_mul_shift is
    attribute use_dsp : string;
    attribute use_dsp of Behavioral : architecture is "yes";
    
    signal mult_reg, shift_reg: std_logic_vector(WIDTH1 + WIDTH2 - 1 downto 0);
begin
    process(clk)
    begin
        if (rising_edge(clk)) then
                mult_reg <= std_logic_vector(unsigned(in_1) * unsigned(in_2));
                shift_reg <= std_logic_vector(shift_right(unsigned(mult_reg), SHIFT));
        end if;
    end process;
    
    out_res <= shift_reg(WIDTH1-1 downto 0);
end Behavioral;
