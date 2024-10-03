----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/26/2024 03:40:12 PM
-- Design Name: 
-- Module Name: convolute_vertical - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils_pkg.ALL;




entity convolute_loops is
Generic(
    --WIDTH OF DATA
    DATA_WIDTH : natural := 16; -- FIXED
    
    --DIRECTION OF CONVOLUTION
    HORIZONTAL: boolean := true;
    
    --SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE : natural := 76; --FIXED 
    BRAM_SIZE : natural := 60000 --FIXED

);
Port ( 
    clk : in std_logic;
    reset: in std_logic;
    start: in std_logic;
    
    --IMAGE ELEMENTS
    img_height: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_width: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_offset_up: in std_logic_vector(DATA_WIDTH -1 downto 0); 
    img_offset_down: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    sigma_size : in std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    
    bram1_a_en: out std_logic;
    bram1_a_we: out std_logic_vector(3 downto 0);
    bram1_a_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram1_a_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    bram1_b_en: out std_logic;
    bram1_b_we: out std_logic_vector(3 downto 0);
    bram1_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram1_b_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);

    kernel_rom_en: out std_logic;
    kernel_rom_addr: out std_logic_vector(log2c(KERNEL_ROM_SIZE) - 1 downto 0);
    kernel_rom_data: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    bram2_a_en: out std_logic;
    bram2_a_we: out std_logic_vector(3 downto 0);
    bram2_a_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram2_a_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    bram2_b_en: out std_logic;
    bram2_b_we: out std_logic_vector(3 downto 0);
    bram2_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram2_b_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    ready : out std_logic
      
);
end convolute_loops;

architecture Mixed of convolute_loops is
    attribute use_dsp : string;
    attribute use_dsp of Mixed : architecture is "yes";
    

component dsp_unit_mac_shift2 is
    generic (WIDTH1: natural := 16;
             WIDTH2: natural := 16;
             WIDTH3: natural := 16 );
    port (clk: in std_logic;
          rst: in std_logic;
          in_1: in std_logic_vector(WIDTH1 - 1 downto 0);
          in_2: in std_logic_vector(WIDTH2 - 1 downto 0);
          in_3: in std_logic_vector(WIDTH3 - 1 downto 0);
          out_res: out std_logic_vector(WIDTH1 - 1 downto 0)
          );
end component;
signal x, y, k, dy, dx, c_y, c_x1, c_x2 : signed(DATA_WIDTH -1 downto 0);
signal x_add_2, x_add_1_next: signed(DATA_WIDTH - 1 downto 0);
signal x_next, y_next, k_next, c_y_next, c_x1_next, c_x2_next : signed(DATA_WIDTH - 1 downto 0);
--signal pix1, pix2, pix3, pix4: unsigned(DATA_WIDTH -1 downto 0);
--signal val, val_next: unsigned(DATA_WIDTH -1 downto 0);
signal sum1_reg, sum2_reg, sum3_reg, sum4_reg: unsigned(DATA_WIDTH -1  downto 0); 
signal sum1_next, sum2_next, sum3_next, sum4_next: unsigned(DATA_WIDTH - 1 downto 0);
signal mul_reg_1, mul_reg_2, mul_reg_3, mul_reg_4: unsigned(2 *DATA_WIDTH -1 downto 0);
signal sigma_center: signed(DATA_WIDTH/2 -1 downto 0);
type state_t is (idle, loops, sum_calc, stal1, stal2, stal3);
signal state_reg, state_next : state_t;

begin

sigma_center <= not('0' &signed(sigma_size(DATA_WIDTH/2 -1 downto 1))) + 1;
addr_gen_1 : dsp_unit_mac_shift2
    generic map(
         WIDTH1 => DATA_WIDTH,
         WIDTH2 => DATA_WIDTH,
         WIDTH3 => DATA_WIDTH)
    port map(
         clk => clk,
         rst => reset,
         in_1 => std_logic_vector(c_y),
         in_2 => img_width,
         in_3 => std_logic_vector(c_x1),
         out_res => bram1_a_addr
         );
addr_gen_2 : dsp_unit_mac_shift2
    generic map(
         WIDTH1 => DATA_WIDTH,
         WIDTH2 => DATA_WIDTH,
         WIDTH3 => DATA_WIDTH)
    port map(
         clk => clk,
         rst => reset,
         in_1 => std_logic_vector(c_y),
         in_2 => img_width,
         in_3 => std_logic_vector(c_x2),
         out_res => bram1_b_addr
         );    
addr_gen_3 : dsp_unit_mac_shift2
    generic map(
         WIDTH1 => DATA_WIDTH,
         WIDTH2 => DATA_WIDTH,
         WIDTH3 => DATA_WIDTH)
    port map(
         clk => clk,
         rst => reset,
         in_1 => std_logic_vector(y),
         in_2 => img_width,
         in_3 => std_logic_vector(x),
         out_res => bram2_a_addr
         );    
addr_gen_4 : dsp_unit_mac_shift2
    generic map(
         WIDTH1 => DATA_WIDTH,
         WIDTH2 => DATA_WIDTH,
         WIDTH3 => DATA_WIDTH)
    port map(
         clk => clk,
         rst => reset,
         in_1 => std_logic_vector(y),
         in_2 => img_width,
         in_3 => std_logic_vector(x_add_2),
         out_res => bram2_b_addr
         );                                     
next_state_process: process(clk, reset) is

begin
    
    if (reset = '1') then
        state_reg <= idle;
        
        x <= (others => '0');
        y <= (others => '0');
        k <= (others => '0');
        
        c_x1 <= (others => '0'); 
        c_x2 <= TO_SIGNED(1, 16); 
        c_y <= (others => '0');
        
        sum1_reg <= (others => '0');
        sum2_reg <= (others => '0');
        sum3_reg <= (others => '0'); 
        sum4_reg <= (others => '0');
    
    elsif (rising_edge(clk) and reset = '0') then
        state_reg <= state_next;
    
        x <= x_next;
        y <= y_next;
        k <= k_next; 
        
        sum1_reg <= sum1_next;
        sum2_reg <= sum2_next;
        sum3_reg <= sum3_next; 
        sum4_reg <= sum4_next;
        c_x1 <= c_x1_next; 
        c_x2 <= c_x2_next; 
        c_y <= c_y_next;
    
    end if;

end process;

combinational_logic_process: process(start, state_reg, state_next, sigma_size, x, x_next, y, y_next, k, k_next, kernel_rom_data, img_width, img_height) is
begin
    
    x_next <= x;
    y_next <= y;
    k_next <= k;    
    
    sum1_next <= sum1_reg;
    sum2_next <= sum2_reg;
    sum3_next <= sum3_reg; 
    sum4_next <= sum4_reg;
    
    c_x1_next <= c_x1; 
    c_x2_next <= c_x2; 
    c_y_next <= c_y;    
          
    bram2_a_wdata <= std_logic_vector(sum1_reg&sum2_reg);
    bram2_b_wdata <= std_logic_vector(sum3_reg&sum4_reg); 
              
    ready <= '0';
                
    case state_reg is 
    
        when idle =>
            if start = '1' then
                state_next <= loops;
                                  
            elsif start = '0' then  
                ready <= '1';          
                state_next <= idle;
            end if;
            
        when loops =>    
            if x>= signed(img_width) then
                ready <= '1';
                state_next <= idle;          
            elsif ( HORIZONTAL = false and y>= signed(img_height) - signed(img_offset_down)) or ( HORIZONTAL = true and y>= signed(img_height) - signed(img_offset_down) - signed(img_offset_up)) then    
                y_next <= (others => '0');
                x_next <= x + 2;
                state_next <= loops; 
                 
            elsif k>= signed(sigma_size)  then
                k_next <= (others => '0');          
                y_next <= y + 1;                   
                state_next <= stal2;                   
            else
                   if HORIZONTAL = true then
                    if abs(dx) > x  then
                        c_x1_next <= (others => '0');
                    elsif x + dx >= signed(img_width) then 
                        c_x1_next <= signed(img_width) -1;
                    else
                        c_x1_next <= x + dx;
                    end if;
                    
                    if abs(dx) > x_add_2 then
                        c_x2_next <= (others => '0');
                    elsif x_add_2 + dx >= signed(img_width) then 
                        c_x2_next <= signed(img_width) -1;
                    else
                        c_x2_next <= x_add_2 + dx;
                    end if;
                    
                    c_y_next <= y;

                else                     
                    if abs(dy) > y  and TO_INTEGER(signed(img_offset_up)) = 0  then
                        c_y_next <= (others => '0');
                        
                    elsif dy < 0 and y + dy < signed(img_offset_up) and TO_INTEGER(signed(img_offset_up)) = 10 then
                        c_y_next <= signed(img_offset_up) + dy;
                                
                    elsif y + dy >= signed(img_height) and TO_INTEGER(signed(img_offset_down)) = 0 then
                        c_y_next <= signed(img_height) -1 ;
                                
                    elsif y + dy >= signed(img_height) and TO_INTEGER(signed(img_offset_down)) = 10 then
                        c_y_next <= signed(img_height) - signed(img_offset_down) + dy;
                                    
                    else
                        c_y_next <= y + dy;
                    end if;
                    
                    c_x1_next <= x; 
                    c_x2_next <= x_add_2;

                end if; 
                state_next <= stal1;
             end if;
        when stal1 => 
                state_next <= sum_calc;
        when stal2 => 
                state_next <= stal3;        
        when stal3 => 
                sum1_next <= (others => '0');
                sum2_next <= (others => '0');
                sum3_next <= (others => '0');
                sum4_next <= (others => '0'); 
                state_next <= loops;             
        when sum_calc =>         
                sum1_next <= sum1_reg + TO_UNSIGNED(TO_INTEGER(unsigned(mul_reg_1))/2 **14, 16);
                sum2_next <= sum2_reg + TO_UNSIGNED(TO_INTEGER(unsigned(mul_reg_2))/2 **14, 16);
                sum3_next <= sum3_reg + TO_UNSIGNED(TO_INTEGER(unsigned(mul_reg_3))/2 **14, 16);
                sum4_next <= sum4_reg + TO_UNSIGNED(TO_INTEGER(unsigned(mul_reg_4))/2 **14, 16);               
                k_next <= k + 1;
                state_next <= loops;         
            
        when others => 
            state_next <= idle;
    
    end case;

end process;
kernel_rom_en <= '1';

bram1_a_en <= '1';
bram1_b_en <= '1';
            
bram1_a_we <= "0000";
bram1_b_we <= "0000";        
            
bram2_a_en <= '1';
bram2_b_en <= '1';
            
bram2_a_we <= "1111";
bram2_b_we <= "1111";

kernel_addr: process(k, sigma_size, sigma_center)
begin
    kernel_rom_addr <= std_logic_vector(TO_UNSIGNED(TO_INTEGER(k), log2c(KERNEL_ROM_SIZE)));
    dx <= sigma_center + k;
    dy <= sigma_center + k; 
end process;
x_add_proc: process(x)
begin
    x_add_2 <= x + TO_SIGNED(1, 16);
end process;

pix_proc: process(bram1_a_rdata, bram1_b_rdata, kernel_rom_data)
begin
    mul_reg_1 <= unsigned(bram1_a_rdata(2 *DATA_WIDTH -1 downto DATA_WIDTH)) * unsigned(kernel_rom_data);
    mul_reg_2 <= unsigned(bram1_a_rdata(DATA_WIDTH-1 downto 0)) * unsigned(kernel_rom_data);
    mul_reg_3 <= unsigned(bram1_b_rdata(2 *DATA_WIDTH -1 downto DATA_WIDTH)) * unsigned(kernel_rom_data);
    mul_reg_4 <= unsigned(bram1_b_rdata(DATA_WIDTH-1 downto 0)) * unsigned(kernel_rom_data);
end process;
                                 
end Mixed;
