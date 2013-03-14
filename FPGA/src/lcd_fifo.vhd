-- LCD FIFO
-- Astro Designs Ltd.
-- $Id:$

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library work;
use work.types_pkg.all;

entity lcd_fifo is
   generic (
      WIDTH : integer;
      DEPTH : integer;
      LCD_INIT : t_slv16_vector(0 to 127) := (others => X"0000"); -- Note: This range would need to be increased for FIFOs deeper than 128.
      PREPROG_LEVEL : integer := 0);
   port (
      RESET : IN  std_logic;
      CLK   : IN  std_logic;
      CE    : IN  std_logic := '1';
      DIN   : IN  std_logic_VECTOR(WIDTH-1 downto 0);
      WR_EN : IN  std_logic;
      RD_EN : IN  std_logic;
      DOUT  : OUT std_logic_VECTOR(WIDTH-1 downto 0);
      LEVEL : OUT std_logic_vector(7 downto 0);
      EMPTY : OUT std_logic;
      FULL  : OUT STD_LOGIC);
end lcd_fifo;

architecture rtl of lcd_fifo is

signal ram  : t_slv16_vector(0 to DEPTH-1) := LCD_INIT(0 to DEPTH-1);
signal rdata : std_logic_vector(WIDTH-1 downto 0);
signal write_counter : integer range 0 to DEPTH-1 := PREPROG_LEVEL;
signal read_counter : integer range 0 to DEPTH-1 := 0;
signal fifo_level : integer range 0 to DEPTH := PREPROG_LEVEL;
signal ram_read : integer range 0 to DEPTH-1 := 0;

begin

   -- Read / Write address generator & level tracking
   process(RESET, CLK)
   begin
      if RESET = '1' then
      elsif rising_edge(CLK) and CE = '1' then

         -- Write process
         if WR_EN = '1' then
            if fifo_level /= DEPTH then
               write_counter <= write_counter + 1 mod DEPTH;
            end if;
         end if;
         
         -- Read process
         if RD_EN = '1' then
            if fifo_level /= 0 then
               read_counter <= read_counter + 1 mod DEPTH;
            end if;
         end if;
         
         -- Track fifo level
         if WR_EN = '1' and RD_EN = '0' and fifo_level /= DEPTH then
            fifo_level <= fifo_level + 1;
         elsif WR_EN = '0' and RD_EN = '1' and fifo_level /= 0 then
            fifo_level <= fifo_level - 1;
         end if;
      end if;
   end process;

   
   -- Write process...
   process(CLK)
   begin
      if rising_edge(CLK) and CE = '1'then
         if WR_EN = '1' and fifo_level /= DEPTH then
            ram(write_counter) <= DIN;
         end if;
      end if;
   end process;


   -- Read process...
   process(CLK)
   begin
      if rising_edge(CLK) and CE = '1' then
         ram_read <= read_counter;
      end if;
   end process;
   
   DOUT <= ram(ram_read);

LEVEL <= std_logic_vector(conv_unsigned(fifo_level,8));
EMPTY <= '1' when fifo_level = 0 else '0';
FULL <= '1' when fifo_level = DEPTH else '0';

END rtl;