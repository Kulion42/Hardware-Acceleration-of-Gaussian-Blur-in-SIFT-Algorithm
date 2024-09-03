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
    
    --IMAGE ELEMENTS
    IMG_WIDTH : natural := 450; -- VARIABLE 
    IMG_HEIGHT : natural := 100; -- VARIABLE 
    IMG_OFFSET_UP : natural := 10; -- VARIABLE 
    IMG_OFFSET_DOWN : natural := 10; -- VARIABLE 
    SIGMA_SIZE : natural := 19; --VARIABLE -- ALWAYS ODD -- MAX = KERNEL_BRAM_SIZE
    SIGMA_CENTER: natural := 10; --VARIABLE --ROUND(SIGMA_SIZE/2)
    
    --DIRECTION OF CONVOLUTION
    HORIZONTAL: boolean := true;
    
    --SIZE OF BRAMS
    KERNEL_BRAM_SIZE : natural := 20; --FIXED 
    BRAM1_SIZE : natural := 60000; --FIXED
    BRAM2_SIZE : natural := 59980 -- FIXED
);
Port ( 
    clk : in std_logic;
    reset: in std_logic;
    start: in std_logic;
    
    bram1_a_en: out std_logic;
    bram1_a_we: out std_logic_vector(3 downto 0);
    bram1_a_raddr: out std_logic_vector(log2c(BRAM1_SIZE) - 1 downto 0);
    bram1_a_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0); 
    
    bram1_b_en: out std_logic;
    bram1_b_we: out std_logic_vector(3 downto 0);
    bram1_b_raddr: out std_logic_vector(log2c(BRAM1_SIZE) - 1 downto 0);
    bram1_b_rdata: in std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    kernel_bram_en: out std_logic;
    kernel_bram_we: out std_logic_vector(3 downto 0);
    kernel_bram_raddr: out std_logic_vector(log2c(KERNEL_BRAM_SIZE) - 1 downto 0);
    kernel_bram_rdata: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    
    bram2_a_en: out std_logic;
    bram2_a_we: out std_logic_vector(3 downto 0);
    bram2_a_waddr: out std_logic_vector(log2c(BRAM2_SIZE) - 1 downto 0);
    bram2_a_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    bram2_b_en: out std_logic;
    bram2_b_we: out std_logic_vector(3 downto 0);
    bram2_b_waddr: out std_logic_vector(log2c(BRAM2_SIZE) - 1 downto 0);
    bram2_b_wdata: out std_logic_vector(2 *DATA_WIDTH -1 downto 0);
    
    ready : out std_logic
      
);
end convolute_loops;

architecture Mixed of convolute_loops is
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
signal x_next, y_next, k_next, dx_next, dy_next, c_y_next, c_x1_next, c_x2_next : signed(DATA_WIDTH - 1 downto 0);
signal pix1, pix2, pix3, pix4: unsigned(DATA_WIDTH -1 downto 0);
signal val1: unsigned(DATA_WIDTH -1 downto 0);
signal sum1_reg, sum2_reg, sum3_reg, sum4_reg: std_logic_vector(DATA_WIDTH -1  downto 0); 
signal sum1_next, sum2_next, sum3_next, sum4_next: std_logic_vector(DATA_WIDTH - 1 downto 0);

signal img_w : signed(DATA_WIDTH -1 downto 0) := TO_SIGNED(IMG_WIDTH, DATA_WIDTH);
signal img_h : signed(DATA_WIDTH -1 downto 0) := TO_SIGNED(IMG_HEIGHT, DATA_WIDTH);
signal img_off_up : signed(DATA_WIDTH -1 downto 0) := TO_SIGNED(IMG_OFFSET_UP, DATA_WIDTH);
signal img_off_down : signed(DATA_WIDTH -1 downto 0) := TO_SIGNED(IMG_OFFSET_DOWN, DATA_WIDTH);
signal sigma_s : signed(DATA_WIDTH -1 downto 0) := TO_SIGNED(SIGMA_SIZE, DATA_WIDTH);
signal sigma_c : signed(DATA_WIDTH -1 downto 0) := TO_SIGNED(-SIGMA_CENTER, DATA_WIDTH);

type state_t is (idle, loops_start, x_loop_end, y_loop_end, k_loop_end, x_addr_gen, y_addr_gen, bram_read_1, bram_read_2, bram_write);
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
                              
next_state_process: process(clk, reset) is

begin
    
    if (reset = '1') then
        state_reg <= idle;
        
        x <= (others => '0');
        y <= TO_SIGNED(IMG_OFFSET_UP, 16);
        k <= (others => '0');
        
        dx <= (others => '0');
        dy <= (others => '0');
        
        c_y <= (others => '0');
        c_x1 <= (others => '0');
        c_x2 <= (others => '0');
        
        sum1_reg <= (others => '0');
        sum2_reg <= (others => '0');
        sum3_reg <= (others => '0');
        sum4_reg <= (others => '0');
    
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
        
        sum1_reg <= sum1_next;
        sum2_reg <= sum2_next;
        sum3_reg <= sum3_next;
        sum4_reg <= sum4_next;   
    
    end if;

end process;

combinational_logic_process: process(start, state_reg, state_next, img_w, img_h, img_off_up, img_off_down, sigma_s, sigma_c, x, x_next, y, y_next, k, k_next, dx, dy, dx_next, dy_next, c_x1, c_x2, c_y, 
val1, pix1, pix2, pix3, pix4, sum1_reg, sum2_reg, sum3_reg, sum4_reg, sum1_next, sum2_next, sum3_next, sum4_next, kernel_bram_rdata, bram1_a_rdata, bram1_b_rdata) is

begin
    kernel_bram_en <= '1';
    kernel_bram_we <= "0000";
    kernel_bram_raddr <= (others => '0');
    
    bram1_a_en <= '1';
    bram1_a_we <= (others => '0');
    bram1_a_raddr <= (others => '0');
    
    bram1_b_en <= '1';
    bram1_b_we <= (others => '0');
    bram1_b_raddr <= (others => '0');
    
    bram2_a_en <= '1';
    bram2_a_we <= (others => '1');
    bram2_a_waddr <= (others => '0');
    bram2_a_wdata <= (others => '0');
    
    bram2_b_en <= '1';
    bram2_b_we <= (others => '1');
    bram2_b_waddr <= (others => '0');
    bram2_b_wdata <= (others => '0');
    
    val1 <= (others => '0');
    
    pix1 <= (others => '0');
    pix2 <= (others => '0');
    pix3 <= (others => '0');
    pix4 <= (others => '0');
    
    x_next <= x;
    y_next <= y;
    k_next <= k;
    
    c_y_next <= c_y; 
    c_x1_next <= c_x1;
    c_x2_next <= c_x2;
        
    dx_next <= dx;
    dy_next <= dy;
    
    sum1_next <= sum1_reg;
    sum2_next <= sum2_reg;
    sum3_next <= sum3_reg;
    sum4_next <= sum4_reg;
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
            if x>= img_w then
                ready <= '1';
                state_next <= x_loop_end;
            
            elsif (HORIZONTAL = false and y>= img_h - img_off_down) or (HORIZONTAL = true and y>= img_h - img_off_up-img_off_down) then
         
                state_next <= y_loop_end;   
        
            elsif k>= sigma_s then   
                
                state_next <= k_loop_end;
                         
            else
                if HORIZONTAL = true then
                    dx_next <= sigma_c +k;
                    state_next <= x_addr_gen;
                else 
                    dy_next <= sigma_c +k;
                    state_next <= y_addr_gen;
                end if;
            
            end if; 
        when x_addr_gen =>
            if x < dx  then
                c_x1_next <= (others => '0');
            elsif x + dx > img_w then 
                c_x1_next <= img_w -1;
            else
                c_x1_next <= x + dx;
            end if;
            
            if x + 2 < dx then
                c_x2_next <= (others => '0');
            elsif x + dx + 2 > img_w then 
                c_x2_next <= img_w -1;
            else
                c_x2_next <= x + dx + 2;
            end if;
            
            c_y_next <= y;
            state_next <= bram_read_1;
          
        when y_addr_gen =>
            if y < dy  and IMG_OFFSET_UP = 0 then
                        c_y_next <= (others => '0');
                        
            elsif y+dy < img_off_up and IMG_OFFSET_UP = 10 then
                        c_y_next <= img_off_up + dy;
                        
            elsif y+dy >= img_h and IMG_OFFSET_DOWN = 0 then
                        c_y_next <= img_h -1 ;
                        
            elsif y+dy >= img_h - img_off_down and IMG_OFFSET_DOWN = 10 then
                        c_y_next <= img_h -img_off_down + dy;
                            
            else
                        c_y_next <= y + dy;
            end if;
            
            c_x1_next <= x; 
            c_x2_next <= x + 2;    
            state_next <= bram_read_1;
        
        when bram_read_1 =>
            
            kernel_bram_raddr <= std_logic_vector(TO_UNSIGNED(TO_INTEGER(k), 5));
            bram1_a_raddr <= std_logic_vector(TO_UNSIGNED(TO_INTEGER(c_y * IMG_WIDTH + c_x1), 16));
            bram1_b_raddr <= std_logic_vector(TO_UNSIGNED(TO_INTEGER(c_y * IMG_WIDTH + c_x2), 16));
                       
            bram1_a_we <= "0000";
            bram1_b_we <= "0000";
            state_next <= bram_read_2;
        
        when bram_read_2 =>
            val1 <= unsigned(kernel_bram_rdata(DATA_WIDTH -1 downto 0));
            
            pix1 <= unsigned(bram1_a_rdata(2 * DATA_WIDTH -1 downto DATA_WIDTH));
            pix2 <= unsigned(bram1_a_rdata(DATA_WIDTH -1  downto 0));
            pix3 <= unsigned(bram1_b_rdata(2 * DATA_WIDTH -1 downto DATA_WIDTH));
            pix4 <= unsigned(bram1_b_rdata(DATA_WIDTH -1 downto 0));
            
            state_next <= bram_write;
           
        when bram_write =>
            
            bram2_a_we <= "1111";
            bram2_b_we <= "1111";
            
            bram2_a_waddr <= std_logic_vector(TO_UNSIGNED(TO_INTEGER(y * IMG_WIDTH + x), 16));
            bram2_b_waddr <= std_logic_vector(TO_UNSIGNED(TO_INTEGER(y * IMG_WIDTH + x + 2), 16));
            
            bram2_a_wdata <= sum1_reg&sum2_reg;
            bram2_b_wdata <= sum3_reg&sum4_reg;
            
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
        
        
        when x_loop_end =>
            state_next <= idle;
           
        
        when others => 
            state_next <= idle;
    
    end case;

end process;

end Mixed;
