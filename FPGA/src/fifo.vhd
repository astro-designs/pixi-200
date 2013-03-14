-- FIFO VHDL
-- Astro Designs Ltd.
-- $Id:$

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity fifo is
   generic (
      WIDTH         : integer := 16;
      DEPTH         : integer := 16;
      PRELOAD_LEVEL : integer := 0;
      INIT_00       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_10       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_11       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_12       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_13       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_14       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_15       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_16       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_17       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_18       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_19       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1A       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1B       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1C       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1D       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1E       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1F       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_20       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_21       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_22       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_23       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_24       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_25       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_26       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_27       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_28       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_29       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2A       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2B       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2C       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2D       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2E       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2F       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_30       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_31       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_32       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_33       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_34       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_35       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_36       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_37       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_38       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_39       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3A       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3B       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3C       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3D       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3E       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3F       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_40       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_41       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_42       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_43       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_44       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_45       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_46       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_47       : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000");
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
end fifo;

architecture rtl of fifo is

type ram_type is array (DEPTH-1 downto 0) of std_logic_vector(WIDTH-1 downto 0);

-- Initialise RAM function
function init_ram return ram_type is
   variable tmp : ram_type := (others => (others => '0'));  
   begin
      for bit_num in 0 to DEPTH*WIDTH-1 loop
         if bit_num >= 16#0000# and bit_num < 16#0100# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_00(bit_num mod 256)); end if;
         if bit_num >= 16#0100# and bit_num < 16#0200# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_01(bit_num mod 256)); end if;
         if bit_num >= 16#0200# and bit_num < 16#0300# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_02(bit_num mod 256)); end if;
         if bit_num >= 16#0300# and bit_num < 16#0400# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_03(bit_num mod 256)); end if;
         if bit_num >= 16#0400# and bit_num < 16#0500# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_04(bit_num mod 256)); end if;
         if bit_num >= 16#0500# and bit_num < 16#0600# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_05(bit_num mod 256)); end if;
         if bit_num >= 16#0600# and bit_num < 16#0700# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_06(bit_num mod 256)); end if;
         if bit_num >= 16#0700# and bit_num < 16#0800# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_07(bit_num mod 256)); end if;
         if bit_num >= 16#0800# and bit_num < 16#0900# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_08(bit_num mod 256)); end if;
         if bit_num >= 16#0900# and bit_num < 16#0A00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_09(bit_num mod 256)); end if;
         if bit_num >= 16#0A00# and bit_num < 16#0B00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_0A(bit_num mod 256)); end if;
         if bit_num >= 16#0B00# and bit_num < 16#0C00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_0B(bit_num mod 256)); end if;
         if bit_num >= 16#0C00# and bit_num < 16#0D00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_0C(bit_num mod 256)); end if;
         if bit_num >= 16#0D00# and bit_num < 16#0E00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_0D(bit_num mod 256)); end if;
         if bit_num >= 16#0E00# and bit_num < 16#0F00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_0E(bit_num mod 256)); end if;
         if bit_num >= 16#0F00# and bit_num < 16#1000# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_0F(bit_num mod 256)); end if;
         if bit_num >= 16#1000# and bit_num < 16#1100# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_10(bit_num mod 256)); end if;
         if bit_num >= 16#1100# and bit_num < 16#1200# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_11(bit_num mod 256)); end if;
         if bit_num >= 16#1200# and bit_num < 16#1300# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_12(bit_num mod 256)); end if;
         if bit_num >= 16#1300# and bit_num < 16#1400# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_13(bit_num mod 256)); end if;
         if bit_num >= 16#1400# and bit_num < 16#1500# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_14(bit_num mod 256)); end if;
         if bit_num >= 16#1500# and bit_num < 16#1600# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_15(bit_num mod 256)); end if;
         if bit_num >= 16#1600# and bit_num < 16#1700# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_16(bit_num mod 256)); end if;
         if bit_num >= 16#1700# and bit_num < 16#1800# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_17(bit_num mod 256)); end if;
         if bit_num >= 16#1800# and bit_num < 16#1900# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_18(bit_num mod 256)); end if;
         if bit_num >= 16#1900# and bit_num < 16#1A00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_19(bit_num mod 256)); end if;
         if bit_num >= 16#1A00# and bit_num < 16#1B00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_1A(bit_num mod 256)); end if;
         if bit_num >= 16#1B00# and bit_num < 16#1C00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_1B(bit_num mod 256)); end if;
         if bit_num >= 16#1C00# and bit_num < 16#1D00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_1C(bit_num mod 256)); end if;
         if bit_num >= 16#1D00# and bit_num < 16#1E00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_1D(bit_num mod 256)); end if;
         if bit_num >= 16#1E00# and bit_num < 16#1F00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_1E(bit_num mod 256)); end if;
         if bit_num >= 16#1F00# and bit_num < 16#2000# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_1F(bit_num mod 256)); end if;
         if bit_num >= 16#2000# and bit_num < 16#2100# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_20(bit_num mod 256)); end if;
         if bit_num >= 16#2100# and bit_num < 16#2200# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_21(bit_num mod 256)); end if;
         if bit_num >= 16#2200# and bit_num < 16#2300# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_22(bit_num mod 256)); end if;
         if bit_num >= 16#2300# and bit_num < 16#2400# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_23(bit_num mod 256)); end if;
         if bit_num >= 16#2400# and bit_num < 16#2500# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_24(bit_num mod 256)); end if;
         if bit_num >= 16#2500# and bit_num < 16#2600# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_25(bit_num mod 256)); end if;
         if bit_num >= 16#2600# and bit_num < 16#2700# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_26(bit_num mod 256)); end if;
         if bit_num >= 16#2700# and bit_num < 16#2800# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_27(bit_num mod 256)); end if;
         if bit_num >= 16#2800# and bit_num < 16#2900# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_28(bit_num mod 256)); end if;
         if bit_num >= 16#2900# and bit_num < 16#2A00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_29(bit_num mod 256)); end if;
         if bit_num >= 16#2A00# and bit_num < 16#2B00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_2A(bit_num mod 256)); end if;
         if bit_num >= 16#2B00# and bit_num < 16#2C00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_2B(bit_num mod 256)); end if;
         if bit_num >= 16#2C00# and bit_num < 16#2D00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_2C(bit_num mod 256)); end if;
         if bit_num >= 16#2D00# and bit_num < 16#2E00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_2D(bit_num mod 256)); end if;
         if bit_num >= 16#2E00# and bit_num < 16#2F00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_2E(bit_num mod 256)); end if;
         if bit_num >= 16#2F00# and bit_num < 16#3000# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_2F(bit_num mod 256)); end if;
         if bit_num >= 16#3000# and bit_num < 16#3100# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_30(bit_num mod 256)); end if;
         if bit_num >= 16#3100# and bit_num < 16#3200# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_31(bit_num mod 256)); end if;
         if bit_num >= 16#3200# and bit_num < 16#3300# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_32(bit_num mod 256)); end if;
         if bit_num >= 16#3300# and bit_num < 16#3400# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_33(bit_num mod 256)); end if;
         if bit_num >= 16#3400# and bit_num < 16#3500# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_34(bit_num mod 256)); end if;
         if bit_num >= 16#3500# and bit_num < 16#3600# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_35(bit_num mod 256)); end if;
         if bit_num >= 16#3600# and bit_num < 16#3700# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_36(bit_num mod 256)); end if;
         if bit_num >= 16#3700# and bit_num < 16#3800# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_37(bit_num mod 256)); end if;
         if bit_num >= 16#3800# and bit_num < 16#3900# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_38(bit_num mod 256)); end if;
         if bit_num >= 16#3900# and bit_num < 16#3A00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_39(bit_num mod 256)); end if;
         if bit_num >= 16#3A00# and bit_num < 16#3B00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_3A(bit_num mod 256)); end if;
         if bit_num >= 16#3B00# and bit_num < 16#3C00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_3B(bit_num mod 256)); end if;
         if bit_num >= 16#3C00# and bit_num < 16#3D00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_3C(bit_num mod 256)); end if;
         if bit_num >= 16#3D00# and bit_num < 16#3E00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_3D(bit_num mod 256)); end if;
         if bit_num >= 16#3E00# and bit_num < 16#3F00# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_3E(bit_num mod 256)); end if;
         if bit_num >= 16#3F00# and bit_num < 16#4000# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_3F(bit_num mod 256)); end if;
         if bit_num >= 16#4000# and bit_num < 16#4100# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_30(bit_num mod 256)); end if;
         if bit_num >= 16#4100# and bit_num < 16#4200# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_31(bit_num mod 256)); end if;
         if bit_num >= 16#4200# and bit_num < 16#4300# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_32(bit_num mod 256)); end if;
         if bit_num >= 16#4300# and bit_num < 16#4400# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_33(bit_num mod 256)); end if;
         if bit_num >= 16#4400# and bit_num < 16#4500# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_34(bit_num mod 256)); end if;
         if bit_num >= 16#4500# and bit_num < 16#4600# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_35(bit_num mod 256)); end if;
         if bit_num >= 16#4600# and bit_num < 16#4700# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_36(bit_num mod 256)); end if;
         if bit_num >= 16#4700# and bit_num < 16#4800# then tmp(bit_num / WIDTH)(bit_num mod WIDTH) := To_StdULogic(INIT_37(bit_num mod 256)); end if;      end loop;
   return tmp;
end function;

signal ram : ram_type := init_ram;

signal rdata : std_logic_vector(WIDTH-1 downto 0);
signal write_counter : integer range DEPTH-1 downto 0 := PRELOAD_LEVEL;
signal read_counter : integer range DEPTH-1 downto 0 := 0;
signal fifo_level : integer range DEPTH-1 downto 0 := PRELOAD_LEVEL;
signal ram_read : integer range DEPTH-1 downto 0;
signal fifo_full : std_logic;

begin

   -- Read / Write address generator & level tracking
   process(RESET, CLK)
   begin
      if RESET = '1' then
         write_counter <= PRELOAD_LEVEL;
         fifo_level <= PRELOAD_LEVEL;
         read_counter <= 0;
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
      if RESET = '1' then
      elsif rising_edge(CLK) and CE = '1'then
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