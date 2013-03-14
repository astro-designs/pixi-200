-- User Logic VHDL
-- Astro Designs Ltd.
-- $Id:$

-- Template / example VHDL code

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity user_logic is
   generic (
      OPTION_1 : integer := 0; -- Defaults to 0 if not assigned in the component instantiation
      OPTION_2 : integer := 0);
   port (
      RESET    : in  std_logic := '0'; -- Defaults to '0' if not connected in the component instantiation
      CLK      : in  std_logic := '0';
      SW       : in  std_logic_vector(4 downto 1) := "0000";
      LEDS     : out std_logic_vector(7 downto 0);
      GPIO1    : inout std_logic_vector(23 downto 0);
      GPIO2    : inout std_logic_vector(15 downto 0);
      GPIO3    : inout std_logic_vector(15 downto 0);
      EXP      : inout std_logic_vector(19 downto 0));
end user_logic;

architecture rtl of user_logic is

-- Here we define signal, constant, type & component definitions

signal a : std_logic;
signal b : std_logic_vector(0 to 15);
signal c : std_logic_vector(15 downto 0) := "1111111000010000";
signal d : std_logic_vector(15 downto 0) := X"FE10";
type t_state is (idle, waiting, working, ending);
signal e : t_state := idle;

-- Start the functional code with begin...
begin

   -- Example code
   -- Simply connect the four switches to four of the LEDS and connect the
   -- inverse logic from three of the four switches to three of the remaining four LEDS.
   -- Drive the remaining LED with a logical AND function of the logic from the first two switches.
   
   LEDS(3 downto 0) <= SW(4 downto 1);
   
   LEDS(6 downto 4) <= not SW(4 downto 1);

   LEDS(7) <= '1' when SW(1) = '1' and SW(2) = '1' else '0';
   
end rtl;