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
    -- WIDTH OF DATA
    DATA_WIDTH : natural := 16;
    
    -- CONVOLUTION DIRECTION
    HORIZONTAL: boolean := true;
    
    -- PARAMETRS OF CONVOLUTION
    -- This parameter is used to distinguish which BRAM is 16 and which is 32 bit (Read/Write)
    R_PIXEL: natural := 1;
    W_PIXEL: natural := 2;  
    
    -- SIZE OF BRAMS AND ROM
    KERNEL_ROM_SIZE : natural := 77;
    BRAM_SIZE : natural := 60000
);
Port ( 

    clk : in std_logic;
    reset: in std_logic;
    start: in std_logic;
    
    -- IMAGE ELEMENTS
    img_height: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_width: in std_logic_vector(DATA_WIDTH -1 downto 0);
    img_offset_up: in std_logic_vector(DATA_WIDTH -1 downto 0); 
    img_offset_down: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    -- Value we get from Kernel ROM depending on Img Per Octave parameter
    sigma_size : in std_logic_vector(DATA_WIDTH/2 -1 downto 0);

    -- Kernel ROM is used to store sigma values
    kernel_rom_en: out std_logic;
    kernel_rom_addr: out std_logic_vector(log2c(KERNEL_ROM_SIZE) - 1 downto 0);
    kernel_rom_data: in std_logic_vector(DATA_WIDTH -1 downto 0);
    
    -- BRAM 1 is input BRAM, where we read input pixels from
    -- For Vertical convolution, this is Main BRAM, for horizontal, this is Tmp BRAM
    bram1_a_en: out std_logic;
    bram1_a_we: out std_logic_vector(3 downto 0);
    bram1_a_addr: out std_logic_vector(log2c(BRAM_SIZE/R_PIXEL) - 1 downto 0);
    bram1_a_rdata: in std_logic_vector(R_PIXEL *(DATA_WIDTH -1) -1 downto 0);
    bram1_b_en: out std_logic;
    bram1_b_we: out std_logic_vector(3 downto 0);
    bram1_b_addr: out std_logic_vector(log2c(BRAM_SIZE/R_PIXEL) - 1 downto 0);
    bram1_b_rdata: in std_logic_vector(R_PIXEL *(DATA_WIDTH -1) -1 downto 0);
    
    -- BRAM 2 is output BRAM, where we send pixels to
    -- For Vertical convolution, this is Tmp BRAM, for horizontal, this is Main BRAM
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

-- DSP Mac operation unit. Used for Address generating.
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

-- DSP Mul Shift operation unit. Used for Sum calculations.
component dsp_unit_mul_shift 
    generic (WIDTH1: natural := 16;
             WIDTH2: natural := 16;
             SHIFT: natural := 15);
    port (clk: in std_logic;
          mul_valid: in std_logic;
          in_1: in std_logic_vector(WIDTH2 - 1 downto 0);
          in_2: in std_logic_vector(WIDTH1 - 1 downto 0);
          out_res: out std_logic_vector(WIDTH1 - 1 downto 0)
          );
end component;

-- Variables used to calculate address
signal x_reg, y_reg, k_reg, dy, dx : signed(DATA_WIDTH -1 downto 0);

-- Register helper variables
signal x_next, y_next, k_next: signed(DATA_WIDTH - 1 downto 0);

-- Variables to store initial calculated address
signal c_y, c_x: unsigned(DATA_WIDTH -1 downto 0);

-- Read values of pixels and kernel value
signal pix1, pix2, kernel_val: std_logic_vector(DATA_WIDTH -1 downto 0);

-- Final calculated address for both read and write. _coord values are used for write, _vec values are used for read.
signal x1_coord, x2_coord, y_coord, c_x1_vec, c_x2_vec,  c_y_vec: std_logic_vector(DATA_WIDTH -1 downto 0);

-- Values to be written to BRAMs
signal sum1_reg, sum2_reg: unsigned(DATA_WIDTH -1  downto 0); 
signal sum1_next, sum2_next: unsigned(DATA_WIDTH - 1 downto 0);

-- Output of dsp mul units. Used to calculate sum1 and sum2.
signal mul_reg_1, mul_reg_2: std_logic_vector(DATA_WIDTH -1 downto 0);

-- Sigma center value used to loop through kernel values.
signal sigma_center: signed(DATA_WIDTH/2 -1 downto 0);

-- Helper variables used to calculate address. For Tmp Bram = width, For Main BRAM = width/2.
signal img_w1, img_w2: std_logic_vector(DATA_WIDTH -1 downto 0);

-- Valid register used for dsp mul modules to destinguish if input is valid.
signal valid_reg, valid_next: std_logic;

-- FSM state and register values.
type state_t is (idle, loops, sum_calc, stal1, stal2, stal3);
signal state_reg, state_next : state_t;

begin

-- Calculate center as sigma_size/2 and 2nd complement so we get negative value
sigma_center <= not('0' &signed(sigma_size(DATA_WIDTH/2 -1 downto 1))) + 1;

-- Registers process
next_state_process: process(clk, reset)
begin
    if (reset = '1') then
        state_reg <= idle;
        
        x_reg <= (others => '0');
        y_reg <= (others => '0');   
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

-- FSM process
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
        -- In idle state, FSM is waiting for ready signal
        when idle =>
            if start = '1' then
                state_next <= loops;                                               
            else
                ready <= '1'; 
                if HORIZONTAL = false then
                    y_next <= signed(img_offset_up);
                else
                    y_next <= (others => '0');
                end if;                                                                 
                state_next <= idle;
            end if;

        -- In loops state, FSM is checking all 3 loops (y, x, k)
        -- If y loop is finished, convolution is finished and move to the idle state (Ranges were calculated as a part of goto)
        -- If x loop is finished, y++, x=0, and move back to loops state (y for loop, next iteration)
        -- If k loop is finished, x+=2, k=0, and move to stal2->stal3 states (After these states, back to x loop, next iteration)
        -- If none of these conditions are met, move to stal1 state (Regular flow of pixel calculation)
        when loops =>           
            if (HORIZONTAL = true and y_reg>= signed(img_height) - signed(img_offset_down) - signed(img_offset_up)) or (HORIZONTAL = false and y_reg>= signed(img_height) - signed(img_offset_down)) then             
                y_next <= (others => '0');
                state_next <= idle;          
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

        -- stal1 state is necessary because dsp mac unit generates read address for pix1 and pix2
        -- We need to wait fo that address to be ready, pixels to be read so we can use them to calculate mul_reg1/mul_reg2
        -- In loops state we have inputs to dsp mac unit (address)
        -- In stal1 we have values of pix1 and pix2 and we can calculate values
        -- This way, in sum_calc we have valid mul_reg1 and mul_reg2
        when stal1 => 
                valid_next <= '1';
                state_next <= sum_calc;        

        -- In stal2 state, k_reg is set to 0, x_reg+=2. New sum1/sum2 addresses are calculated so
        -- we need one cycle to be sure that we clear correct data. Without this state stal2, race condition would appear
        when stal2 =>   
                state_next <= stal3;

        -- In stal3 state we are clearing sum1/sum2 and in the next cycle these values are valid and sent to BRAM on valid address
        -- This way, they are cleared and ready for new accumulating
        when stal3 => 
                sum1_next <= (others => '0');
                sum2_next <= (others => '0');
                state_next <= loops;       
                
        -- In sum_calc state, all values are final and valid and we can calculate sum1/sum2. k++, and move to next k loop iteration
        when sum_calc => 
                sum1_next <= sum1_reg + unsigned(mul_reg_1);   
                sum2_next <= sum2_reg + unsigned(mul_reg_2);
                k_next <= k_reg + 1;
                state_next <= loops;
        
        -- Error handling
        when others => 
            state_next <= idle;
    
    end case;

end process;
               
    -- Same as dx/dy = -center + k (Keep in mind that sigma_center is -center)
    -- This means that dx/dy can be negative
    dx <= sigma_center + k_reg;
    dy <= sigma_center + k_reg;

    kernel_rom_addr <= std_logic_vector(TO_UNSIGNED(TO_INTEGER(k_reg), log2c(KERNEL_ROM_SIZE))); 

    -- Calculate initial addresses if it's horizontal convolution
    read_adrr_gen_h: if  HORIZONTAL = true generate
        horiz_proc : process(x_reg, dx, img_width, y_reg) 
        begin

            -- Default value
            c_y <= unsigned(y_reg);

            if (x_reg + dx) < TO_SIGNED(0, 16)  then
                c_x <= (others => '0');
            elsif (x_reg + dx) >= signed(img_width) then 
                c_x <= unsigned(img_width) -1;
            else
                c_x <= unsigned(x_reg + dx);
            end if;                 
        end process;    
    end generate;

    -- Calculate initial addresses if it's vertical convolution
    -- First in memory are storred rows in offset up, then image, and then rows in offset down
    read_adrr_gen_v: if  HORIZONTAL = false generate
        vertic_proc: process(y_reg, dy, img_offset_up, img_offset_down, img_height, x_reg)
        begin

            -- Default values 
            c_x <= unsigned(x_reg); 
            c_y <= unsigned(y_reg);

            -- Regular clamp
            if TO_INTEGER(signed(img_offset_down)) = 0 and TO_INTEGER(signed(img_offset_up)) = 0  then                    
                if  (y_reg + dy) < TO_SIGNED(0, 16)  then
                    c_y <= (others => '0');                                   
                elsif (y_reg + dy) >= signed(img_height) then
                    c_y <= unsigned(img_height) -1 ;                                   
                else
                    c_y <= unsigned(y_reg + dy);
                end if;
            
            -- If current image has both offset rows, values can iterate above and below image data
            elsif TO_INTEGER(signed(img_offset_down)) /= 0 and TO_INTEGER(signed(img_offset_up)) /= 0  then
                if  (y_reg + dy) < signed(img_offset_up) then
                    c_y <= unsigned(signed(img_offset_up) + dy);                           
                elsif (y_reg + dy) >= signed(img_height) - signed(img_offset_down) then
                    c_y <= unsigned(signed(img_height) - signed(img_offset_down) + dy);
                else
                    c_y <= unsigned(y_reg + dy);
                end if;
            
            -- If current image has offset down, values can iterate below image data
            elsif TO_INTEGER(signed(img_offset_down)) /= 0 and TO_INTEGER(signed(img_offset_up)) = 0  then                    
                if (y_reg + dy) < TO_SIGNED(0, 16)  then
                    c_y <= (others => '0');                        
                elsif (y_reg + dy) >= signed(img_height) - signed(img_offset_down) then
                    c_y <= unsigned(signed(img_height) - signed(img_offset_down) + dy);                                   
                else
                    c_y <= unsigned(y_reg + dy);
                end if;
            
            -- If current image has offset up, values can iterate above image data
            elsif TO_INTEGER(signed(img_offset_down)) = 0 and TO_INTEGER(signed(img_offset_up)) /= 0  then
                if (y_reg + dy) < signed(img_offset_up) then
                    c_y <= unsigned(signed(img_offset_up) + dy);                           
                elsif (y_reg + dy) >= signed(img_height) then
                    c_y <= unsigned(img_height) -1 ;  
                else
                    c_y <= unsigned(y_reg + dy);
                end if;
            end if;                     
        end process; 

    end generate;

    -- Always used and calculated
    c_y_vec <= std_logic_vector(c_y);

    -- Used for vertical convolution sum1 write address
    x2_coord <= std_logic_vector(x_reg);

    -- Used for horizontal convolution pix1 read address
    c_x1_vec <= std_logic_vector(c_x);
    
    -- When Main BRAM is input BRAM, words are 32 bit, when Tmp BRAM is input BRAM, words are 16 bit

    -- pix2 is always read from bram1_b_rdata lower 16 bits
    -- pix1 is either upper 16 bits on the same address, or different address
    pix2 <= '0'&bram1_b_rdata((DATA_WIDTH-1) -1 downto 0);


vertical_conv: if HORIZONTAL = false generate

        -- sum2 -> BRAM2 (Tmp BRAM) B Port, sum1 -> BRAM2 (Tmp BRAM) A Port
        bram2_b_wdata <= std_logic_vector(sum2_reg(DATA_WIDTH -2 downto 0));
        bram2_a_wdata <= std_logic_vector(sum1_reg(DATA_WIDTH -2 downto 0));
        
        -- Variable used for sum1 and sum2 write (Tmp BRAM Port A and Port B Address)
        y_coord <= std_logic_vector(y_reg- signed(img_offset_up));

        -- Used for sum2 write address (Tmp BRAM Port B)
        x1_coord <= std_logic_vector(x_reg + 1);

        -- Used for pix1 and pix2 read address (Main BRAM Port B)
        c_x2_vec <= std_logic_vector(c_x/2);

        -- Read pix1 from Main BRAM port B, upper 16 bits
        pix1 <= '0'&bram1_b_rdata(R_PIXEL *(DATA_WIDTH-1) -1 downto (DATA_WIDTH-1));

        -- Full width for Tmp BRAM and width/2 for Main BRAM
        img_w1 <= img_width;
        img_w2 <= std_logic_vector(shift_right(unsigned(img_width), 1));
    
    end generate;


horizontal_conv: if HORIZONTAL = true  generate

        -- Sum1 and Sum2 concatenated and send to Main BRAM Port B
        bram2_b_wdata <= std_logic_vector(sum1_reg(DATA_WIDTH -2 downto 0)&sum2_reg(DATA_WIDTH -2 downto 0));
        bram2_a_wdata <= (others => '0');

        -- Variable used for sum1 and sum2 write (Main Port B Address)
        y_coord <= std_logic_vector(y_reg);

        -- Variable used for sum1 and sum2 write (Main Port B Address)
        x1_coord <= std_logic_vector(x_reg/2);

        -- Used for pix2 read address (Tmp BRAM Port B)
        c_x2_vec <= std_logic_vector(c_x + 1);

        -- Read pix1 from Tmp BRAM port A
        pix1 <= '0'&bram1_a_rdata((DATA_WIDTH-1) -1 downto 0);

        -- Full width for Tmp BRAM and width/2 for Main BRAM
        img_w1 <= std_logic_vector(shift_right(unsigned(img_width), 1));
        img_w2 <= img_width;

    end generate;


-- Multiply DSP to calculate multiplied value which is used for sum1
dsp_mul1: dsp_unit_mul_shift
generic map(WIDTH1 => DATA_WIDTH,
            WIDTH2 => DATA_WIDTH,
            SHIFT => 15)
port map( clk => clk,
          mul_valid => valid_reg,
          in_1 => pix1,
          in_2 => kernel_rom_data,
          out_res => mul_reg_1
          );

-- Multiply DSP to calculate multiplied value which is used for sum2
dsp_mul2: dsp_unit_mul_shift
generic map(WIDTH1 => DATA_WIDTH,
            WIDTH2 => DATA_WIDTH,
            SHIFT => 15)
port map( clk => clk,
          mul_valid => valid_reg,
          in_1 => pix2,
          in_2 => kernel_rom_data,
          out_res => mul_reg_2
          );

-- Multiply and add DSP module to calculate address of input BRAM Port B
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
              
-- Multiply and add DSP module to calculate address of output BRAM Port B
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


-- If horizontal convolution => Calculate read address for pix1 (Tmp BRAM)
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
        
-- If vertical convolution => Calculate write address for sum1 (Read BRAM)
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

-- CONSTANTS------------------------------------
kernel_rom_en <= '1';
bram1_b_en <= '1';
bram2_b_en <= '1';        
bram1_a_en <= '1' ;
bram2_a_en <= '1' ; 

bram2_b_we <= "1111";            
bram2_a_we <= "1111";

-- Musn't be able to write to input BRAM
bram1_b_we <= "0000";        
bram1_a_we <= "0000"; 
------------------------------------------------

end Mixed;
