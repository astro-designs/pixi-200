-- General-purpose I2C Switch

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

library work;
use work.types_pkg.all;

entity i2c_switch is
   generic (
      SLAVES : integer := 4);
   port (
      TIMEOUT_CLK          : in std_logic; -- Misc clock, 
      I2C_STOP_INHIBIT     : in std_logic := '0'; -- Only needed if Master does not support 'repeated starts'

      -- Master
      M_SCK                : in std_logic;
      M_SDA                : inout std_logic;
      
      -- Slaves
      S_SCK                : out   std_logic_vector(SLAVES-1 downto 0);
      S_SDA                : inout std_logic_vector(SLAVES-1 downto 0));
end i2c_switch;


architecture rtl of i2c_switch is

   signal i2c_sda : std_logic;
   signal i2c_rnw : std_logic;
   signal i2c_rxbuf : std_logic_vector(7 downto 0);
   signal i2c_txbuf : std_logic_vector(7 downto 0);
   signal i2c_slave_addr : std_logic_vector(6 downto 0);
   signal i2c_slave_rxdata : std_logic_vector(7 downto 0);
   signal i2c_slave_txdata : std_logic_vector(7 downto 0);
   type t_i2c_state is (i2c_sm_idle, i2c_sm_slave_addr, i2c_sm_slave_addr_ack, i2c_sm_rxbyte, i2c_sm_txbyte, i2c_sm_rxbyte_ack, i2c_sm_txbyte_ack, i2c_sm_stopwait);
   signal i2c_state : t_i2c_state;
   signal i2c_state_check0 : t_i2c_state;
   signal i2c_state_check1 : t_i2c_state;
   signal i2c_slave_sda_active : std_logic;
   signal i2c_bit_count : std_logic_vector(3 downto 0);
   signal i2c_bit_cen : std_logic;
   signal i2c_start : std_logic;
   signal i2c_stop : std_logic;
   signal i2c_start_reset : std_logic;
   signal i2c_stop_reset : std_logic;
   signal i2c_timeout_count : std_logic_vector(15 downto 0);
   signal i2c_timeout : std_logic;

   begin

      -- Detect start
      process(M_SDA)
      begin
         if i2c_start_reset = '1' or i2c_timeout = '1' then
               i2c_start <= '0';
         elsif falling_edge(M_SDA) then
            if M_SCK = '1' then
               i2c_start <= '1';
            end if;
         end if;
      end process;

      -- Detect stop
      process(M_SDA)
      begin
         if i2c_stop_reset = '1' or i2c_timeout = '1' then
               i2c_stop <= '0';
         elsif rising_edge(M_SDA) then
            if M_SCK = '1' then
               i2c_stop <= '1';
            end if;
         end if;
      end process;
      
      i2c_stop_reset <= i2c_start;

      -- Bit counter
      process(M_SCK)
      begin
         if i2c_bit_cen = '0' or i2c_state = i2c_sm_idle then
            i2c_bit_count <= "0001";
         elsif falling_edge(M_SCK) then
            if i2c_bit_count = "1000" then
               i2c_bit_count <= "0001";
            else
               i2c_bit_count <= i2c_bit_count + 1;
            end if;
         end if;
      end process;

      -- I2C timeout counter
      process(TIMEOUT_CLK)
      begin
         if i2c_state = i2c_sm_idle then
            i2c_timeout_count <= (others => '0');
         elsif rising_edge(TIMEOUT_CLK) then
            i2c_state_check0 <= i2c_state;
            i2c_state_check1 <= i2c_state_check0;
            if i2c_state_check0 = i2c_state_check1 then
               i2c_timeout_count <= i2c_timeout_count + 1;
            else
               i2c_timeout_count <= (others => '0');
            end if;
         end if;
      end process;
      i2c_timeout <= '1' when i2c_timeout_count(i2c_timeout_count'high) = '1' else '0';

      -- i2c tracking state machine
      process(M_SCK)
      begin
         if reset_p = '1' or (i2c_stop = '1' and i2c_state /= i2c_sm_stop_inhibit) then
            i2c_state <= i2c_sm_idle;
         elsif falling_edge(M_SCK) then
            i2c_start_reset <= '0';
            
            i2c_rxbuf <= i2c_rxbuf(6 downto 0) & i2c_sda;
            i2c_txbuf <= i2c_txbuf(6 downto 0) & M_SDA;
            
            -- Look for start bit
            case i2c_state is
               when i2c_sm_idle =>
                  if i2c_start = '1' then
                     i2c_state <= i2c_sm_slave_addr;
                     i2c_bit_cen <= '1';
                     i2c_start_reset <= '1';
                  end if;
               when i2c_sm_slave_addr =>
                  if i2c_bit_count = "1000" then
                     i2c_bit_cen <= '0';
                     i2c_slave_addr <= i2c_rxbuf(6 downto 0);
                     i2c_rnw <= M_SDA;
                     i2c_state <= i2c_sm_slave_addr_ack;
                  end if;
               when i2c_sm_slave_addr_ack =>
                  if i2c_rnw = '1' then
                     i2c_state <= i2c_sm_rxbyte;
                     i2c_bit_cen <= '1';
                  else
                     i2c_state <= i2c_sm_txbyte;
                     i2c_bit_cen <= '1';
                  end if;
               when i2c_sm_rxbyte =>
                  if i2c_bit_count = "1000" then
                     i2c_bit_cen <= '0';
                     i2c_slave_rxdata <= i2c_rxbuf(6 downto 0) & i2c_sda;
                     i2c_state <= i2c_sm_rxbyte_ack;
                  end if;
               when i2c_sm_txbyte =>
                  if i2c_bit_count = "1000" then
                     i2c_bit_cen <= '0';
                     i2c_slave_txdata <= i2c_txbuf(6 downto 0) & M_SDA;
                     i2c_state <= i2c_sm_txbyte_ack;
                  end if;
               when i2c_sm_rxbyte_ack =>
                  if I2C_STOP_INHIBIT = '1' and PI_SDA = '1' then -- Detect AK and inhibit STOP if STOP needs to be inhibited
                     i2c_state <= i2c_sm_stop_inhibit;
                  else
                     i2c_state <= i2c_sm_rxbyte;
                     i2c_bit_cen <= '1';
                  end if;
               when i2c_sm_txbyte_ack =>
                  if I2C_STOP_INHIBIT = '1' and M_SDA = '1' then -- Detect AK and inhibit STOP if STOP needs to be inhibited
                     i2c_state <= i2c_sm_stop_inhibit;
                  else
                     i2c_state <= i2c_sm_txbyte;
                     i2c_bit_cen <= '1';
                  end if;
               when i2c_sm_stop_inhibit => -- Prevent 'STOP' from propagating to slave
                  if i2c_start = '1' then
                     i2c_state <= i2c_sm_slave_addr;
                     i2c_bit_cen <= '1';
                     i2c_start_reset <= '1';
                  end if;
               when others => NULL;
            end case;
         end if;
      end process;
      
      
      i2c_slave_sda_active <= '1' when i2c_state = i2c_sm_slave_addr_ack or
                                      i2c_state = i2c_sm_rxbyte or
                                      i2c_state = i2c_sm_txbyte_ack
                                      else '0';

      -- Combine all SDA lines (from input buffers)
      i2c_sda <= and_reduce(S_SDA);

      -- Drive combined slave SDA to master when slave is driving SDA
      M_SDA <= '0' when i2c_sda = '0' and i2c_slave_sda_active = '1' else 'Z';
      
      -- Drive master SDA to all slaves when slave is not driving the bus
      slave_io_gen : for i in 0 to SLAVES-1 generate
         S_SCK(i) <= M_SCK;
         S_SDA(i) <= '0' when M_SDA = '0' and i2c_slave_sda_active = '0' else 'Z';
      end generate;
      
end rtl;
