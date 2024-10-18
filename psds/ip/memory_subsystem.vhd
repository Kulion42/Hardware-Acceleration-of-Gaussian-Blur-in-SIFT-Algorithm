----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/02/2024 11:10:44 PM
-- Design Name: 
-- Module Name: memory_subsystem - struct
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memory_subsystem is
Generic(
    --DATA WIDTH
    DATA_WIDTH : natural := 16;
    
    --SIZE OF BRAMS
    BRAM_SIZE : natural := 60000 --FIXED
);
Port (
    clk: in std_logic;
    reset: in std_logic;
    
    -----------------------------------------------------------------
    
    --INTERFACE TO AXI LITE
    
    reg_data_i : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    img_height_we_i: in std_logic;
    img_width_we_i: in std_logic;
    img_offset_up_we_i: in std_logic; 
    img_offset_down_we_i: in std_logic;
    img_per_octave_we_i: in std_logic;
    
    start_we_i : in std_logic;
    reset_we_i : in std_logic;
    --ready_wr_i : in std_logic;
       
    --software read
    img_height_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);
    img_width_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);
    img_offset_up_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0); 
    img_offset_down_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);
    img_per_octave_axi_o: out std_logic_vector(DATA_WIDTH -1 downto 0);
    
    ready_axi_o : out std_logic;
    start_axi_o : out std_logic;
    reset_axi_o : out std_logic;
    
    -----------------------------------------------------------------
    --MAIN BRAM INTERFACE
    
    --main bram interface A port
    main_mem_a_addr_i : in std_logic_vector(log2c(BRAM_SIZE)-1 downto 0);
    main_mem_a_wdata_i : in std_logic_vector(2*DATA_WIDTH-1 downto 0);
    main_mem_a_we_i : in std_logic_vector(3 downto 0);
    main_mem_a_en_i : in std_logic;
    
    main_mem_a_rdata_o : out std_logic_vector(2*DATA_WIDTH - 1 downto 0);  
    
    --main bram interface B port
    main_mem_b_addr_i : in std_logic_vector(log2c(BRAM_SIZE)-1 downto 0);
    main_mem_b_wdata_i : in std_logic_vector(2*DATA_WIDTH-1 downto 0);  
    main_mem_b_we_i : in std_logic_vector(3 downto 0);
    main_mem_b_en_i : in std_logic;
    
    main_mem_b_rdata_o : out std_logic_vector(2*DATA_WIDTH - 1 downto 0);
    
     -----------------------------------------------------------------
     
    --INTERFACE TO GAUSSIAN_BLUR
    
    --registers 
    img_height_o: out std_logic_vector(DATA_WIDTH -1 downto 0);
    img_width_o: out std_logic_vector(DATA_WIDTH -1 downto 0);
    img_offset_up_o: out std_logic_vector(DATA_WIDTH -1 downto 0); 
    img_offset_down_o: out std_logic_vector(DATA_WIDTH -1 downto 0);
    img_per_octave_o: out std_logic_vector(DATA_WIDTH -1 downto 0);
    
    start_o : out std_logic;
    reset_o : out std_logic;
    
    ready_i : in std_logic;
   
     
    --temp bram interface
    tmp_mem_a_addr_i : in std_logic_vector(log2c(BRAM_SIZE)-1 downto 0);
    tmp_mem_a_rdata_o : out std_logic_vector(2*DATA_WIDTH - 1 downto 0);
    tmp_mem_a_we_i : in std_logic_vector(3 downto 0);
    tmp_mem_a_en_i : in std_logic;
    
    tmp_mem_a_wdata_i : in std_logic_vector(2*DATA_WIDTH-1 downto 0);
    
    
    tmp_mem_b_addr_i : in std_logic_vector(log2c(BRAM_SIZE)-1 downto 0);
    tmp_mem_b_rdata_o : out std_logic_vector(2*DATA_WIDTH - 1 downto 0);
    tmp_mem_b_we_i : in std_logic_vector(3 downto 0);
    tmp_mem_b_en_i : in std_logic;
    
    tmp_mem_b_wdata_i : in std_logic_vector(2*DATA_WIDTH-1 downto 0) 
    
    
     
    );
end memory_subsystem;

architecture struct of memory_subsystem is

    component bram is
    generic (WIDTH: positive := 16;
             SIZE: positive := 60000);
    port (clk_a : in std_logic;
          clk_b : in std_logic;
          en_a: in std_logic;
          en_b: in std_logic;
          we_a: in std_logic_vector(3 downto 0);
          we_b: in std_logic_vector(3 downto 0);
          addr_a: in std_logic_vector(log2c(SIZE) -1 downto 0);
          addr_b: in std_logic_vector(log2c(SIZE) -1 downto 0);
          data_a_i: in std_logic_vector(2 *WIDTH-1 downto 0);
          data_b_i: in std_logic_vector(2 *WIDTH-1 downto 0);
          data_a_o: out std_logic_vector(2 *WIDTH-1 downto 0);
          data_b_o: out std_logic_vector(2 *WIDTH-1 downto 0));

    end component;

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
                
    
    ---------------------- MEMORIES ----------------------
    
    main_bram: bram
    Generic map(
        WIDTH => DATA_WIDTH,
        SIZE => BRAM_SIZE
    )
    Port map(
        clk_a => clk,
        clk_b => clk,
        en_a => main_mem_a_en_i,
        en_b => main_mem_b_en_i,
        we_a => main_mem_a_we_i,
        we_b => main_mem_b_we_i,
        addr_a => main_mem_a_addr_i,
        addr_b => main_mem_b_addr_i,
        data_a_i => main_mem_a_wdata_i,  --ulazni podatak za upis u bram
        data_b_i => main_mem_b_wdata_i,  --ulazni podatak za upis u bram
        data_a_o => main_mem_a_rdata_o,  --izlazni podatak za citanje bram-a
        data_b_o => main_mem_b_rdata_o   --izlazni podatak za citanje bram-a
    );
    --Port A i port B se koriste i od strane axija i od strane gaussian blura
    --ovo je implementirano u top modelu
    
    
    
    
    tmp_bram: bram
    Generic map(
        WIDTH => DATA_WIDTH,
        SIZE => BRAM_SIZE
        )
    Port map(
        clk_a => clk,
        clk_b => clk,
        en_a => tmp_mem_a_en_i,
        en_b => tmp_mem_b_en_i,
        we_a => tmp_mem_a_we_i,
        we_b => tmp_mem_b_we_i,
        addr_a => tmp_mem_a_addr_i,
        addr_b => tmp_mem_b_addr_i,
        data_a_i => tmp_mem_a_wdata_i,  --ulazni podatak za upis u bram
        data_b_i => tmp_mem_b_wdata_i,  --ulazni podatak za upis u bram
        data_a_o => tmp_mem_a_rdata_o,  --izlazni podatak za citanje bram-a
        data_b_o => tmp_mem_b_rdata_o   --izlazni podatak za citanje bram-a
    );   
    --Oba porta se koriste od strane IP-a,
 
    --Dodati write_read_bram_control
 
end struct;
