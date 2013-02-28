library IEEE;
use IEEE.std_logic_1164.all;

package types_pkg is

   type t_slv2_vector is array (natural range <>) of std_logic_vector(1 downto 0);
   type t_slv3_vector is array (natural range <>) of std_logic_vector(2 downto 0);
   type t_slv4_vector is array (natural range <>) of std_logic_vector(3 downto 0);
   type t_slv5_vector is array (natural range <>) of std_logic_vector(4 downto 0);
   type t_slv6_vector is array (natural range <>) of std_logic_vector(5 downto 0);
   type t_slv7_vector is array (natural range <>) of std_logic_vector(6 downto 0);
   type t_slv8_vector is array (natural range <>) of std_logic_vector(7 downto 0);
   type t_slv9_vector is array (natural range <>) of std_logic_vector(8 downto 0);
   type t_slv10_vector is array (natural range <>) of std_logic_vector(9 downto 0);
   type t_slv11_vector is array (natural range <>) of std_logic_vector(10 downto 0);
   type t_slv12_vector is array (natural range <>) of std_logic_vector(11 downto 0);
   type t_slv13_vector is array (natural range <>) of std_logic_vector(12 downto 0);
   type t_slv14_vector is array (natural range <>) of std_logic_vector(13 downto 0);
   type t_slv15_vector is array (natural range <>) of std_logic_vector(14 downto 0);
   type t_slv16_vector is array (natural range <>) of std_logic_vector(15 downto 0);
   type t_slv17_vector is array (natural range <>) of std_logic_vector(16 downto 0);
   type t_slv18_vector is array (natural range <>) of std_logic_vector(17 downto 0);
   type t_slv19_vector is array (natural range <>) of std_logic_vector(18 downto 0);
   type t_slv20_vector is array (natural range <>) of std_logic_vector(19 downto 0);
   type t_slv21_vector is array (natural range <>) of std_logic_vector(20 downto 0);
   type t_slv22_vector is array (natural range <>) of std_logic_vector(21 downto 0);
   type t_slv23_vector is array (natural range <>) of std_logic_vector(22 downto 0);
   type t_slv24_vector is array (natural range <>) of std_logic_vector(23 downto 0);
   type t_slv25_vector is array (natural range <>) of std_logic_vector(24 downto 0);
   type t_slv26_vector is array (natural range <>) of std_logic_vector(25 downto 0);
   type t_slv27_vector is array (natural range <>) of std_logic_vector(26 downto 0);
   type t_slv28_vector is array (natural range <>) of std_logic_vector(27 downto 0);
   type t_slv29_vector is array (natural range <>) of std_logic_vector(28 downto 0);
   type t_slv30_vector is array (natural range <>) of std_logic_vector(29 downto 0);
   type t_slv31_vector is array (natural range <>) of std_logic_vector(30 downto 0);
   type t_slv32_vector is array (natural range <>) of std_logic_vector(31 downto 0);

   type t_slv48_vector is array (natural range <>) of std_logic_vector(47 downto 0);

   type t_slv64_vector is array (natural range <>) of std_logic_vector(63 downto 0);

   type t_slv128_vector is array (natural range <>) of std_logic_vector(127 downto 0);

   type t_slv256_vector is array (natural range <>) of std_logic_vector(255 downto 0);

   type boolean_vector is array (natural range <>) of boolean;

end package;
