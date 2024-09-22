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
    img_per_octave: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    sigma_size : in std_logic_vector(DATA_WIDTH/2 -1 downto 0);
    
    bram1_a_en: out std_logic;
    bram1_a_we: out std_logic_vector(3 downto 0);
    bram1_a_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram1_a_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    bram1_a_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);  
    
    bram1_b_en: out std_logic;
    bram1_b_we: out std_logic_vector(3 downto 0);
    bram1_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram1_b_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    bram1_b_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    kernel_rom_en: out std_logic;
    kernel_rom_addr: out std_logic_vector(log2c(KERNEL_ROM_SIZE) - 1 downto 0);
    kernel_rom_data: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    
    bram2_a_en: out std_logic;
    bram2_a_we: out std_logic_vector(3 downto 0);
    bram2_a_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram2_a_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    bram2_a_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    bram2_b_en: out std_logic;
    bram2_b_we: out std_logic_vector(3 downto 0);
    bram2_b_addr: out std_logic_vector(log2c(BRAM_SIZE) - 1 downto 0);
    bram2_b_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    bram2_b_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    ready : out std_logic
      
);
end convolute_loops;

architecture Mixed of convolute_loops is
    attribute use_dsp : string;
    attribute use_dsp of Mixed : architecture is "yes";
    
component dsp_unit_mac_shift is
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
signal x_add_1, x_add_1_next: signed(DATA_WIDTH - 1 downto 0);
signal x_next, y_next, k_next, dx_next, dy_next, c_y_next, c_x1_next, c_x2_next : signed(DATA_WIDTH - 1 downto 0);
signal pix1, pix2, pix3, pix4: unsigned(DATA_WIDTH -1 downto 0);
signal val1: unsigned(DATA_WIDTH -1 downto 0);
signal sum1_reg, sum2_reg, sum3_reg, sum4_reg: std_logic_vector(DATA_WIDTH -1  downto 0); 
signal sum1_next, sum2_next, sum3_next, sum4_next: std_logic_vector(DATA_WIDTH - 1 downto 0);
signal addr_a_b1, addr_b_b1, addr_a_b2, addr_b_b2: std_logic_vector(DATA_WIDTH -1 downto 0);


type state_t is (idle, loops_start, y_loop_end, k_loop_end, x_addr_gen, y_addr_gen, bram_read_1, bram_read_2);
signal state_reg, state_next : state_t;

begin


 mac1: dsp_unit_mac_shift
    generic map(
         WIDTH1 => DATA_WIDTH,
         WIDTH2 => DATA_WIDTH,
         WIDTH3 => DATA_WIDTH)
    port map(
         clk => clk,
         rst => reset,
         in_1 => std_logic_vector(pix1),
         in_2 => std_logic_vector(val1),
         in_3 => sum1_reg,
         out_res => sum1_next
         );
         
mac2: dsp_unit_mac_shift
    generic map(
         WIDTH1 => DATA_WIDTH,
         WIDTH2 => DATA_WIDTH,
         WIDTH3 => DATA_WIDTH)
    port map(
         clk => clk,
         rst => reset,
         in_1 => std_logic_vector(pix2),
         in_2 => std_logic_vector(val1),
         in_3 => sum2_reg,
         out_res => sum2_next
         );

mac3: dsp_unit_mac_shift
    generic map(
         WIDTH1 => DATA_WIDTH,
         WIDTH2 => DATA_WIDTH,
         WIDTH3 => DATA_WIDTH)
    port map(
         clk => clk,
         rst => reset,
         in_1 => std_logic_vector(pix3),
         in_2 => std_logic_vector(val1),
         in_3 => sum3_reg,
         out_res => sum3_next
         );    
         
mac4: dsp_unit_mac_shift
    generic map(
         WIDTH1 => DATA_WIDTH,
         WIDTH2 => DATA_WIDTH,
         WIDTH3 => DATA_WIDTH)
    port map(
         clk => clk,
         rst => reset,
         in_1 => std_logic_vector(pix4),
         in_2 => std_logic_vector(val1),
         in_3 => sum4_reg,
         out_res => sum4_next
         );
addr_gen_1 : dsp_unit_mac_shift
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
         out_res => addr_a_b1
         );
addr_gen_2 : dsp_unit_mac_shift
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
         out_res => addr_b_b1
         );    
addr_gen_3 : dsp_unit_mac_shift
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
         out_res => addr_a_b2
         );    
addr_gen_4 : dsp_unit_mac_shift
    generic map(
         WIDTH1 => DATA_WIDTH,
         WIDTH2 => DATA_WIDTH,
         WIDTH3 => DATA_WIDTH)
    port map(
         clk => clk,
         rst => reset,
         in_1 => std_logic_vector(y),
         in_2 => img_width,
         in_3 => std_logic_vector(x_add_1),
         out_res => addr_b_b2
         );                                     
next_state_process: process(clk, reset) is

begin
    
    if (reset = '1') then
        state_reg <= idle;
        
        x <= (others => '0');
        y <= (others => '0');
        k <= (others => '0');
        
        dx <= (others => '0');
        dy <= (others => '0');
        
        c_y <= (others => '0');
        c_x1 <= (others => '0');
        c_x2 <= (others => '0');
        
        x_add_1 <= (others => '0');
        
        --sum1_reg <= (others => '0');
        --sum2_reg <= (others => '0');
        --sum3_reg <= (others => '0');
        --sum4_reg <= (others => '0');
    
    elsif (rising_edge(clk) and reset = '0') then
        state_reg <= state_next;
    
        x <= x_next;
        y <= y_next;
        k <= k_next;
               
        dx <= dx_next;
        dy <= dy_next;
        
        c_y <= c_y_next; 
        c_x1 <= c_x1_next ;
        c_x2 <= c_x2_next ;
        
        x_add_1 <= x_add_1_next;
        
        --sum1_reg <= sum1_next;
        --sum2_reg <= sum2_next;
        --sum3_reg <= sum3_next;
        --sum4_reg <= sum4_next;   
    
    end if;

end process;

combinational_logic_process: process(start, state_reg, state_next, img_width, img_height, img_offset_up, img_offset_down, sigma_size, x, x_next, y, y_next, k, k_next, dx, dy, dx_next, dy_next, c_x1, c_x2, c_y, 
val1, pix1, pix2, pix3, pix4, kernel_rom_data, bram1_a_rdata, bram1_b_rdata) is

begin
   
    kernel_rom_en <= '1';
    
    x_next <= x;
    y_next <= y;
    k_next <= k;
    
    c_y_next <= c_y; 
    c_x1_next <= c_x1;
    c_x2_next <= c_x2;
    
    x_add_1_next <= x_add_1;
        
    dx_next <= dx;
    dy_next <= dy;
    
    pix1 <= (others => '0');
    pix2 <= (others => '0');
    pix3 <= (others => '0');
    pix4 <= (others => '0');
    
    val1 <= (others => '0');
    
    kernel_rom_addr <= (others => '0');
    
    ready <= '0';
    
                
    case state_reg is 
    
        when idle =>
            if start = '1' then
                state_next <= loops_start;
                                  
            elsif start = '0' then 
                ready <= '1';           
                state_next <= idle;
            end if;
            
        when loops_start =>
            if x>= signed(img_width) then
                state_next <= idle;
            
            elsif (HORIZONTAL = false and y>= signed(img_height) - signed(img_offset_down)) or (HORIZONTAL = true and y>= signed(img_height) - signed(img_offset_down)) then
         
                state_next <= y_loop_end;   
        
            elsif k>= signed(sigma_size) then   
                
                state_next <= k_loop_end;
                         
            else
                if HORIZONTAL = true then
                    dx_next <= signed('0' &sigma_size(DATA_WIDTH/2 -1 downto 1)) +k;
                    x_add_1_next <= x + TO_SIGNED(1, 16);
                    state_next <= x_addr_gen;
                else 
                    dy_next <= signed('0' &sigma_size(DATA_WIDTH/2 -1 downto 1)) +k;
                    x_add_1_next <= x + TO_SIGNED(1, 16);
                    state_next <= y_addr_gen;
                end if;
            end if; 
        when x_addr_gen =>
            if x < dx  then
                c_x1_next <= (others => '0');
            elsif x + dx > signed(img_width) then 
                c_x1_next <= signed(img_width) -1;
            else
                c_x1_next <= x + dx;
            end if;
            
            if x + 2 < dx then
                c_x2_next <= (others => '0');
            elsif x_add_1 + dx > signed(img_width) then 
                c_x2_next <= signed(img_width) -1;
            else
                c_x2_next <= x_add_1 + dx;
            end if;
            
            c_y_next <= y;
            state_next <= bram_read_1;
          
        when y_addr_gen =>
            if y < dy  and TO_INTEGER(signed(img_offset_up)) = 0  then
                        c_y_next <= (others => '0');
                        
            elsif y+dy < signed(img_offset_up) and TO_INTEGER(signed(img_offset_up)) = 10 then
                        c_y_next <= signed(img_offset_up) + dy;
                        
            elsif y+dy >= signed(img_height) and TO_INTEGER(signed(img_offset_down)) = 0 then
                        c_y_next <= signed(img_height) -1 ;
                        
            elsif y+dy >= signed(img_height) and TO_INTEGER(signed(img_offset_down)) = 10 then
                        c_y_next <= signed(img_height) - signed(img_offset_down) + dy;
                            
            else
                        c_y_next <= y + dy;
            end if;
            
            c_x1_next <= x; 
            c_x2_next <= x_add_1;
            kernel_rom_en <= '1';  
            kernel_rom_addr <= std_logic_vector(TO_UNSIGNED(TO_INTEGER(k), log2c(KERNEL_ROM_SIZE)));  
            state_next <= bram_read_1;
        
        when bram_read_1 =>
                       
            state_next <= bram_read_2;
        
        when bram_read_2 =>
            val1 <= unsigned(kernel_rom_data);
            
            pix1 <= unsigned(bram1_a_rdata(2 * DATA_WIDTH -1 downto DATA_WIDTH));
            pix2 <= unsigned(bram1_a_rdata(DATA_WIDTH -1  downto 0));
            pix3 <= unsigned(bram1_b_rdata(2 * DATA_WIDTH -1 downto DATA_WIDTH));
            pix4 <= unsigned(bram1_b_rdata(DATA_WIDTH -1 downto 0));
            
            k_next <= k + 1;
            state_next <= loops_start;
            
        when k_loop_end =>
            
            k_next <= (others => '0');
            y_next <= y + 1;
            state_next <= loops_start;       
        
        when y_loop_end =>
            y_next <= (others => '0');
            x_next <= x + 4;
            state_next <= loops_start;
            
        when others => 
            state_next <= idle;
    
    end case;

end process;
            bram1_a_en <= '1';
            bram1_b_en <= '1';
            
            bram1_a_we <= "0000";
            bram1_a_we <= "0000";        
            
            bram2_a_en <= '1';
            bram2_b_en <= '1';
            
            bram2_a_we <= "1111";
            bram2_b_we <= "1111";
            
            sum1_reg <= (others => '0') when k < k_next
                         else sum1_next;
            sum2_reg <= (others => '0') when k < k_next
                         else sum2_next;
            sum3_reg <= (others => '0') when k < k_next
                         else sum3_next;             
            sum4_reg <= (others => '0') when k < k_next
                         else sum4_next;
            
            bram1_a_addr <= addr_a_b1 when state_reg = bram_read_1
                            else (others => '0');
            bram1_b_addr <= addr_b_b1 when state_reg = bram_read_1
                            else (others => '0');
            
            bram2_a_addr <= addr_a_b2 when state_reg = k_loop_end
                            else (others => '0');
            bram2_b_addr <= addr_b_b2 when state_reg = k_loop_end
                            else (others => '0');
            
            bram2_a_wdata <= sum1_reg&sum2_reg when state_reg = k_loop_end
                            else (others => '0');
            bram2_b_wdata <= sum3_reg&sum4_reg when state_reg = k_loop_end
                            else (others => '0');
end Mixed;
