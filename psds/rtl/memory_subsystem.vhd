library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils_pkg.ALL;


entity memory_subsystem is
Generic(
    --DATA WIDTH
    DATA_WIDTH : natural := 16);
Port (
    clk: in std_logic;
    reset: in std_logic;
    
    -----------------------------------------------------------------
    
    --INTERFACE TO AXI LITE
    
    reg_data_i : in std_logic_vector(DATA_WIDTH - 1 downto 0); --16 bita
    
    img_height_we_i: in std_logic; 
    img_width_we_i: in std_logic;
    img_offset_up_we_i: in std_logic; 
    img_offset_down_we_i: in std_logic;
    img_per_octave_we_i: in std_logic;
    
    start_we_i : in std_logic;
    reset_we_i : in std_logic;
    --ready_wr_i : in std_logic;
       
    --software read
    img_height_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);         --16 bita
    img_width_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);          --16 bita
    img_offset_up_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);      --16 bita
    img_offset_down_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);    --16 bita
    img_per_octave_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);     --16 bita
    
    ready_axi_o : out std_logic;
    start_axi_o : out std_logic; --ako treba da se cita od strane softvera, treba dodati
    reset_axi_o : out std_logic;
     
    --INTERFACE TO GAUSSIAN_BLUR
    
    --registers 
    img_height_o: out std_logic_vector(DATA_WIDTH -1 downto 0);                 --16 bita
    img_width_o: out std_logic_vector(DATA_WIDTH -1 downto 0);                  --16 bita
    img_offset_up_o: out std_logic_vector(DATA_WIDTH -1 downto 0);              --16 bita
    img_offset_down_o: out std_logic_vector(DATA_WIDTH -1 downto 0);            --16 bita
    img_per_octave_o: out std_logic_vector(DATA_WIDTH -1 downto 0);             --16 bita
    
    start_o : out std_logic;
    reset_o : out std_logic;
    
    ready_i : in std_logic
   
    
    );
    
end memory_subsystem;

architecture struct of memory_subsystem is

    --registers
    signal img_height_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_width_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_offset_up_s: std_logic_vector(DATA_WIDTH -1 downto 0); 
    signal img_offset_down_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal img_per_octave_s: std_logic_vector(DATA_WIDTH -1 downto 0);
    signal start_s : std_logic;
    signal ready_s : std_logic;
    signal reset_s : std_logic;


begin

    --to gaussian blur
    img_height_o <= img_height_s;
    img_width_o <= img_width_s;
    img_offset_up_o <= img_offset_up_s;
    img_offset_down_o <= img_offset_down_s;
    img_per_octave_o <= img_per_octave_s;
    start_o <= start_s;
    reset_o <= reset_s;
    
    --to axi
    img_height_axi_o <= img_height_s;
    img_width_axi_o <= img_width_s;
    img_offset_up_axi_o <= img_offset_up_s;
    img_offset_down_axi_o <= img_offset_down_s;
    img_per_octave_axi_o <= img_per_octave_s;
    ready_axi_o <= ready_s;
    start_axi_o <= start_s;
    reset_axi_o <= reset_s;
    
    --img_height reg
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                img_height_s <= (others => '0');
            elsif img_height_we_i = '1' then
                img_height_s <= reg_data_i;
            end if;
        end if;
    end process;
    
    
    --img width reg
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                img_width_s <= (others => '0');
            elsif img_width_we_i = '1' then
                img_width_s <= reg_data_i;
            end if;
        end if;
    end process; 
    
    --img offset up reg
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                img_offset_up_s <= (others => '0');
            elsif img_offset_up_we_i = '1' then
                img_offset_up_s <= reg_data_i;
            end if;
        end if;
    end process;
    
    --img offset down reg
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                img_offset_down_s <= (others => '0');
            elsif img_offset_down_we_i = '1' then
                img_offset_down_s <= reg_data_i;
            end if;
        end if;
    end process;
    
    --img per octave reg
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                img_per_octave_s <= (others => '0');
            elsif img_per_octave_we_i = '1' then
                img_per_octave_s <= reg_data_i;
            end if;
        end if;
    end process;
    
    --start reg
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                start_s <= '0';
            elsif start_we_i = '1' then
                start_s <= reg_data_i(0);
            end if;
        end if;
    end process;
    
    --ready reg
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                ready_s <= '0';
            else
                ready_s <= ready_i;
            end if;
        end if;
    end process;
    --ovde mozda fali CE signal kao kod drugih, ako ga axi lite generise
       
    --reset reg
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                reset_s <= '0';
            elsif reset_we_i = '1' then
                reset_s <= reg_data_i(0);
            end if;
        end if;
    end process;
                
 
end struct;


