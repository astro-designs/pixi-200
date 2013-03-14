-- Keyboard Scanner VHDL
-- Astro Designs Ltd.
-- $Id:$

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

library work;
use work.types_pkg.all;

entity kbscan is
   generic (
      ROWS        : integer := 4;
      COLUMNS     : integer := 4;
      KEY_MAP     : string := "123456789*0#");
   port (
      RESET       : in  std_logic := '0';
      CLK         : in  std_logic;
      CLK_EN      : in  std_logic := '1';

      SCAN_OUT    : out std_logic_vector(ROWS-1 downto 0);
      SCAN_IN     : in  std_logic_vector(COLUMNS-1 downto 0);

      KEY_PRESSED : out std_logic;
      KEY_CODE    : out std_logic_vector(7 downto 0));
end kbscan;

architecture rtl of kbscan is

   constant all_ones : std_logic_vector(31 downto 0) := X"FFFFFFFF";
   constant all_zeros : std_logic_vector(31 downto 0) := X"00000000";
   constant KEYPAD_STYLE : std_logic := '0'; -- Set to '0' if the keypad is a telephone style (3x4) keypad or '1' if it's a hexadecimal style (4x4) keypad
   signal scan_count : std_logic_vector(15 downto 0);
   signal scan_in_buf : t_slv4_vector(2 downto 0); -- 4-bit x 3 shift register
   signal scan_code : std_logic_vector(15 downto 0); -- 16 bit allows for 4x4 keypad (using one-hot coding)
   signal key_pressed_buf : std_logic_vector(2 downto 0);

begin

   process(CLK)
   begin
      if rising_edge(CLK) then
         scan_count <= scan_count + 1; -- Keyboard scanner counter used to sequence the scanning of each line in turn.
         scan_in_buf <= scan_in_buf(1 downto 0) & SCAN_IN; -- Register keyboard scan input into a shift register / buffer

         case scan_count(15 downto 12) is -- Decode scan_count 
            when "0000" => scan_code(3 downto 0)   <= scan_in_buf(2);
            when "0001" => scan_code(7 downto 4)   <= scan_in_buf(2);
            when "0010" => scan_code(11 downto 8)  <= scan_in_buf(2);
            when "0011" => scan_code(15 downto 12) <= scan_in_buf(2);
            when others => NULL;
         end case;
         
         key_pressed_buf(2 downto 1) <= key_pressed_buf(1 downto 0);

         if scan_count = all_ones(scan_count'range) then
            key_pressed_buf(0) <= '0'; -- default to no key pressed unless key is actually pressed.
            if KEYPAD_STYLE = '0' then -- Note this section of code is defined for a telephone style keypad (1,2,3  4,5,6  7,8,9  *,0,#)
               case scan_code is
               -- COL:  1234123412341234
               -- ROW:  4444333322221111
                  when "0000000000000001" => KEY_CODE <= std_logic_vector(conv_unsigned(character'pos(KEY_MAP(1)),8)); key_pressed_buf(0) <= '1'; -- "1"
                  when "0000000000000010" => KEY_CODE <= "00110010"; key_pressed_buf(0) <= '1'; -- "2"
                  when "0000000000000100" => KEY_CODE <= "00110011"; key_pressed_buf(0) <= '1'; -- "3"
                  when "0000000000010000" => KEY_CODE <= "00110100"; key_pressed_buf(0) <= '1'; -- "4"
                  when "0000000000100000" => KEY_CODE <= "00110101"; key_pressed_buf(0) <= '1'; -- "5"
                  when "0000000001000000" => KEY_CODE <= "00110110"; key_pressed_buf(0) <= '1'; -- "6"
                  when "0000000100000000" => KEY_CODE <= "00110111"; key_pressed_buf(0) <= '1'; -- "7"
                  when "0000001000000000" => KEY_CODE <= "00111000"; key_pressed_buf(0) <= '1'; -- "8"
                  when "0000010000000000" => KEY_CODE <= "00111001"; key_pressed_buf(0) <= '1'; -- "9"
                  when "0001000000000000" => KEY_CODE <= "00101010"; key_pressed_buf(0) <= '1'; -- "*"
                  when "0010000000000000" => KEY_CODE <= "00110000"; key_pressed_buf(0) <= '1'; -- "0"
                  when "0100000000000000" => KEY_CODE <= "00100011"; key_pressed_buf(0) <= '1'; -- "#"
                  when others => NULL; -- Nothing to do
               end case;
            else -- Note this section of code is defined for a 4x4 hexadecimal style keypad. (0,1,2,3  4,5,6,7  8,9,A,B  C,D,E,F)
               case scan_code is
                  when "0000000000000001" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "0"
                  when "0000000000000010" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "1"
                  when "0000000000000100" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "2"
                  when "0000000000001000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "3"
                  when "0000000000010000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "4"
                  when "0000000000100000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "5"
                  when "0000000001000000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "6"
                  when "0000000010000000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "7"
                  when "0000000100000000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "8"
                  when "0000001000000000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "9"
                  when "0000010000000000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "A"
                  when "0000100000000000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "B"
                  when "0001000000000000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "C"
                  when "0010000000000000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "D"
                  when "0100000000000000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "E"
                  when "1000000000000000" => KEY_CODE <= "00000000"; key_pressed_buf(0) <= '1'; -- "F"
                  when others => NULL; -- Nothing to do
               end case;
            end if;
         end if;         
      end if;
   end process;

   SCAN_OUT(0) <= '1' when scan_count(15 downto 12) = "0000" else '0'; -- Scan top row
   SCAN_OUT(1) <= '1' when scan_count(15 downto 12) = "0001" else '0'; -- Scan row 2
   SCAN_OUT(2) <= '1' when scan_count(15 downto 12) = "0010" else '0'; -- Scan row 3
   SCAN_OUT(3) <= '1' when scan_count(15 downto 12) = "0011" else '0'; -- Scan bottom row


   KEY_PRESSED <= '1' when key_pressed_buf(2 downto 1) = "01" else '0';

end rtl;

