-- Simple FIFO VHDL
-- Astro Designs Ltd.
-- $Id:$

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_MISC.all;

entity simple_fifo is
   generic (
      WIDTH : integer := 16;
      DEPTH : integer := 16);
   port (
      RESET    : in  std_logic := '0';
      CLK      : in  std_logic;
      CLK_EN   : in  std_logic := '1';
      
      WEN      : in  std_logic;
      DATA_IN  : in  std_logic_vector(WIDTH-1 downto 0);
      REN      : in  std_logic;
      DATA_OUT : out std_logic_vector(WIDTH-1 downto 0);
      
      LEVEL    : out  std_logic_vector(7 downto 0); -- Supports a maximum depth of 256
      EMPTY    : out  std_logic;
      FULL     : out  std_logic);
end simple_fifo;

architecture rtl of simple_fifo is

      type ram is array (0 to DEPTH-1) of std_logic_vector(7 downto 0);
      signal fifo : ram;
      signal write_pointer : integer range 0 to DEPTH-1;
      signal read_pointer : integer range 0 to DEPTH-1;
      signal fifo_level : integer range 0 to DEPTH;
      signal ram_read : integer range 0 to DEPTH-1;
      signal read_data : std_logic_vector(7 downto 0);
      signal fifo_write : std_logic;
      signal fifo_read : std_logic;

      attribute equivalent_register_removal : string;
      attribute keep : string;

      attribute keep of write_pointer : signal is "true";
      attribute equivalent_register_removal of write_pointer : signal is "no";
      attribute keep of read_pointer : signal is "true";
      attribute equivalent_register_removal of read_pointer : signal is "no";
      attribute keep of fifo_write : signal is "true";
      attribute equivalent_register_removal of fifo_write : signal is "no";
      attribute keep of fifo_read : signal is "true";
      attribute equivalent_register_removal of fifo_read : signal is "no";
      attribute keep of empty : signal is "true";
      attribute equivalent_register_removal of empty : signal is "no";
      attribute keep of full : signal is "true";
      attribute equivalent_register_removal of full : signal is "no";
      attribute keep of fifo_level : signal is "true";
      attribute equivalent_register_removal of fifo_level : signal is "no";

   begin

      process(CLK)
      begin
         if RESET = '1' then
            write_pointer <= 0;
            read_pointer <= 0;
            fifo_level <= 0;
         elsif rising_edge(CLK) then
            -- Write port...
            if WEN = '1' and fifo_level /= 16 then
               fifo(write_pointer) <= DATA_IN;
               write_pointer <= write_pointer + 1 mod DEPTH;
            end if;
            
            -- Read port...
            ram_read <= read_pointer;
            if REN = '1' and fifo_level /= 0 then
               read_pointer <= read_pointer + 1 mod DEPTH;
            end if;
            
            -- Track fifo level
            if WEN = '1' and REN = '0' and fifo_level /= DEPTH then
               fifo_level <= fifo_level + 1;
            elsif WEN = '0' and REN = '1' and fifo_level /= 0 then
               fifo_level <= fifo_level - 1;
            end if;
         end if;
      end process;

      DATA_OUT <= fifo(ram_read);

      LEVEL <= std_logic_vector(conv_unsigned(fifo_level,8)); -- Supports a maximum depth of 256
      EMPTY <= '1' when fifo_level = 0 else '0';
      FULL <= '1' when fifo_level = 16 else '0';

end rtl;

