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
    
    --CONVOLUTION DIRECTION
    HORIZONTAL: boolean := true;
    
    --PARAMETRS OF CONVOLUTION
    R_PIXEL: natural := 1;
    W_PIXEL: natural := 2;  
    
    --SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE : natural := 77; --FIXED 
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
    bram1_a_addr: out std_logic_vector(log2c(BRAM_SIZE/R_PIXEL) - 1 downto 0);
    bram1_a_rdata: in std_logic_vector(R_PIXEL *(DATA_WIDTH -1) -1 downto 0);
    bram1_b_en: out std_logic;
    bram1_b_we: out std_logic_vector(3 downto 0);
    bram1_b_addr: out std_logic_vector(log2c(BRAM_SIZE/R_PIXEL) - 1 downto 0);
    bram1_b_rdata: in std_logic_vector(R_PIXEL *(DATA_WIDTH -1) -1 downto 0);
    
    kernel_rom_en: out std_logic;
    kernel_rom_addr: out std_logic_vector(log2c(KERNEL_ROM_SIZE) - 1 downto 0);
    kernel_rom_data: in std_logic_vector(DATA_WIDTH -1 downto 0);
       
    bram2_a_en: out std_logic;
    bram2_a_we: out std_logic_vector(3 downto 0);
    bram2_a_addr: out std_logic_vector(log2c(BRAM_SIZE/W_PIXEL) - 1 downto 0);
    bram2_a_wdata: out std_logic_vector(W_PIXEL *(DATA_WIDTH -1) -1 downto 0);
    bram2_b_en: out std_logic;
    bram2_b_we: out std_logic_vector(3 downto 0);
    bram2_b_addr: out std_logic_vector(log2c(BRAM_SIZE/W_PIXEL) - 1 downto 0);
    bram2_b_wdata: out std_logic_vector(W_PIXEL *(DATA_WIDTH -1) -1 downto 0);
    
    ready : out std_logic
      
);
end convolute_loops;

architecture Mixed of convolute_loops is   

component dsp_unit_mac_shift 
    generic (WIDTH_IN: natural := 16;
             WIDTH_OUT:natural := 16 );
    port (clk: in std_logic;
          rst: in std_logic;
          in_1: in std_logic_vector(WIDTH_IN - 1 downto 0);
          in_2: in std_logic_vector(WIDTH_IN - 1 downto 0);
          in_3: in std_logic_vector(WIDTH_IN - 1 downto 0);
          out_res: out std_logic_vector(WIDTH_OUT - 1 downto 0)
          );
end component;
component dsp_unit_mul_shift 
    generic (WIDTH1: natural := 16;
             WIDTH2: natural := 16;
             SHIFT: natural := 14);
    port (clk: in std_logic;
          mul_valid: in std_logic;
          in_1: in std_logic_vector(WIDTH2 - 1 downto 0);
          in_2: in std_logic_vector(WIDTH1 - 1 downto 0);
          out_res: out std_logic_vector(WIDTH1 - 1 downto 0)
          );
end component;

signal x_reg, y_reg, k_reg, dy, dx : signed(DATA_WIDTH -1 downto 0);
signal x_next, y_next, k_next: signed(DATA_WIDTH - 1 downto 0);
signal c_y, c_x: unsigned(DATA_WIDTH -1 downto 0);
signal pix1, pix2, kernel_val: std_logic_vector(DATA_WIDTH -1 downto 0);
signal x1_coord, x2_coord, y_coord, c_x1_vec, c_x2_vec,  c_y_vec: std_logic_vector(DATA_WIDTH -1 downto 0);
signal sum1_reg, sum2_reg: unsigned(DATA_WIDTH -1  downto 0); 
signal sum1_next, sum2_next: unsigned(DATA_WIDTH - 1 downto 0);
signal mul_reg_1, mul_reg_2: std_logic_vector(DATA_WIDTH -1 downto 0);
signal sigma_center: signed(DATA_WIDTH/2 -1 downto 0);
signal img_w1, img_w2: std_logic_vector(DATA_WIDTH -1 downto 0);
signal valid_reg, valid_next: std_logic;
type state_t is (idle, loops, sum_calc, stal1, stal2, stal3, conv_end);
signal state_reg, state_next : state_t;

begin

sigma_center <= not('0' &signed(sigma_size(DATA_WIDTH/2 -1 downto 1))) + 1;                                    
next_state_process: process(clk, reset)

begin
    
    if (reset = '1') then
        state_reg <= idle;
        
        x_reg <= (others => '0');
        if HORIZONTAL = false then
            y_reg <= signed(img_offset_up);
        else
            y_reg <= (others => '0');
        end if;    
        k_reg <= (others => '0');
        
        sum1_reg <= (others => '0');
        sum2_reg <= (others => '0');
        valid_reg <= '0';
        
    elsif (rising_edge(clk) and reset = '0') then
        state_reg <= state_next;
    
        x_reg <= x_next;
        y_reg <= y_next;
        k_reg <= k_next; 
        
        sum1_reg <= sum1_next;
        sum2_reg <= sum2_next;
        
        valid_reg <= valid_next;
    end if;

end process;

combinational_logic_process: process(start, state_reg, state_next, sigma_size, x_reg, y_reg, k_reg, img_width, img_height, img_offset_up, img_offset_down, 
sum1_reg, sum2_reg, mul_reg_1, mul_reg_2, valid_reg) 
begin
    
    x_next <= x_reg;
    y_next <= y_reg;
    k_next <= k_reg;    
    
    sum1_next <= sum1_reg;
    sum2_next <= sum2_reg; 
    
    valid_next <= valid_reg;
                     
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
            if (HORIZONTAL = true and y_reg>= signed(img_height) - signed(img_offset_down) - signed(img_offset_up)) or (HORIZONTAL = false and y_reg>= signed(img_height) - signed(img_offset_down)) then             
                state_next <= conv_end;          
            elsif x_reg>= signed(img_width) then    
                y_next <= y_reg + 1; 
                x_next <= (others => '0');
                valid_next <= '0';
                state_next <= loops; 
                 
            elsif k_reg > signed(sigma_size)    then
                k_next <= (others => '0');          
                x_next <= x_reg + 2;     
                valid_next <= '0';              
                state_next <= stal2;                   
            else 
                state_next <= stal1;
            end if;
        when stal1 => 
                valid_next <= '1';
                state_next <= sum_calc;                
        when stal2 =>   
                state_next <= stal3;
        when stal3 => 
                sum1_next <= (others => '0');
                sum2_next <= (others => '0');
                state_next <= loops;             
        when sum_calc => 
                sum1_next <= sum1_reg + unsigned(mul_reg_1);   
                sum2_next <= sum2_reg + unsigned(mul_reg_2);
                k_next <= k_reg + 1;
                state_next <= loops; 
        when conv_end =>
                ready <= '1';
                state_next <= conv_end;                           
        when others => 
            state_next <= idle;
    
    end case;

end process;
               
    
read_address_coord_generation: process(x_reg, y_reg, k_reg, dx, dy, img_width, img_height, img_offset_up, img_offset_down)
begin
    dx <= sigma_center + k_reg;
    dy <= sigma_center + k_reg; 
    kernel_rom_addr <= std_logic_vector(TO_UNSIGNED(TO_INTEGER(k_reg), log2c(KERNEL_ROM_SIZE))); 

    if  HORIZONTAL = true then  
        if (x_reg + dx) < TO_SIGNED(0, 16)  then
            c_x <= (others => '0');
        elsif (x_reg + dx) >= signed(img_width) then 
            c_x <= unsigned(img_width) -1;
        else
            c_x <= unsigned(x_reg + dx);
        end if;
                                       
        c_y <= unsigned(y_reg);

    else
        if TO_INTEGER(signed(img_offset_down)) = 0 and TO_INTEGER(signed(img_offset_up)) = 0  then                    
            if  (y_reg + dy) < TO_SIGNED(0, 16)  then
                c_y <= (others => '0');                                   
            elsif (y_reg + dy) >= signed(img_height) then
                c_y <= unsigned(img_height) -1 ;                                   
            else
                c_y <= unsigned(y_reg + dy);
            end if;
        end if;
                    
        if TO_INTEGER(signed(img_offset_down)) /= 0 and TO_INTEGER(signed(img_offset_up)) /= 0  then
            if  (y_reg + dy) < signed(img_offset_up) then
                c_y <= unsigned(signed(img_offset_up) + dy);                           
            elsif (y_reg + dy) >= signed(img_height) - signed(img_offset_down) then
                c_y <= unsigned(signed(img_height) - signed(img_offset_down) + dy);
            else
                c_y <= unsigned(y_reg + dy);
            end if;
        end if;
                    
        if TO_INTEGER(signed(img_offset_down)) /= 0 and TO_INTEGER(signed(img_offset_up)) = 0  then                    
            if (y_reg + dy) < TO_SIGNED(0, 16)  then
                c_y <= (others => '0');                        
            elsif (y_reg + dy) >= signed(img_height) - signed(img_offset_down) then
                c_y <= unsigned(signed(img_height) - signed(img_offset_down) + dy);                                   
            else
                c_y <= unsigned(y_reg + dy);
            end if;
        end if;
                    
        if TO_INTEGER(signed(img_offset_down)) = 0 and TO_INTEGER(signed(img_offset_up)) /= 0  then
            if (y_reg + dy) < signed(img_offset_up) then
                c_y <= unsigned(signed(img_offset_up) + dy);                           
            elsif (y_reg + dy) >= signed(img_height) then
                c_y <= unsigned(img_height) -1 ;  
            else
                c_y <= unsigned(y_reg + dy);
            end if;
        end if;                      
        c_x <= unsigned(x_reg); 
                            
    end if; 

end process; 

address_generation: process(x_reg, y_reg, c_x, c_y, sum1_reg, sum2_reg, bram1_b_rdata, bram1_b_rdata, img_width, img_offset_up)
begin
    x2_coord <= std_logic_vector(x_reg);
    c_y_vec <= std_logic_vector(c_y);
    c_x1_vec <= std_logic_vector(c_x);
    pix2 <= '0'&bram1_b_rdata((DATA_WIDTH-1) -1 downto 0);

    if HORIZONTAL = true then
        bram2_b_wdata <= std_logic_vector(sum1_reg(DATA_WIDTH -2 downto 0)&sum2_reg(DATA_WIDTH -2 downto 0));
        bram2_a_wdata <= (others => '0');
        y_coord <= std_logic_vector(y_reg);
        x1_coord <= std_logic_vector(x_reg/2);
        c_x2_vec <= std_logic_vector(c_x + 1);
        pix1 <= '0'&bram1_a_rdata((DATA_WIDTH-1) -1 downto 0);
        img_w1 <= std_logic_vector(shift_right(unsigned(img_width), 1));
        img_w2 <= img_width;
    else
        bram2_b_wdata <= std_logic_vector(sum2_reg(DATA_WIDTH -2 downto 0));
        bram2_a_wdata <= std_logic_vector(sum1_reg(DATA_WIDTH -2 downto 0));
        y_coord <= std_logic_vector(y_reg- signed(img_offset_up));
        x1_coord <= std_logic_vector(x_reg + 1);
        c_x2_vec <= std_logic_vector(c_x/2);
        pix1 <= '0'&bram1_b_rdata(R_PIXEL *(DATA_WIDTH-1) -1 downto (DATA_WIDTH-1));
        img_w1 <= img_width;
        img_w2 <= std_logic_vector(shift_right(unsigned(img_width), 1));
    end if;

end process;
         
dsp_mul1: dsp_unit_mul_shift
generic map(WIDTH1 => DATA_WIDTH,
            WIDTH2 => DATA_WIDTH,
            SHIFT => 14)
port map( clk => clk,
          mul_valid => valid_reg,
          in_1 => pix1,
          in_2 => kernel_rom_data,
          out_res => mul_reg_1
          );

dsp_mul2: dsp_unit_mul_shift
generic map(WIDTH1 => DATA_WIDTH,
            WIDTH2 => DATA_WIDTH,
            SHIFT => 14)
port map( clk => clk,
          mul_valid => valid_reg,
          in_1 => pix2,
          in_2 => kernel_rom_data,
          out_res => mul_reg_2
          );

addr_b_gen_1: dsp_unit_mac_shift
generic map(WIDTH_IN => DATA_WIDTH,
            WIDTH_OUT => log2c(BRAM_SIZE/R_PIXEL)
            )
port map( clk => clk,
          rst => reset,
          in_1 => c_y_vec,
          in_2 => img_w2,
          in_3 => c_x2_vec,
          out_res => bram1_b_addr
          );              
          
                 
addr_b_gen_2: dsp_unit_mac_shift
generic map(WIDTH_IN => DATA_WIDTH,
            WIDTH_OUT => log2c(BRAM_SIZE/W_PIXEL)
            )
port map( clk => clk,
          rst => reset,
          in_1 => y_coord,
          in_2 => img_w1,
          in_3 => x1_coord,
          out_res => bram2_b_addr
          ); 
          
addr_a_gen_2: if HORIZONTAL = false generate

dsp2: dsp_unit_mac_shift
generic map(WIDTH_IN => DATA_WIDTH,
            WIDTH_OUT => log2c(BRAM_SIZE)
            )
port map( clk => clk,
          rst => reset,
          in_1 => y_coord,
          in_2 => img_w1,
          in_3 => x2_coord,
          out_res => bram2_a_addr
          ); 
           
end generate;

addr_a_gen_1: if HORIZONTAL = true generate

dsp1:dsp_unit_mac_shift
generic map(WIDTH_IN => DATA_WIDTH,
            WIDTH_OUT => log2c(BRAM_SIZE)
            )
port map( clk => clk,
          rst => reset,
          in_1 => c_y_vec,
          in_2 => img_w2,
          in_3 => c_x1_vec,
          out_res => bram1_a_addr
          ); 
           
end generate;    

--CONSTANTS------------------------------------
kernel_rom_en <= '1';

bram1_b_en <= '1';
            
bram1_b_we <= "0000";        
            
bram2_b_en <= '1';
            
bram2_b_we <= "1111";


bram1_a_en <= '1' ;
            
bram1_a_we <= "0000";        
            
bram2_a_en <= '1' ;
            
bram2_a_we <= "1111" ;
------------------------------------------------

end Mixed;
