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
signal x, y, k, dy, dx : signed(DATA_WIDTH -1 downto 0);
signal x_add_2, x_add_1_next: signed(DATA_WIDTH - 1 downto 0);
signal x_next, y_next, k_next: signed(DATA_WIDTH - 1 downto 0);
signal pix1, pix2, pix3, pix4, c_y, c_x1, c_x2, c_y_next, c_x1_next, c_x2_next : unsigned(DATA_WIDTH -1 downto 0);
--signal val, val_next: unsigned(DATA_WIDTH -1 downto 0);
signal sum1_reg, sum2_reg, sum3_reg, sum4_reg: unsigned(DATA_WIDTH -1  downto 0); 
signal sum1_next, sum2_next, sum3_next, sum4_next: unsigned(DATA_WIDTH - 1 downto 0);
signal mul_reg_1, mul_reg_2, mul_reg_3, mul_reg_4: unsigned(2 *DATA_WIDTH -1 downto 0);
signal sigma_center: signed(DATA_WIDTH/2 -1 downto 0);
signal addr1_a, addr1_b, addr2_a, addr2_b: unsigned(2 * log2c(BRAM_SIZE) - 1 downto 0);
type state_t is (idle, loops, sum_calc, stal1, stal2, stal3);
signal state_reg, state_next : state_t;

begin

sigma_center <= not('0' &signed(sigma_size(DATA_WIDTH/2 -1 downto 1))) + 1;                                    
next_state_process: process(clk, reset) is

begin
    
    if (reset = '1') then
        state_reg <= idle;
        
        x <= (others => '0');
        y <= (others => '0');
        k <= (others => '0');
        
        c_x1 <= (others => '0'); 
        c_x2 <= TO_UNSIGNED(1, 16); 
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
      
    kernel_rom_addr <= std_logic_vector(TO_UNSIGNED(TO_INTEGER(k), log2c(KERNEL_ROM_SIZE)));
    dx <= sigma_center + k;
    dy <= sigma_center + k; 
              
    ready <= '0';
                
    case state_reg is 
    
        when idle =>
            if start = '1' then
                state_next <= loops;
                                  
            else 
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
                        c_x1_next <= unsigned(img_width) -1;
                    else
                        c_x1_next <= unsigned(x + dx);
                    end if;
                    
                    if abs(dx) > x_add_2 then
                        c_x2_next <= (others => '0');
                    elsif x_add_2 + dx >= signed(img_width) then 
                        c_x2_next <= unsigned(img_width) -1;
                    else
                        c_x2_next <= unsigned(x_add_2 + dx);
                    end if;
                    
                    c_y_next <= unsigned(y);

                else                     
                    if abs(dy) > y  and TO_INTEGER(signed(img_offset_up)) = 0  then
                        c_y_next <= (others => '0');
                        
                    elsif dy < 0 and y + dy < signed(img_offset_up) and TO_INTEGER(signed(img_offset_up)) = 10 then
                        c_y_next <= unsigned(signed(img_offset_up) + dy);
                                
                    elsif y + dy >= signed(img_height) and TO_INTEGER(signed(img_offset_down)) = 0 then
                        c_y_next <= unsigned(img_height) -1 ;
                                
                    elsif y + dy >= signed(img_height) and TO_INTEGER(signed(img_offset_down)) = 10 then
                        c_y_next <= unsigned(signed(img_height) - signed(img_offset_down) + dy);
                                    
                    else
                        c_y_next <= unsigned(y + dy);
                    end if;
                    
                    c_x1_next <= unsigned(x); 
                    c_x2_next <= unsigned(x_add_2);

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
                sum1_next <= sum1_reg + mul_reg_1(DATA_WIDTH -1 downto 0);    
                sum2_next <= sum2_reg + mul_reg_2(DATA_WIDTH -1 downto 0);   
                sum3_next <= sum3_reg + mul_reg_3(DATA_WIDTH -1 downto 0);   
                sum4_next <= sum4_reg + mul_reg_4(DATA_WIDTH -1 downto 0);               
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

end process;
x_add_proc: process(x, reset)
begin
    x_add_2 <= x + TO_SIGNED(1, 16) when reset = '0'
               else TO_SIGNED(1, 16);
end process;

pix_proc: process(kernel_rom_data)
begin
    mul_reg_1 <= shift_right(unsigned(bram1_a_rdata(2 *DATA_WIDTH -1 downto DATA_WIDTH)) * unsigned(kernel_rom_data), 14);
    mul_reg_2 <= shift_right(unsigned(bram1_a_rdata(DATA_WIDTH-1 downto 0)) * unsigned(kernel_rom_data), 14);
    mul_reg_3 <= shift_right(unsigned(bram1_b_rdata(2 *DATA_WIDTH -1 downto DATA_WIDTH)) * unsigned(kernel_rom_data), 14);
    mul_reg_4 <= shift_right(unsigned(bram1_b_rdata(DATA_WIDTH-1 downto 0)) * unsigned(kernel_rom_data), 14);
end process;

addr_gen_proc: process(x,y, c_y, c_x1, c_x2, x_add_2, img_width)
begin
addr1_a <= c_y * unsigned(img_width) + c_x1;
addr1_b <= c_y * unsigned(img_width) + c_x2;
addr2_a <= unsigned(y * signed(img_width) + x);
addr2_b <= unsigned(y * signed(img_width) + x_add_2);

end process;    

bram1_a_addr <= std_logic_vector(addr1_a(DATA_WIDTH -1 downto 0));                                
bram1_b_addr <= std_logic_vector(addr1_b(DATA_WIDTH -1 downto 0));                                
bram2_a_addr <= std_logic_vector(addr2_a(DATA_WIDTH -1 downto 0));                               
bram2_b_addr <= std_logic_vector(addr2_b(DATA_WIDTH -1 downto 0));                             




end Mixed;
