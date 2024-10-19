library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dsp_unit_mul_shift is
    generic (WIDTH: natural := 16;
             SHIFT: natural := 14);
    port (clk: in std_logic;
          rst: in std_logic;
          in_1: in std_logic_vector(WIDTH - 1 downto 0);
          in_2: in std_logic_vector(WIDTH - 1 downto 0);
          out_res: out std_logic_vector(WIDTH - 1 downto 0)
          );
end dsp_unit_mul_shift;

architecture Behavioral of dsp_unit_mul_shift is
    attribute use_dsp : string;
    attribute use_dsp of Behavioral : architecture is "yes";
    
    signal mult_reg, shift_reg: std_logic_vector(2 *WIDTH - 1 downto 0);
begin
    process(clk) is
    begin
        if (rising_edge(clk)) then
                mult_reg <= std_logic_vector(signed(in_1) * signed(in_2));
                shift_reg <= std_logic_vector(shift_right(unsigned(mult_reg), SHIFT));
        end if;
    end process;
    
    out_res <= shift_reg(WIDTH-1 downto 0);
end Behavioral;
