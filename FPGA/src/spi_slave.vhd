library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
-- $Id:$

entity spi_slave is
   generic (
      CPOL : std_logic := '0';
      CPHA : std_logic := '0';
      ADDR_WIDTH : integer := 8;
      CTRL_WIDTH : integer := 8;
      DATA_WIDTH : integer := 16);
   port (
      nreset : in std_logic;
      spi_clk : in std_logic;
      spi_cen : in std_logic;
      spi_mosi : in std_logic;
      spi_miso : out std_logic;
      addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
      ren : out std_logic;
      wen : out std_logic;
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));
end spi_slave;

architecture rtl of spi_slave is

constant BUFFER_WIDTH : integer := ADDR_WIDTH + CTRL_WIDTH + DATA_WIDTH;
signal spi_clk_int : std_logic;
signal spi_phase : integer range 0 to ADDR_WIDTH + CTRL_WIDTH + DATA_WIDTH;
signal ale : std_logic;
signal dole : std_logic; -- strobe to latch data out
signal dile : std_logic; -- strobe to latch data in
signal ren_i : std_logic;
signal wen_i : std_logic;

signal mosi_buffer : std_logic_vector(BUFFER_WIDTH-1 downto 0);
signal rxtx_buffer : std_logic_vector(ADDR_WIDTH + CTRL_WIDTH + DATA_WIDTH-1 downto 0);
signal rx_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
signal rx_data : std_logic_vector(DATA_WIDTH-1 downto 0);

begin
        
   spi_clk_int <= not spi_clk when CPOL = '1' else spi_clk;

   process(spi_clk_int, spi_cen)
   begin
      if nreset = '0' or spi_cen = '1' then
         if CPHA = '0' then
            spi_phase <= 1;
         else
            spi_phase <= 0;
         end if;
      elsif falling_edge(spi_clk_int) then
         spi_phase <= spi_phase + 1;
      end if;
   end process;

   ale <= '1' when spi_phase = ADDR_WIDTH else '0';
   dole <= '1' when spi_phase = ADDR_WIDTH+CTRL_WIDTH+DATA_WIDTH else '0';
   dile <= '1' when spi_phase = ADDR_WIDTH+CTRL_WIDTH else '0';


   -- MOSI (slave data in) Buffer
   process (spi_clk_int)
   begin
      if spi_cen = '1' then
         wen <= '0';
         ren <= '0';
      elsif rising_edge(spi_clk_int) then

         if spi_phase = ADDR_WIDTH+1 then -- Register the read bit
            ren_i <= spi_mosi;
            ren <= spi_mosi;
         end if;

         if spi_phase = ADDR_WIDTH+2 then -- Register the write bit
            wen_i <= spi_mosi;
         end if;

         mosi_buffer <= mosi_buffer(BUFFER_WIDTH-2 downto 0) & spi_mosi;
         if ale = '1' then
            addr <= mosi_buffer(ADDR_WIDTH-2 downto 0) & spi_mosi;
         end if;

         if dole = '1' then
            data_out <= mosi_buffer(DATA_WIDTH-2 downto 0) & spi_mosi;
            wen <= wen_i;
         end if;

      end if;
   end process;


   -- Data in => MISO register
   process (spi_clk_int, spi_cen, nreset)
   begin
      if falling_edge(spi_clk_int) then
         if dile = '1' then -- Register data_in
            rxtx_buffer <= rxtx_buffer(BUFFER_WIDTH-2 downto 0) & spi_mosi;
            rxtx_buffer(rxtx_buffer'HIGH downto rxtx_buffer'HIGH - (DATA_WIDTH-1)) <= data_in;
         else
            rxtx_buffer <= rxtx_buffer(BUFFER_WIDTH-2 downto 0) & spi_mosi;
         end if;
      end if;
   end process;
   
   spi_miso <= rxtx_buffer(rxtx_buffer'HIGH);

end rtl;