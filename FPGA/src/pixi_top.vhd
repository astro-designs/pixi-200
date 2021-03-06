-- PiXi-200 top-level VHDL
-- Astro Designs Ltd.
-- $Id:$

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.types_pkg.all;
use work.build_time_pkg.all;
use work.registers_pkg.all;

ENTITY pixi IS
   GENERIC (
      -- Compile options...
      DEMO_BUILD             : std_logic_vector(15 downto 0) := X"0000"; -- Non-zero values indicate demo build & position in demo sequence
      DEFAULT_I2C_ADDRESS    : std_logic_vector(7 downto 0) := X"70"; -- Default I2C address (A7..A1) of bits (7..0) of the slave address byte
      DEFAULT_SPI_FPGA_CH    : std_logic := '0'; -- Sets the default SPI channel number for the FPGA's SPI interface
      DEFAULT_SPI_MCP3204_CH : std_logic := '1'; -- Sets the default SPI channel number for the ADC
      ENABLE_SPI_INTERFACE   : boolean := true;  -- Use this to enable the SPI interface
      ENABLE_I2C_INTERFACE   : boolean := true;  -- Use this to enable the I2C switch
      ENABLE_TESTMODE        : boolean := true;  -- Use this to enable the testmode options (enter testmode by holding SW4 down while pressing and releasing SW3)
      ENABLE_RUNTIME_COUNTER : boolean := true; -- Use this to enable the runtime counter (counts seconds or run-time from startup or reset)
      ENABLE_LCDVFD          : boolean := true;  -- Use this to enable the dedicatad LCD / VFD interface on GPIO3
      ENABLE_KBSCAN          : boolean := true;  -- Use this to enable the keypad scanner option on GPIO1(19:13)
      ENABLE_TIMER           : boolean := true;  -- Use this to enable the general-purpose timer function
      ENABLE_COUNTER         : boolean := true;  -- Use this to enable the general-purposs counter function
      ENABLE_PWM_GEN         : boolean := true;  -- Use this to enable the 8 PWM controllers
      ENABLE_PWM_SEQ         : boolean := true;  -- Use this to enable the PWM sequencer
      ENABLE_PWM_READBACK    : boolean := true; -- Use this to enable register readback of the PWM contro registers
      ENABLE_UART1           : boolean := false; -- Use this to enable the internal UART (not yet implemented)
      ENABLE_EXP_F0          : boolean := false; -- Use this to enable expansion function f0 (20 x 3.3v single-ended I/O) (not yet implemented)
      ENABLE_EXP_F1          : boolean := false; -- Use this to enable expansion function f1 (10 x 3.3v LVDS I/O) (not yet implemented)
      ENABLE_USERLOGIC       : boolean := false; -- Use this to enable user logic module
      ENABLE_LED_CTRL        : boolean := true); -- Use this to enable advanced LED driver options (useful for debug)
   PORT (
      -- Pi General purpose I/O
      PI_GPIO_GEN          : INOUT STD_LOGIC_VECTOR(10 downto 0);

      -- Pi I2C
      PI_SCK               : IN STD_LOGIC;
      PI_SDA               : INOUT STD_LOGIC;
      
      -- Pi SPI interface
      PI_SPI_MOSI          : IN    STD_LOGIC;
      PI_SPI_MISO          : INOUT STD_LOGIC;
      PI_SPI_SCLK          : IN    STD_LOGIC;
      PI_SPI_CE0_N         : IN    STD_LOGIC;
      PI_SPI_CE1_N         : IN    STD_LOGIC;
      
      -- Pi clock
      PI_GPIO_GCLK         : IN    STD_LOGIC;
      
      -- Pi Serial
      PI_TXD0              : IN    STD_LOGIC;
      PI_RXD0              : INOUT STD_LOGIC;
      
      -- Clock (33MHz)
      CLK0                 : IN    STD_LOGIC;

      -- GPIO 1, 2 & 3
      GPIO1                : INOUT STD_LOGIC_VECTOR(23 DOWNTO 0);
      GPIO2                : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      GPIO3                : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      GPIO3_OE             : OUT   STD_LOGIC_VECTOR(1 DOWNTO 0);
      GPIO3_TR             : OUT   STD_LOGIC_VECTOR(1 DOWNTO 0);

      -- LEDs & Switches
      LED                  : OUT   STD_LOGIC_VECTOR(8 DOWNTO 1);
      SW                   : IN    STD_LOGIC_VECTOR(4 DOWNTO 1);

      -- RS232 level shift
      SIN                  : IN    STD_LOGIC;
      SOUT                 : OUT   STD_LOGIC;
      CTS                  : IN    STD_LOGIC;
      RTS                  : OUT   STD_LOGIC;

      -- EEPROM
      EESDA                : INOUT STD_LOGIC;
      EESDC                : OUT   STD_LOGIC;

      -- ADC
      ADC_SCK              : OUT   STD_LOGIC;
      ADC_MOSI             : OUT   STD_LOGIC; -- Connects to ADC DIN
      ADC_MISO             : IN    STD_LOGIC; -- Connects to ADC DOUT
      ADC_CS_N             : OUT   STD_LOGIC;

      -- DAC
      DAC_SCK              : OUT   STD_LOGIC;
      DAC_SDA              : INOUT STD_LOGIC;
      DAC_LDAC             : OUT   STD_LOGIC;
      DAC_RDY              : IN    STD_LOGIC;
      
      -- 3-Axis Accelerometer
      MMA_SCK              : OUT   STD_LOGIC;
      MMA_SDA              : INOUT STD_LOGIC;
      MMA_INT              : IN    STD_LOGIC;
      
      -- 3-Axis Magnetometer
      MAG_SCK              : OUT   STD_LOGIC;
      MAG_SDA              : INOUT STD_LOGIC;
      MAG_INT              : IN    STD_LOGIC;
      
      -- Expansion
      -- Note this section of GPIO needs more work to make it configurable & general purpose
      EXP_IP               : IN    STD_LOGIC_VECTOR(4 downto 0);
      EXP_IN               : IN    STD_LOGIC_VECTOR(4 downto 0);
      EXP_OP               : OUT   STD_LOGIC_VECTOR(9 downto 5);
      EXP_ON               : OUT   STD_LOGIC_VECTOR(9 downto 5)
      );
END pixi;


architecture rtl of pixi is

   constant all_ones : std_logic_vector(31 downto 0) := X"FFFFFFFF";
   constant all_zeros : std_logic_vector(31 downto 0) := X"00000000";
   constant PWM_BITS : integer := 10;

   -- Reset
   signal startup_count : std_logic_vector(27 downto 0) := (others => '0');
   signal startup_phase : std_logic_vector(7 downto 0) := (others => '0');
   signal startup : boolean;
   signal startup_reset : std_logic;
   signal fpga_reset : std_logic := '0';
   signal reset_p : std_logic;
   signal reset_n : std_logic;

   -- Clocks
   signal clk_33m : std_logic;
   signal pi_spi_sclk_bufg : std_logic;
   signal pi_sck_bufg : std_logic;
   signal pi_gpio_gclk_bufg : std_logic;
   
   signal en_50hz : std_logic;
   signal en_50hz_phase : std_logic_vector(23 downto 0);
   signal en_pwm : std_logic;
   signal en_pwm_phase : std_logic_vector(23 downto 0);
   signal en_5hz : std_logic;
   signal en_5hz_phase : std_logic_vector(23 downto 0);
   signal en_2hz : std_logic;
   signal en_2hz_phase : std_logic_vector(23 downto 0);
   signal en_1hz : std_logic;
   signal en_1hz_phase : std_logic_vector(27 downto 0);
   signal clk_2hz5 : std_logic;
   signal clk_1hz : std_logic;
   signal exp_clk : std_logic;
   signal runtime_count : std_logic_vector(31 downto 0);
   signal en_5s : std_logic;
   signal en_5s_phase : std_logic_vector(3 downto 0);
   signal en_0hz2 : std_logic;
     
   -- SPI
   signal spi_FPGA_ch : std_logic;
   signal spi_MCP3204_ch : std_logic;
   signal spi_do : std_logic;
   signal spi_do_en : std_logic;
   signal spi_wen : std_logic;
   signal spi_ren : std_logic;
   signal spi_miso : std_logic;
   signal spi_addr : std_logic_vector(7 downto 0);
   signal spi_rdata : std_logic_vector(15 downto 0);
   signal spi_wdata : std_logic_vector(15 downto 0);
   signal spi_wen_buf : std_logic_vector(3 downto 0);
   signal spi_ren_buf : std_logic_vector(3 downto 0);
   signal spi_wen_33m : std_logic;
   signal spi_ren_33m : std_logic;
   
   -- IIC
   signal i2c_slave_address : std_logic_vector(6 downto 0);
   
   -- Registers (see registers_pkg.vhd for full definition of the registers)
   constant num_registers : integer := 256;
   signal wreg : t_slv16_vector(num_registers-1 downto 0);
   signal rreg : t_slv16_vector(num_registers-1 downto 0);
   signal wen : std_logic_vector(num_registers-1 downto 0);
   signal ren : std_logic_vector(num_registers-1 downto 0);
   signal wen_ext : t_slv16_vector(num_registers-1 downto 0);

   -- GPIO
   signal gpio1_f1 : std_logic_vector(23 downto 0);
   signal gpio1_f2 : std_logic_vector(23 downto 0);
   signal gpio1_f3 : std_logic_vector(23 downto 0);
   signal gpio1_kbscan_out : std_logic_vector(3 downto 0);
   signal gpio1_sck0 : std_logic;
   signal gpio1_sda0 : std_logic;
   signal gpio2a_pwm : std_logic_vector(7 downto 0);
   signal gpio2b_pwm : std_logic_vector(7 downto 0);
   signal gpio2_f3 : std_logic_vector(15 downto 0);
   signal gpio3a_vfd : std_logic_vector(7 downto 0);
   signal gpio3b_vfd : std_logic_vector(7 downto 0);
   signal gpio3_oe_vfd : std_logic_vector(1 downto 0);
   signal gpio3_tr_vfd : std_logic_vector(1 downto 0);
   signal gpio3_f3 : std_logic_vector(15 downto 0);
   signal pwm_pos : t_slv16_vector(7 downto 0);
   signal pwm_dir : std_logic_vector(7 downto 0);
   signal exp_f1 : std_logic_vector(19 downto 0);
   signal exp_f2 : std_logic_vector(19 downto 0);
   signal exp_f3 : std_logic_vector(19 downto 0);

   -- Switches & LEDs
   signal sw_buf : std_logic_vector(4 downto 1);
   signal sw_event : std_logic_vector(4 downto 1);
   signal sw_event_reset_buf : std_logic_vector(2 downto 0);
   signal leds : t_slv8_vector(31 downto 0);   
   signal led_blink : std_logic_vector(7 downto 0);
   signal moving_leds : std_logic_vector(7 downto 0);
   signal led_dir : std_logic;
   signal moving_leds2 : std_logic_vector(7 downto 0);
   signal led_dir2 : std_logic;
   signal clock_leds : std_logic_vector(11 downto 0);
   
   -- Test
   signal testmode : boolean := false;
   signal key_code : std_logic_vector(7 downto 0); -- 8-bit character code (ASCII)

   -- Define a simple function to convert a string of characters for the LCD/VFD display into an array of
   -- 16-bit sdt_logic_vector words, compatible with the LCD interface.
   function string_to_slv16_vector (s : string) return t_slv16_vector is
      variable tmp : t_slv16_vector(s'range);
   begin
      for j in s'range loop
         tmp(j) := X"02" & std_logic_vector(conv_unsigned(character'pos(s(j)),8));
      end loop;
      return tmp;
   end string_to_slv16_vector;

   attribute equivalent_register_removal : string;
   attribute keep : string;

   attribute keep of gpio3a_vfd : signal is "true";
   attribute equivalent_register_removal of gpio3a_vfd : signal is "no";
   attribute keep of gpio3b_vfd : signal is "true";
   attribute equivalent_register_removal of gpio3b_vfd : signal is "no";

COMPONENT fifo_generator_v9_3
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

begin

-- ********************************************
-- ***** Clocks & DCMs                    *****
-- ********************************************

   -- Main 33MHz clock distribution buffer
   bufg_clk0 : BUFG
   port map (I => CLK0, O => clk_33m);
   
   -- SPI clock distribution buffer
   bufg_pi_spi_sclk : BUFG
   port map (I => PI_SPI_SCLK, O => pi_spi_sclk_bufg);
   
   -- I2C clock distribution buffer
   bufg_pi_sck : BUFG
   port map (I => PI_SCK, O => pi_sck_bufg);
   
   -- Main 33MHz clock distribution buffer
   bufg_pi_gclk_gpio : BUFG
   port map (I => PI_GPIO_GCLK, O => pi_gpio_gclk_bufg);

   -- 50Hz clock-enable generator
   process(clk_33m)
   begin
      if reset_n = '0' then
         en_50hz_phase <= X"000000";
      elsif rising_edge(clk_33m) then
         en_50hz <= '0';
         if en_50hz_phase = X"0A2C2A" then
            en_50hz_phase <= X"000000";
            en_50hz <= '1';
         else
            en_50hz_phase <= en_50hz_phase + 1;
         end if;
      end if;
   end process;

   -- 5Hz clock-enable generator
   process(clk_33m)
   begin
      if reset_n = '0' then
         en_5hz_phase <= X"000000";
      elsif rising_edge(clk_33m) then
         en_5hz <= '0';
         if en_5hz_phase = X"65B9AA" then
            en_5hz_phase <= X"000000";
            en_5hz <= '1';
            clk_2hz5 <= not clk_2hz5;
         else
            en_5hz_phase <= en_5hz_phase + 1;
         end if;
      end if;
   end process;

   -- 1Hz clock-enable generator
   process(clk_33m)
   begin
      if reset_n = '0' then
         en_1hz_phase <= (others => '0');
      elsif rising_edge(clk_33m) then
         en_1hz <= '0';
         if en_1hz_phase = X"1FCA054" then
            en_1hz_phase <= X"0000000";
            en_1hz <= '1';
         else
            en_1hz_phase <= en_1hz_phase + 1;
         end if;
      end if;
   end process;

   -- 1s clock generator
   process(clk_33m)
   begin
      if reset_n = '0' then
         en_2hz_phase <= X"000000";
      elsif rising_edge(clk_33m) then
         en_2hz <= '0';
         if en_2hz_phase = X"FE502A" then
            en_2hz_phase <= X"000000";
            en_2hz <= '1';
         else
            en_2hz_phase <= en_2hz_phase + 1;
         end if;

         if en_2hz = '1' then
            clk_1hz <= not clk_1hz;
         end if;
      end if;
   end process;

   -- 0.2Hz (5s) clock-enable generator
   process(clk_33m)
   begin
      if reset_n = '0' then
         en_5s_phase <= (others => '0');
         en_5s <= '0';
      elsif rising_edge(clk_33m) and en_1hz = '1' then
         en_5s <= '0';
         if en_5s_phase = X"4" then
            en_5s_phase <= X"0";
            en_5s <= '1';
         else
            en_5s_phase <= en_5s_phase + 1;
         end if;
      end if;
   end process;
   en_0hz2 <= '1' when en_1hz = '1' and en_5s = '1' else '0';

-- ********************************************
-- ***** Startup & Reset                  *****
-- ********************************************

   -- Force async reset when SW3 & SW4 are pressed at the same time
   fpga_reset <= '1' when SW = "1111" else '0';

   -- startup reset (approx 100ms) & startup phase
   -- Hold SW4 while releasing S3 to enter test mode after reset
   -- Hold SW3 while releasing S4 to avoid test mode after reset
   
   process(clk_33m)
   begin
      if fpga_reset = '1' then
         startup_count <= (others => '0');
         startup_phase <= (others => '0');
         testmode <= false;
      elsif rising_edge(clk_33m) then
         if startup_count(startup_count'HIGH) = '0' then
            startup_count <= startup_count + 1;
            startup_phase <= startup_count(startup_count'HIGH downto startup_count'HIGH-7);
            if SW(4) = '1' and ENABLE_TESTMODE then
               testmode <= true;
            end if;
         end if;
      end if;
   end process;

   startup_reset <= '1' when startup_phase = all_zeros(startup_phase'range) else '0';
   startup <= startup_phase(startup_phase'HIGH -1) = '0';

   reset_n <= '0' when startup_reset = '1' else '1';
   reset_p <= '1' when startup_reset = '1' else '0';
   

-- ********************************************
-- ***** Run-time Counter                 *****
-- ********************************************
-- 32-bit counter, starts at zero at reset or startup and increments every second.
   runtime_counter : if ENABLE_RUNTIME_COUNTER generate
   begin
      process(clk_33m)
      begin
         if startup_reset = '1' then
            runtime_count <= (others => '0');
         elsif rising_edge(clk_33m) then
            if en_1hz = '1' then
               runtime_count <= runtime_count + 1;
            end if;
         end if;
      end process;
   end generate;


-- ********************************************
-- ***** SPI Interface                    *****
-- ********************************************

-- Need to forward this port to ADC...
-- Need to include SPI config options...

   spi_slave_inst : entity work.spi_slave
   generic map (
      CPOL => '0', -- Data captured on rising edge, propagated on falling edge
      CPHA => '0',
      ADDR_WIDTH => 8,
      DATA_WIDTH => 16)
   port map (
      nreset       => reset_n,
      spi_clk      => PI_SPI_SCLK_bufg,
      spi_cen      => PI_SPI_CE0_N,
      spi_mosi     => PI_SPI_MOSI,
      spi_miso     => spi_miso,
      addr         => spi_addr,
      data_in      => spi_rdata,
      data_out     => spi_wdata,
      ren          => spi_ren,
      wen          => spi_wen);
   
   -- SPI MISO mux
   PI_SPI_MISO <= spi_miso when PI_SPI_CE0_N = '0' else
                  ADC_MISO when PI_SPI_CE1_N = '0' else 'Z';
                  
   -- Create a write enable & read-enable in the 33M clock domain
   process(clk_33m)
   begin
      if rising_edge(clk_33m) then
         spi_wen_buf <= spi_wen_buf(2 downto 0) & spi_wen;
         spi_ren_buf <= spi_ren_buf(2 downto 0) & spi_ren;
      end if;
   end process;
   
   spi_wen_33m <= '1' when spi_wen_buf(3 downto 2) = "01" else '0';
   spi_ren_33m <= '1' when spi_ren_buf(3 downto 2) = "10" else '0';


   -- Create writeable registers
   process(clk_33m)
   begin
      if startup_reset = '1' then
         -- Set any necessary reset states for any registers here...
         wreg(reg_vfd_ctrl) <= X"8000"; -- Default LCD/VFD timing & interface standard
      elsif rising_edge(clk_33m) then
         if spi_wen_33m = '1' then
            wreg(conv_integer(unsigned(spi_addr))) <= spi_wdata;
         end if;
      end if;
   end process;


   -- Readable register array
   spi_rdata <= rreg(conv_integer(unsigned(spi_addr)));


   -- Create write strobes
   process(clk_33m)
   begin
      if rising_edge(clk_33m) then
         for i in 0 to num_registers-1 loop
            wen(i) <= '0';
         end loop;
         if spi_wen_33m = '1' then
            wen(conv_integer(unsigned(spi_addr))) <= '1';
         end if;
      end if;
   end process;
   
   -- Create read strobes
   ren_gen : for i in 0 to num_registers-1 generate
      ren(i) <= '1' when spi_ren_33m = '1' and conv_integer(unsigned(spi_addr)) = i else '0';
   end generate;
   
-- ********************************************
-- ***** Misc Readable Registers          *****
-- ********************************************

   rreg(reg_build_time0) <= BUILD_TIME(15 downto 0);
   rreg(reg_build_time1) <= BUILD_TIME(31 downto 16);
   rreg(reg_build_time2) <= BUILD_TIME(47 downto 32);

   rreg(reg_test3) <= wreg(reg_test3);
   rreg(reg_test4) <= not wreg(reg_test4);
   rreg(reg_test5) <= wreg(reg_test5);
   rreg(reg_test6) <= wreg(reg_test6);
   rreg(reg_test7) <= wreg(reg_test7);
   
   gpio_mode_reg_gen : if true generate -- Optional if s/w needs to readback what was written
      rreg(reg_gpio1a_mode) <= wreg(reg_gpio1a_mode);
      rreg(reg_gpio1b_mode) <= wreg(reg_gpio1b_mode);
      rreg(reg_gpio1c_mode) <= wreg(reg_gpio1c_mode);
      rreg(reg_gpio2a_mode) <= wreg(reg_gpio2a_mode);
      rreg(reg_gpio2b_mode) <= wreg(reg_gpio2b_mode);
      rreg(reg_gpio3a_mode) <= wreg(reg_gpio3a_mode);
      rreg(reg_gpio3b_mode) <= wreg(reg_gpio3b_mode);
   end generate;

   pwm_ctrl_reg_gen : if ENABLE_PWM_READBACK generate -- Optional if s/w needs to readback what was written
      rreg(reg_pwm0) <= wreg(reg_pwm0);
      rreg(reg_pwm1) <= wreg(reg_pwm1);
      rreg(reg_pwm2) <= wreg(reg_pwm2);
      rreg(reg_pwm3) <= wreg(reg_pwm3);
      rreg(reg_pwm4) <= wreg(reg_pwm4);
      rreg(reg_pwm5) <= wreg(reg_pwm5);
      rreg(reg_pwm6) <= wreg(reg_pwm6);
      rreg(reg_pwm7) <= wreg(reg_pwm7);
   end generate;
   
   runtime_counter_reg_gen : if ENABLE_RUNTIME_COUNTER generate
      rreg(reg_runtime0) <= runtime_count(15 downto 0);
      rreg(reg_runtime1) <= runtime_count(31 downto 16);
   end generate;
   
   rreg(reg_demoseq) <= DEMO_BUILD;

   -- Option registers (allows s/w to identify which options are enabled)
   rreg(reg_options0)(0)  <= '1' when ENABLE_SPI_INTERFACE else '0'; 
   rreg(reg_options0)(1)  <= '1' when ENABLE_I2C_INTERFACE else '0'; 
   rreg(reg_options0)(2)  <= '1' when ENABLE_TESTMODE else '0'; 
   rreg(reg_options0)(3)  <= '1' when ENABLE_LED_CTRL else '0'; 
   rreg(reg_options0)(4)  <= '1' when ENABLE_LCDVFD else '0'; 
   rreg(reg_options0)(5)  <= '1' when ENABLE_PWM_GEN else '0'; 
   rreg(reg_options0)(6)  <= '1' when ENABLE_PWM_SEQ else '0'; 
   rreg(reg_options0)(7)  <= '1' when ENABLE_KBSCAN else '0'; 
   rreg(reg_options0)(8)  <= '1' when ENABLE_TIMER else '0'; 
   rreg(reg_options0)(9)  <= '1' when ENABLE_COUNTER else '0'; 
   rreg(reg_options0)(10) <= '1' when ENABLE_UART1 else '0'; 
   rreg(reg_options0)(11) <= '1' when ENABLE_EXP_F0 else '0'; 
   rreg(reg_options0)(12) <= '1' when ENABLE_EXP_F1 else '0'; 
   rreg(reg_options0)(13) <= '0'; -- Reserved for other option
   rreg(reg_options0)(14) <= '0'; -- Reserved for other option
   rreg(reg_options0)(15) <= '1' when ENABLE_USERLOGIC else '0'; 
   rreg(reg_options1)     <= X"0000"; -- Reserved for other options


-- ********************************************
-- ***** I2C Switch                       *****
-- ********************************************

   -- Note: Includes a fix for the missing 'repeated start' I2C operation that the Pi might not support.
   -- To enable repeated start, the processor must set a bit in the PiXi-200 map to inhibit the automatic stop.
   -- Process: set stop inhibit bit then send data. Reset stop inhibit bit just before sending the final byte to enable the final stop.
   
   i2c_gen : if ENABLE_I2C_INTERFACE generate
   begin
   
      i2c_slave_address <= wreg(reg_i2c_config)(6 downto 0);

      i2c_switch0 : entity work.i2c_switch
      generic map (
         SLAVES => 5)
      port map (
         TIMEOUT_CLK => clk_33m,
         I2C_STOP_INHIBIT => wreg(reg_i2c_config)(7),

         -- Master
         M_SCK => PI_SCK_bufg,
         M_SDA => PI_SDA,
         
         -- Slaves
         S_SCK(0) => EESDC,
         S_SCK(1) => DAC_SCK,
         S_SCK(2) => MMA_SCK,
         S_SCK(3) => MAG_SCK,
         S_SCK(4) => gpio1_sck0,
         S_SDA(0) => EESDA,
         S_SDA(1) => DAC_SDA,
         S_SDA(2) => MMA_SDA,
         S_SDA(3) => MAG_SDA,
         S_SDA(4) => gpio1_sda0);

   end generate;


-- ********************************************
-- ***** PI GPIO Config                   *****
-- ********************************************

   PI_GPIO_GEN(0) <= --MAG_INT when wreg(reg_pi_gpio_cfg0)(1 downto 0) = "01" else
                     --MMA_INT when wreg(reg_pi_gpio_cfg0)(1 downto 0) = "10" else
                     --DAC_RDY when wreg(reg_pi_gpio_cfg0)(1 downto 0) = "11" else
                     'Z';

   PI_GPIO_GEN(1) <= --MAG_INT when wreg(reg_pi_gpio_cfg0)(3 downto 2) = "01" else
                     --MMA_INT when wreg(reg_pi_gpio_cfg0)(3 downto 2) = "10" else
                     --DAC_RDY when wreg(reg_pi_gpio_cfg0)(3 downto 2) = "11" else
                     'Z';

   PI_GPIO_GEN(2) <= --MAG_INT when wreg(reg_pi_gpio_cfg0)(5 downto 4) = "01" else
                     --MMA_INT when wreg(reg_pi_gpio_cfg0)(5 downto 4) = "10" else
                     --DAC_RDY when wreg(reg_pi_gpio_cfg0)(5 downto 4) = "01" else
                     'Z';

   PI_GPIO_GEN(3) <= MAG_INT when wreg(reg_pi_gpio_cfg0)(7 downto 6) = "01" else
                     MMA_INT when wreg(reg_pi_gpio_cfg0)(7 downto 6) = "10" else
                     DAC_RDY when wreg(reg_pi_gpio_cfg0)(7 downto 6) = "11" else
                     'Z';

   PI_GPIO_GEN(4) <= MAG_INT when wreg(reg_pi_gpio_cfg0)(9 downto 8) = "01" else
                     MMA_INT when wreg(reg_pi_gpio_cfg0)(9 downto 8) = "10" else
                     DAC_RDY when wreg(reg_pi_gpio_cfg0)(9 downto 8) = "11" else
                     'Z';

   PI_GPIO_GEN(5) <= MAG_INT when wreg(reg_pi_gpio_cfg0)(11 downto 10) = "01" else
                     MMA_INT when wreg(reg_pi_gpio_cfg0)(11 downto 10) = "10" else
                     '0'     when wreg(reg_pi_gpio_cfg0)(11 downto 10) = "11" else
                     'Z';

-- PI_GPIO_GEN(6) IS RESERVERED FOR FPGA 'PROG' FUNCTION ONLY

-- PI_GPIO_GEN(7, 8, 9, 10) ARE ONLY AVAILABLE ON RASPBERRY PI REV2

   PI_GPIO_GEN(7) <= MAG_INT when wreg(reg_pi_gpio_cfg0)(13 downto 12) = "01" else
                     MMA_INT when wreg(reg_pi_gpio_cfg0)(13 downto 12) = "10" else
                     DAC_RDY when wreg(reg_pi_gpio_cfg0)(13 downto 12) = "11" else
                     'Z';

   PI_GPIO_GEN(8) <= MAG_INT when wreg(reg_pi_gpio_cfg0)(15 downto 14) = "01" else
                     MMA_INT when wreg(reg_pi_gpio_cfg0)(15 downto 14) = "10" else
                     DAC_RDY when wreg(reg_pi_gpio_cfg0)(15 downto 14) = "11" else
                     'Z';

   PI_GPIO_GEN(9) <= MAG_INT when wreg(reg_pi_gpio_cfg1)(1 downto 0) = "01" else
                     MMA_INT when wreg(reg_pi_gpio_cfg1)(1 downto 0) = "10" else
                     DAC_RDY when wreg(reg_pi_gpio_cfg1)(1 downto 0) = "11" else
                     'Z';

   PI_GPIO_GEN(10) <= MAG_INT when wreg(reg_pi_gpio_cfg1)(3 downto 2) = "01" else
                      MMA_INT when wreg(reg_pi_gpio_cfg1)(3 downto 2) = "10" else
                      DAC_RDY when wreg(reg_pi_gpio_cfg1)(3 downto 2) = "11" else
                      'Z';


-- ********************************************
-- ***** DAC                              *****
-- ********************************************

   DAC_LDAC <= '0'; -- Configures the DAC to update the outputs imediately
   
   
-- ********************************************
-- ***** ADC (SPI)                        *****
-- ********************************************
-- ADC sits on the PI's SPI interface channel 1 (of channels 0 & 1) by default
   
   ADC_SCK  <= PI_SPI_SCLK_bufg;
   ADC_MOSI <= PI_SPI_MOSI;
   ADC_CS_N <= PI_SPI_CE1_N when wreg(reg_spi_config)(1) = '0' else PI_SPI_CE0_N;


-- ********************************************
-- ***** Serial / UART                    *****
-- ********************************************

   SOUT <= PI_TXD0;
   PI_RXD0 <= SIN;
   
   RTS <= CTS;

-- Need to add configuration options here, plus an internal UART for the optional second serial channel


-- ********************************************
-- ***** LCD / VF Display (GPIO3)         *****
-- ********************************************

   lcdvfd_gen : if ENABLE_LCDVFD generate

      signal lcd_fifo_rdata : std_logic_vector(15 downto 0);
      signal lcd_fifo_ren : std_logic;
      signal lcd_fifo_empty : std_logic;
      signal lcd_fifo_full : std_logic;
      signal lcd_fifo_level : std_logic_vector(7 downto 0);
      type t_lcd_sm_state is (lcd_sm_idle, lcd_sm_wen, lcd_sm_wen_wait, lcd_sm_ren, lcd_sm_ren_wait);
      signal lcd_sm_state : t_lcd_sm_state;
      signal lcd_wen : std_logic;
      signal lcd_cycle_count : std_logic_vector(23 downto 0);
      signal lcd_timing : std_logic_vector(23 downto 0); -- := X"008000";
      
--      LCD init string
--      constant lcd_init : t_slv16_vector(0 to 127) := (X"8FFF", X"0030", X"8FFF", X"0030", X"8002", X"0030", X"8002", X"0038",
--                                                       X"8002", X"000C", X"8002", X"0001", X"8002", X"0004", X"8FFF", X"8002") & (
--      VFD init string
--      constant lcd_init : t_slv16_vector(0 to 127) := (X"8FFF", X"0030", X"8FFF", X"0030", X"8002", X"0030", X"8002", X"000C",
--                                                       X"8002", X"0001", X"8002", X"001C", X"8002", X"8002", X"8FFF", X"8002") & (
--    VFD Setup String
      constant lcd_init : t_slv16_vector(0 to 127) := (X"0030", X"8FFF", X"0030", X"8002", X"0030", X"8002", X"0038", X"0102",
                                                       X"8002", X"000C", X"8002", X"0001", X"8002", X"0006", X"0002", X"8FFF") & (
--    VFD Graphic Setup String
--      constant lcd_init : t_slv16_vector(0 to 127) := (X"021B", X"0240", X"8001", X"021B", X"0243", X"0201", X"8001", X"8001",
--                                                       X"8001", X"8001", X"8001", X"8001", X"8001", X"8001", X"8001", X"8001") & (
                                                       -- Welcome message next...
                                                       string_to_slv16_vector("Welcome to the PiXi-200                 Now what shall we do today?...                                          "));
      -- Just some text to help line things up...      string_to_slv16_vector("1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012"));

   begin
     
      -- Display FIFO
      lcd_fifo0 : entity work.lcd_fifo 
      generic map (
         WIDTH => 16,
         DEPTH => 96,
         LCD_INIT => lcd_init,
         PREPROG_LEVEL => 95) -- Note: This needs to be high enough to ensure entire init string (lcd_init) is sent.
      port map(
         RESET => startup_reset,
         CLK => clk_33m,
         WR_EN => wen(reg_vfd),
         DIN => wreg(reg_vfd),
         RD_EN => lcd_fifo_ren,
         DOUT => lcd_fifo_rdata,
         -- Status
         LEVEL => lcd_fifo_level,
         FULL => lcd_fifo_full,
         EMPTY => lcd_fifo_empty);
      
      lcd_timing <= X"00" & wreg(reg_vfd_ctrl)(15 downto 8) & X"00";
      
      -- LCD/VFD Output State machine
      process(clk_33m)
      begin
         if startup_reset = '1' then
            lcd_sm_state <= lcd_sm_idle;
            lcd_wen <= '0';
            lcd_fifo_ren <= '0';
         elsif rising_edge(clk_33m) then
            case lcd_sm_state is
               when lcd_sm_idle => -- Pause if necessary & wait for data
                  lcd_wen <= '0';
                  lcd_fifo_ren <= '0';
                  if lcd_cycle_count = "000000" then
                     if lcd_fifo_empty = '0' then
                        if lcd_fifo_rdata(15 downto 12) = X"8" then -- Check for pause request
                           lcd_fifo_ren <= '1';
                           lcd_sm_state <= lcd_sm_ren; -- Bypass write & go straight to ren.
                           lcd_cycle_count(11 downto 0) <= X"000";
                           lcd_cycle_count(23 downto 12) <= lcd_fifo_rdata(11 downto 0); -- Load wait time
                        else
                           lcd_sm_state <= lcd_sm_wen;
                           lcd_wen <= '1';
                           lcd_cycle_count <= lcd_timing;
                        end if;
                     end if;
                  else
                     lcd_cycle_count <= lcd_cycle_count - 1;
                  end if;
               when lcd_sm_wen => -- Write to LCD
                  if lcd_cycle_count = X"000000" then
                     lcd_wen <= '0';
                     lcd_cycle_count <= lcd_timing;
                     lcd_sm_state <= lcd_sm_wen_wait;
                  else
                     lcd_cycle_count <= lcd_cycle_count - 1;
                  end if;
               when lcd_sm_wen_wait =>
                  if lcd_cycle_count = X"000000" then
                     lcd_fifo_ren <= '1';
                     lcd_sm_state <= lcd_sm_ren;
                  else
                     lcd_cycle_count <= lcd_cycle_count - 1;
                  end if;
               when lcd_sm_ren =>
                  lcd_fifo_ren <= '0';
                  lcd_sm_state <= lcd_sm_ren_wait;
               when lcd_sm_ren_wait =>
                  lcd_sm_state <= lcd_sm_idle;
               when others => lcd_sm_state <= lcd_sm_idle;
            end case;            
         end if;
      end process;
      
      gpio3a_vfd(1) <= lcd_fifo_rdata(0);
      gpio3a_vfd(0) <= lcd_fifo_rdata(1);
      gpio3a_vfd(3) <= lcd_fifo_rdata(2);
      gpio3a_vfd(2) <= lcd_fifo_rdata(3);
      gpio3a_vfd(5) <= lcd_fifo_rdata(4);
      gpio3a_vfd(4) <= lcd_fifo_rdata(5);
      gpio3a_vfd(7) <= lcd_fifo_rdata(6);
      gpio3a_vfd(6) <= lcd_fifo_rdata(7);

      gpio3b_vfd(1) <= '0';  -- NC
      gpio3b_vfd(0) <= lcd_fifo_rdata(9);  -- RS
      gpio3b_vfd(3) <= '0'     when wreg(reg_vfd_ctrl)(0) = '0' else not lcd_wen;
      gpio3b_vfd(2) <= lcd_wen when wreg(reg_vfd_ctrl)(0) = '0' else '1';
      gpio3b_vfd(5) <= wreg(reg_gpio3b_out)(4);
      gpio3b_vfd(4) <= wreg(reg_gpio3b_out)(4);
      gpio3b_vfd(7) <= wreg(reg_gpio3b_out)(4);
      gpio3b_vfd(6) <= wreg(reg_gpio3b_out)(4);
      
      gpio3_oe_vfd <= "00"; -- when startup or testmode else wreg(reg_vfd)(13);
      gpio3_tr_vfd <= "00";

      -- Debug...
      leds(20)(6 downto 0) <= lcd_fifo_level(6 downto 0);
      leds(20)(7) <= lcd_fifo_full;

end generate;


-- ********************************************
-- ***** GPI                              *****
-- ********************************************

   -- Note: these registers only use the bottom byte of the 16-bit register space
   
   rreg(reg_gpio1a_in) <= "00000000" & GPIO1(7 downto 0);
   rreg(reg_gpio1b_in) <= "00000000" & GPIO1(15 downto 8);
   rreg(reg_gpio1c_in) <= "00000000" & GPIO1(23 downto 16);

   rreg(reg_gpio2a_in) <= "00000000" & GPIO2(7 downto 0);
   rreg(reg_gpio2b_in) <= "00000000" & GPIO2(15 downto 8);
   
   rreg(reg_gpio3a_in) <= "00000000" & GPIO3(7 downto 0);
   rreg(reg_gpio3b_in) <= "00000000" & GPIO3(15 downto 8);
   

-- ********************************************
-- ***** GPO                              *****
-- ********************************************

   -- GPIO1 is general purpose 3.3V GPIO
   -- Each GPO pin can be an input            (mode = "00") (high impedance), or 
   --                     a registered output (mode = "01") driven by the GPIO1(x)_out register bit, or
   --                     GPIO1 Function 1    (mode = "10") Re-mapped from Raspberry Pi's P1 connector, or
   --                     GPIO1 Function 2    (mode = "11")
   gpio1_io_ctrl_gen : for i in 0 to 7 generate
      GPIO1(i)    <= gpio1_f2(i)             when testmode else
                     wreg(reg_gpio1a_out)(i) when wreg(reg_gpio1a_mode)((i*2)+1 downto i*2) = "01" else
                     gpio1_f1(i)             when wreg(reg_gpio1a_mode)((i*2)+1 downto i*2) = "10" else
                     gpio1_f2(i)             when wreg(reg_gpio1a_mode)((i*2)+1 downto i*2) = "11" else
                     'Z';                                                                  -- "00"
                     
      GPIO1(i+8)  <= gpio1_f2(i+8)           when testmode else
                     wreg(reg_gpio1b_out)(i) when wreg(reg_gpio1b_mode)((i*2)+1 downto i*2) = "01" else
                     gpio1_f1(i+8)           when wreg(reg_gpio1b_mode)((i*2)+1 downto i*2) = "10" else
                     gpio1_f2(i+8)           when wreg(reg_gpio1b_mode)((i*2)+1 downto i*2) = "11" else
                     'Z';                                                                 -- "00"

      GPIO1(i+16) <= 'Z'                     when testmode else
                     wreg(reg_gpio1c_out)(i) when wreg(reg_gpio1c_mode)((i*2)+1 downto i*2) = "01" else
                     gpio1_f1(i+16)          when wreg(reg_gpio1c_mode)((i*2)+1 downto i*2) = "10" else
                     gpio1_f2(i+16)          when wreg(reg_gpio1c_mode)((i*2)+1 downto i*2) = "11" else
                     'Z';                                                                  -- "00"

   end generate;

   gpio1_f1(0)  <= 'Z'; -- 
   gpio1_f1(1)  <= 'Z'; --
--   gpio1_f1(2)  <= PI_SDA;
   gpio1_f1(3)  <= 'Z';
   gpio1_f1(4)  <= PI_SCK;
   gpio1_f1(5)  <= 'Z';
   gpio1_f1(6)  <= PI_GPIO_GCLK;
   gpio1_f1(7)  <= PI_TXD0;
   gpio1_f1(8)  <= 'Z';
   gpio1_f1(9)  <= PI_RXD0;
   gpio1_f1(10) <= PI_GPIO_GEN(0);
   gpio1_f1(11) <= PI_GPIO_GEN(1);
   gpio1_f1(12) <= PI_GPIO_GEN(2);
   gpio1_f1(13) <= 'Z';
   gpio1_f1(14) <= PI_GPIO_GEN(3);
   gpio1_f1(15) <= PI_GPIO_GEN(4);
   gpio1_f1(16) <= 'Z';
   gpio1_f1(17) <= PI_GPIO_GEN(5);
   gpio1_f1(18) <= PI_SPI_MOSI;
   gpio1_f1(19) <= 'Z';
   gpio1_f1(20) <= PI_SPI_MISO;
   gpio1_f1(21) <= 'Z'; --PI_GPIO_GEN(6);
   gpio1_f1(22) <= PI_SPI_SCLK;
   gpio1_f1(23) <= PI_SPI_CE0_N;

   gpio1_f2(11 downto 0)  <= clock_leds;
   gpio1_f2(15 downto 12) <= gpio1_kbscan_out; -- Keyboard scanner output
   gpio1_f2(16) <= gpio1_sck0;
   gpio1_f2(17) <= gpio1_sda0;
   gpio1_f2(19 downto 16) <= "ZZZZ";
   
   -- GPIO2 is general purpose open-collector outputs or PWM control
   -- Each GPO pin can be off / un-used ('0') (mode = "00")
   --                     a registered output (mode = "01") driven by the GPIO2(x)_out register bit, or
   --                     PWM Output          (mode = "10") for servo control or
   --                     (TBD)               (mode = "11")
   gpio2_io_ctrl_gen : for i in 0 to 7 generate
      GPIO2(i)    <= gpio2a_pwm(i)           when testmode or DEMO_BUILD = "0000" else 
                     wreg(reg_gpio2a_out)(i) when wreg(reg_gpio2a_mode)((i*2)+1 downto i*2) = "01" else
                     gpio2a_pwm(i)           when wreg(reg_gpio2a_mode)((i*2)+1 downto i*2) = "10" else
                     --(TBD)                 when wreg(reg_gpio2a_mode)((i*2)+1 downto i*2) = "11" else
                     '0'; -- ("00")
      GPIO2(i+8)  <= gpio2b_pwm(i)           when testmode or DEMO_BUILD = "0000" else 
                     wreg(reg_gpio2b_out)(i) when wreg(reg_gpio2b_mode)((i*2)+1 downto i*2) = "01" else
                     gpio2b_pwm(i)           when wreg(reg_gpio2b_mode)((i*2)+1 downto i*2) = "10" else
                     --(TBD)                 when wreg(reg_gpio2b_mode)((i*2)+1 downto i*2) = "11" else
                     '1'; -- ("00")
   end generate;
   

   -- GPIO3 is general purpose 5V GPIO or LCD/VFD
   -- GPIO3 is arranged in two banks of 8 bits, each bank can be configured separately:
   -- Each bank pin can be an input           (mode = "00") (high-impedance) or 
   --                     a registered output (mode = "01") driven by the GPIO3(x)_out register bit, or
   --                     LCD / VFD output    (mode = "10") LCD/VFD display control
   --                     (TBD)               (mode = "11") or

   GPIO3(7 downto 0)  <= gpio3a_vfd                       when true else --startup or testmode else 
                         wreg(reg_gpio3a_out)(7 downto 0) when wreg(reg_gpio3a_mode)(1 downto 0) = "01" else 
                         gpio3a_vfd                       when wreg(reg_gpio3a_mode)(1 downto 0) = "10" else 
                         "00000000"                       when wreg(reg_gpio3a_mode)(1 downto 0) = "11" else 
                         "ZZZZZZZZ"; -- (when "00")

   GPIO3_OE(0)         <= gpio3_oe_vfd(0)                 when true else -- startup or testmode else 
                          '0'                             when wreg(reg_gpio3a_mode)(1 downto 0) = "01" else
                          gpio3_oe_vfd(0)                 when wreg(reg_gpio3a_mode)(1 downto 0) = "10" else
                          '0'                             when wreg(reg_gpio3a_mode)(1 downto 0) = "11" else
                          '0'; -- (when "00")
                          
   GPIO3_TR(0)         <= gpio3_tr_vfd(0)                 when true else -- startup or testmode else 
                          '0'                             when wreg(reg_gpio3a_mode)(1 downto 0) = "01" else
                          gpio3_tr_vfd(0)                 when wreg(reg_gpio3a_mode)(1 downto 0) = "10" else
                          '0'                             when wreg(reg_gpio3a_mode)(1 downto 0) = "11" else
                          '1'; -- (when "00")

   GPIO3(15 downto 8) <= gpio3b_vfd                       when true else -- startup or testmode else 
                         wreg(reg_gpio3b_out)(7 downto 0) when wreg(reg_gpio3b_mode)(1 downto 0) = "01" else 
                         gpio3b_vfd                       when wreg(reg_gpio3b_mode)(1 downto 0) = "10" else 
                         "00000000"                       when wreg(reg_gpio3b_mode)(1 downto 0) = "11" else 
                         "ZZZZZZZZ"; -- (when "00")

   GPIO3_OE(1)         <= gpio3_oe_vfd(1)                 when true else -- startup or testmode else 
                          '0'                             when wreg(reg_gpio3b_mode)(1 downto 0) = "01" else
                          gpio3_oe_vfd(1)                 when wreg(reg_gpio3b_mode)(1 downto 0) = "10" else
                          '0'                             when wreg(reg_gpio3b_mode)(1 downto 0) = "11" else
                          '0'; -- (when "00")
                          
   GPIO3_TR(1)         <= gpio3_tr_vfd(1)                 when true else -- startup or testmode else 
                          '0'                             when wreg(reg_gpio3b_mode)(1 downto 0) = "01" else
                          gpio3_tr_vfd(1)                 when wreg(reg_gpio3b_mode)(1 downto 0) = "10" else
                          '0'                             when wreg(reg_gpio3b_mode)(1 downto 0) = "11" else
                          '1'; -- (when "00")


-- ********************************************
-- ***** Switches                         *****
-- ********************************************

-- Simple register to read switch on/off status plus an 'event' detection function to detect if
-- a switch has been pressed while not being monitored by the Pi.
-- Event detection is reset when the switch register is read.

   -- Switch register
   rreg(reg_switches) <= "00000000" & sw_event(4) & SW(4) & sw_event(3) & SW(3) & sw_event(2) & SW(2) & sw_event(1) & SW(1);

   process(clk_33m)
   begin
      if reset_p = '1' then
         sw_event <= (others => '0');
      elsif rising_edge(clk_33m) then
         -- Reset sw_event register at the end of a read sw_event register process 
         if ren(reg_switches) = '1' then
            sw_event <= (others => '0');
         end if;
      
         sw_buf <= SW;
         for i in 1 to 4 loop
            if sw_buf(i) /= SW(i) then
               sw_event(i) <= '1';
            end if;
         end loop;
      end if;
   end process;
   

-- ********************************************
-- ***** LED drivers                      *****
-- ********************************************

   -- LED register
   -- 8 x LED drivers, LEDs can be off, on, blink slow or blin fast
   -- Note: slow and fast blink are only enabled with ENABLE_LED_CTRL is true.
   
   led_blink_gen : for i in 0 to 7 generate
      led_blink(i) <= '0' when      wreg(reg_leds)(1+(i*2) downto i*2) = "00" else -- Off
                      clk_1hz when  wreg(reg_leds)(1+(i*2) downto i*2) = "01" and ENABLE_LED_CTRL else -- Slow blink
                      clk_2hz5 when wreg(reg_leds)(1+(i*2) downto i*2) = "10" and ENABLE_LED_CTRL else -- Fast blink
                      '1';                                                         -- On (when = "11")
   end generate;
   
   -- Generate moving led sequence... No real function other than it looks cool...
   -- Note: This code will get optimised out is ENABLE_LED_CTRL is false
   process(clk_33m)
   begin
      if reset_p = '1' then
         moving_leds <= "10000000";
         led_dir <= '0';
      elsif rising_edge(clk_33m) then
         if en_50hz = '1' then
            if moving_leds(0) = '1' then
               led_dir <= '1';
               moving_leds <= moving_leds(6 downto 0) & '0';
            elsif moving_leds(7) = '1' then
               led_dir <= '0';
               moving_leds <= '0' & moving_leds(7 downto 1);
            elsif led_dir = '1' then
               moving_leds <= moving_leds(6 downto 0) & '0';
            else
               moving_leds <= '0' & moving_leds(7 downto 1);
            end if;
         end if;
      end if;
   end process;


   -- Generate moving led sequence... No real function other than it looks cool...
   -- Note: This code will get optimised out is ENABLE_LED_CTRL is false
   process(clk_33m)
   begin
      if reset_p = '1' then
         moving_leds2 <= "10000000";
      elsif rising_edge(clk_33m) then
         if en_5hz = '1' then
            if SW(4) = '1' then
               led_dir2 <= '1';
            elsif SW(3) = '1' then
               led_dir2 <= '0';
            end if;

            if led_dir2 = '1' then
               moving_leds2 <= moving_leds2(6 downto 0) & moving_leds2(7);
            else
               moving_leds2 <= moving_leds2(0) & moving_leds2(7 downto 1);
            end if;
         end if;
      end if;
   end process;


   -- LED Clock...
   -- A 12-bit LED sequence designed for driving 12 LEDs connected to GPIO1
   process(clk_33m)
   begin
      if reset_p = '1' then
         clock_leds <= "100000000000";
      elsif rising_edge(clk_33m) then
         if (en_0hz2 = '1') or (en_5Hz = '1' and DEMO_BUILD = X"0002" and SW(4) = '1') then
            clock_leds <= clock_leds(10 downto 0) & clock_leds(11);
         end if;
      end if;
   end process;
   

   -- LED driver sources (generally used for debugging)
   -- Can be used to select what source control the LEDs. For example, set the LED_CTRL register to 0 and the LEDs are
   -- controlled entirely by software by writing to the LED register. Or set the LED_CTRL register to 1 and the LEDs are
   -- controlled directly by the switches. Or set the LED_CTRL register to 13 (0x0D) to see the serial port activity.
   leds(0)  <= led_blink;                          -- Basic LED control register
   leds(1)  <= not SW(4) & SW(4) & not SW(3) & SW(3) & not SW(2) & SW(2) & not SW(1) & SW(1); -- Use LEDs to test switches
   leds(2)  <= spi_addr;                           -- SPI address register
   leds(3)  <= spi_wdata(7 downto 0);              -- SPI (write) data register (low-byte)
   leds(4)  <= spi_wdata(15 downto 8);             -- SPI (write) data register (high-byte)
   leds(5)  <= wreg(reg_test0)(7 downto 0);        -- test register
   leds(6)  <= rreg(reg_build_time0)(7 downto 0);  -- build_time register (year)
   leds(7)  <= rreg(reg_build_time0)(15 downto 8); -- build_time register (month)
   leds(8)  <= rreg(reg_build_time1)(7 downto 0);  -- build_time register (day)
   leds(9)  <= rreg(reg_build_time1)(15 downto 8); -- build_time register (seconds)
   leds(10) <= rreg(reg_build_time2)(7 downto 0);  -- build_time register (minutes)
   leds(11) <= rreg(reg_build_time2)(15 downto 8); -- build_time register (hour)
   leds(12) <= moving_leds;                        -- Moving '1' LED register
   leds(13) <= PI_TXD0 & SIN & "000" & DAC_RDY & MMA_INT & MAG_INT; -- Serial, DAC, MMA & MAG debug
   leds(16) <= moving_leds2;                       -- Rotating '1' LED register

   -- Multiplex LED driver output source signals based on reg_led_ctrl (when enabled)
   LED <= moving_leds when startup else 
          leds(14)    when testmode else
          leds(1)     when wreg(reg_led_ctrl)(4 downto 0) = "00001" and ENABLE_LED_CTRL else
          leds(2)     when wreg(reg_led_ctrl)(4 downto 0) = "00010" and ENABLE_LED_CTRL else
          leds(3)     when wreg(reg_led_ctrl)(4 downto 0) = "00011" and ENABLE_LED_CTRL else
          leds(4)     when wreg(reg_led_ctrl)(4 downto 0) = "00100" and ENABLE_LED_CTRL else
          leds(5)     when wreg(reg_led_ctrl)(4 downto 0) = "00101" and ENABLE_LED_CTRL else
          leds(6)     when wreg(reg_led_ctrl)(4 downto 0) = "00110" and ENABLE_LED_CTRL else
          leds(7)     when wreg(reg_led_ctrl)(4 downto 0) = "00111" and ENABLE_LED_CTRL else
          leds(8)     when wreg(reg_led_ctrl)(4 downto 0) = "01000" and ENABLE_LED_CTRL else
          leds(9)     when wreg(reg_led_ctrl)(4 downto 0) = "01001" and ENABLE_LED_CTRL else
          leds(10)    when wreg(reg_led_ctrl)(4 downto 0) = "01010" and ENABLE_LED_CTRL else
          leds(11)    when wreg(reg_led_ctrl)(4 downto 0) = "01011" and ENABLE_LED_CTRL else
          leds(12)    when wreg(reg_led_ctrl)(4 downto 0) = "01100" and ENABLE_LED_CTRL else
          leds(13)    when wreg(reg_led_ctrl)(4 downto 0) = "01101" and ENABLE_LED_CTRL else
          leds(14)    when wreg(reg_led_ctrl)(4 downto 0) = "01110" and ENABLE_LED_CTRL else
          leds(15)    when wreg(reg_led_ctrl)(4 downto 0) = "01111" and ENABLE_LED_CTRL else
          leds(16)    when wreg(reg_led_ctrl)(4 downto 0) = "10000" and ENABLE_LED_CTRL else
          leds(17)    when wreg(reg_led_ctrl)(4 downto 0) = "10001" and ENABLE_LED_CTRL else
          leds(18)    when wreg(reg_led_ctrl)(4 downto 0) = "10010" and ENABLE_LED_CTRL else
          leds(19)    when wreg(reg_led_ctrl)(4 downto 0) = "10011" and ENABLE_LED_CTRL else
          leds(20)    when wreg(reg_led_ctrl)(4 downto 0) = "10100" and ENABLE_LED_CTRL else
          leds(21)    when wreg(reg_led_ctrl)(4 downto 0) = "10101" and ENABLE_LED_CTRL else
          leds(22)    when wreg(reg_led_ctrl)(4 downto 0) = "10110" and ENABLE_LED_CTRL else
          leds(23)    when wreg(reg_led_ctrl)(4 downto 0) = "10111" and ENABLE_LED_CTRL else
          leds(24)    when wreg(reg_led_ctrl)(4 downto 0) = "11000" and ENABLE_LED_CTRL else
          leds(25)    when wreg(reg_led_ctrl)(4 downto 0) = "11001" and ENABLE_LED_CTRL else
          leds(26)    when wreg(reg_led_ctrl)(4 downto 0) = "11010" and ENABLE_LED_CTRL else
          leds(27)    when wreg(reg_led_ctrl)(4 downto 0) = "11011" and ENABLE_LED_CTRL else
          leds(28)    when wreg(reg_led_ctrl)(4 downto 0) = "11100" and ENABLE_LED_CTRL else
          leds(29)    when wreg(reg_led_ctrl)(4 downto 0) = "11101" and ENABLE_LED_CTRL else
          leds(30)    when wreg(reg_led_ctrl)(4 downto 0) = "11110" and ENABLE_LED_CTRL else
          leds(31)    when wreg(reg_led_ctrl)(4 downto 0) = "11111" and ENABLE_LED_CTRL else
          leds(0);    -- Default to basic LED control register
   
   
-- ********************************************
-- ***** Keyboard Scanner                 *****
-- ********************************************
-- Note this function required a pull-down resistor on GPIO1(19:16), implemented on-chip, definec in the UCF file.

   kbscan_blk : if ENABLE_KBSCAN generate -- Use a generate to keep any new signal definitions declared within this section of code only - keeps things tidy...
      signal key_pressed : std_logic;
      signal read_data : std_logic_vector(7 downto 0);
      signal empty : std_logic;
      signal full : std_logic;

      attribute keep of key_pressed : signal is "true";
      attribute equivalent_register_removal of key_pressed : signal is "no";
      attribute keep of read_data : signal is "true";
      attribute equivalent_register_removal of read_data : signal is "no";
      attribute keep of empty : signal is "true";
      attribute equivalent_register_removal of empty : signal is "no";
      attribute keep of full : signal is "true";
      attribute equivalent_register_removal of full : signal is "no";

   begin

   leds(14)(0) <= key_code(7);
   leds(14)(1) <= key_code(6);
   leds(14)(2) <= key_code(5);
   leds(14)(3) <= key_code(4);
   leds(14)(4) <= key_code(3);
   leds(14)(5) <= key_code(2);
   leds(14)(6) <= key_code(1);
   leds(14)(7) <= key_code(0);

      kbscan0 : entity work.kbscan 
      generic map (
         ROWS => 4,
         COLUMNS => 4,
         KEY_MAP => "123456789*0#")
      port map (
         RESET => SW(1),
         CLK => clk_33m,
         CLK_EN => '1',
         
         SCAN_OUT => gpio1_kbscan_out,
         SCAN_IN => GPIO1(19 downto 16),
         
         KEY_PRESSED => key_pressed,
         KEY_CODE => key_code);
         

your_instance_name : fifo_generator_v9_3
  PORT MAP (
    clk => clk_33m,
    rst => SW(1),
    din => key_code,
    wr_en => key_pressed,
    rd_en => ren(reg_keypad),
    dout => read_data,
    full => full,
    empty => empty
  );

--      kb_fifo : entity work.simple_fifo
--      generic map(
--         WIDTH => 8,
--         DEPTH => 16)
--      port map(
--         RESET => SW(1),
--         CLK => clk_33m,
--         CLK_EN => '1',
--         
--         WEN => key_pressed,
--         DATA_IN => key_code,
--         REN => ren(reg_keypad),
--         DATA_OUT => read_data, --rreg(reg_keypad)(7 downto 0),
--         
--         LEVEL(4 downto 0) => leds(21)(4 downto 0),
--         LEVEL(7 downto 5) => open,
--         EMPTY => empty,
--         FULL => full);

      rreg(reg_keypad)(7 downto 0) <= read_data;
      rreg(reg_keypad)(8) <= empty;
      rreg(reg_keypad)(9) <= full;

      -- Debug...
      leds(19)(0) <= not leds(19)(0) when rising_edge(clk_33m) and ren(51) = '1';
      leds(19)(1) <= not leds(19)(1) when rising_edge(clk_33m) and ren(reg_keypad) = '1';
      leds(19)(2) <= spi_wen_33m;
      leds(19)(3) <= spi_ren_33m;
      leds(19)(4) <= spi_wen;
      leds(19)(5) <= spi_ren;
      leds(19)(6) <= full;
      leds(19)(7) <= empty;
      leds(21)(5) <= key_pressed;
      leds(21)(6) <= full;
      leds(21)(7) <= empty;
      leds(22)(7 downto 0) <= read_data;
   end generate;
   
   
-- ********************************************
-- ***** Simple PWM controllers           *****
-- ********************************************

-- Note: R/C servos operate over a range from 1ms to 2ms out of 20ms
-- Equivalent to a PWM duty-cycle of 5% to 10%
-- Take care not to drive them outside this range when using this to control R/C servos

-- The default no. of bits for the PWM controller is 10 bits (0 to 1023)
-- Note: frequency is currently fixed to 50Hz but this can be changed. See PWM_PHASE_MAX definition

   pwm_gen : if ENABLE_PWM_GEN generate -- Use a block to keep any new signal definitions declared within this section of code only - keeps things tidy...
      constant PWM_HIGH : std_logic_vector(PWM_BITS-1 downto 0) := (others => '1');
      constant PWM_CHANNELS : integer := 8;
      constant PWM_FREQ : integer := 50; -- PWM frequency (Hz)
      constant PWM_PHASE_MAX : std_logic_vector(23 downto 0) := std_logic_vector(conv_unsigned((33333333 / (2**PWM_BITS * PWM_FREQ)),24));
      signal pwm_phase : std_logic_vector(PWM_BITS-1 downto 0);
      signal pwm_level : t_slv16_vector(PWM_CHANNELS-1 downto 0);
      signal pwm_out : std_logic_vector(PWM_CHANNELS-1 downto 0);
      signal pwm_test_pos : t_slv16_vector(PWM_CHANNELS-1 downto 0);
      signal pwm_test_dir : std_logic_vector(PWM_CHANNELS-1 downto 0);
   begin

      -- PWM clock-enable generator
      -- Runs at PWM_FREQ * 2^PWM_BITS (Hz)
      -- EG. a 50Hz PWM controller set to 10bit resolution (default) runs at 51.2kHz
      process(clk_33m)
      begin
         if reset_n = '0' then
            en_pwm_phase <= X"000000";
         elsif rising_edge(clk_33m) then
            en_pwm <= '0';
            if en_pwm_phase = PWM_PHASE_MAX then 
               en_pwm_phase <= X"000000";
               en_pwm <= '1';
            else
               en_pwm_phase <= en_pwm_phase + 1;
            end if;
         end if;
      end process;

      -- PWM cycle counter / saw-tooth generator
      process(clk_33m)
      begin
         if rising_edge(clk_33m) then
            if en_pwm = '1' then
               if pwm_phase(PWM_BITS-1 downto 0) = all_ones(PWM_BITS-1 downto 0) then
                  pwm_phase <= (others => '0');
               else
                  pwm_phase <= pwm_phase + 1;
               end if;
            end if;
         end if;
      end process;


      pwm_ch_gen : for i in 0 to PWM_CHANNELS-1 generate
      begin

         -- Set PWM level from register or sequencer...
--         pwm_level(i)(PWM_BITS-1 downto 0) <= wreg(reg_pwm0 + i)(PWM_BITS-1 downto 0) when wreg(reg_pwm_cfg)(i) = '0' else pwm_pos(i)(PWM_BITS-1 downto 0);
         pwm_level(i)(PWM_BITS-1 downto 0) <= wreg(reg_pwm0 + i)(PWM_BITS-1 downto 0) when SW(4) = '0' else std_logic_vector(conv_unsigned(102,10));

         process(clk_33m)
         begin
            if rising_edge(clk_33m) then
               if en_pwm = '1' then
                  if pwm_level(i)(PWM_BITS-1 downto 0) < pwm_phase or pwm_level(i)(PWM_BITS-1 downto 0) = all_zeros(PWM_BITS-1 downto 0) then
                      pwm_out(i) <= '0';
                  else
                      pwm_out(i) <= '1';
                  end if;
               end if;
            end if;
         end process;

         -- GPIO2 PWM low-current drivers:
         gpio2a_pwm(i) <= not pwm_out(i);
         -- GPIO2 PWM high-current drivers:
         gpio2b_pwm(i) <= wreg(reg_pwm0 + i)(15) when wreg(reg_pwm_cfg)(i) = '0' else pwm_pos(i)(15);

      end generate;
      

      -- PWM (servo control) test function channel(0)
      process(clk_33m)
      begin
         if DEMO_BUILD = X"0004" then
            pwm_test_pos(0) <= key_code + std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 100/2000),PWM_BITS)); -- 1.5ms (mid-position)
         elsif startup or (SW(1) = '1' and SW(2) = '1') then
            pwm_test_dir(0) <= '1';
            pwm_test_pos(0) <= std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 150/2000),PWM_BITS)); -- 1.5ms (mid-position)
--            pwm_test_pos(0) <= key_code + std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 100/2000),PWM_BITS)); -- 1.5ms (mid-position)
         elsif rising_edge(clk_33m) then
            if en_5hz = '1' then
               if SW(1) = '1' then
                  pwm_test_pos(0) <= pwm_test_pos(0) + 1;
               elsif SW(2) = '1' then
                  pwm_test_pos(0) <= pwm_test_pos(0) - 1;
               end if;

               if pwm_test_pos(0) = std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 200/2000),PWM_BITS)) then  -- 2ms max pulse width
                  pwm_test_pos(0) <= pwm_test_pos(0) - 1;
                  pwm_test_dir(0) <= '0';
               end if;

               if pwm_test_pos(0) = std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 100/2000),PWM_BITS)) then  -- 1ms min pulse width
                  pwm_test_pos(0) <= pwm_test_pos(0) + 1;
                  pwm_test_dir(0) <= '1';
               end if;
            end if;
         end if;
      end process;

      -- PWM (servo control) test function channel(1)
      process(clk_33m)
      begin
         if DEMO_BUILD = X"0004" then
            pwm_test_pos(1) <= key_code + std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 100/2000),PWM_BITS)); -- 1.5ms (mid-position)
         elsif startup or (SW(3) = '1' and SW(4) = '1') then
            pwm_test_dir(1) <= '1';
            pwm_test_pos(1) <= std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 150/2000),PWM_BITS)); -- 1.5ms (mid-position)
--            pwm_test_pos(1) <= key_code + std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 100/2000),PWM_BITS)); -- 1.5ms (mid-position)
         elsif rising_edge(clk_33m) then
            if en_5hz = '1' then
               if SW(3) = '1' then
                  pwm_test_pos(1) <= pwm_test_pos(1) + 1;
               elsif SW(4) = '1' then
                  pwm_test_pos(1) <= pwm_test_pos(1) - 1;
               end if;

               if pwm_test_pos(1) = std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 200/2000),PWM_BITS)) then  -- 2ms max pulse width
                  pwm_test_pos(1) <= pwm_test_pos(1) - 1;
                  pwm_test_dir(1) <= '0';
               end if;

               if pwm_test_pos(1) = std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 100/2000),PWM_BITS)) then  -- 1ms min pulse width
                  pwm_test_pos(1) <= pwm_test_pos(1) + 1;
                  pwm_test_dir(1) <= '1';
               end if;
            end if;
         end if;
      end process;

   end generate; -- pwm_gen


-- ********************************************
-- ***** PWM Sequencer                    *****
-- ********************************************

   pwm_seq_gen : if ENABLE_PWM_SEQ generate
      signal pwm_fifo_empty : std_logic;
      signal pwm_fifo_level : std_logic_vector(7 downto 0);
      signal pwm_fifo_ren : std_logic;
      signal pwm_fifo_rdata : std_logic_vector(63 downto 0);
      signal pwm_seq_en : std_logic;
      signal pwm_seq_override : std_logic;
      constant pwm_mid : std_logic_vector(PWM_BITS-1 downto 0) := std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 2000/2000),PWM_BITS));
      constant pwm_min : std_logic_vector(PWM_BITS-1 downto 0) := std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 1000/2000),PWM_BITS));
      constant pwm_max : std_logic_vector(PWM_BITS-1 downto 0) := std_logic_vector(conv_unsigned(((2**PWM_BITS - 1) * 0/2000),PWM_BITS));
   begin

      -- PWM Sequencer FIFO
      pwm_fifo : entity work.fifo 
      generic map (
         WIDTH => 64,
         DEPTH => 64,
         PRELOAD_LEVEL => 0,
         INIT_00 => X"0040005900400059005900400059004000330066003300660066003300660033",
         INIT_01 => X"003D003D003D003D0038003800380038004D004D004D004D004D004D004D004D",
         INIT_02 => X"0040005900400059005900400059004000330066003300660066003300660033",
         INIT_03 => X"003D003D003D003D0038003800380038004D004D004D004D004D004D004D004D",
         INIT_04 => X"0040005900400059005900400059004000330066003300660066003300660033",
         INIT_05 => X"003D003D003D003D0038003800380038004D004D004D004D004D004D004D004D",
         INIT_06 => X"0040005900400059005900400059004000330066003300660066003300660033",
         INIT_07 => X"003D003D003D003D0038003800380038004D004D004D004D004D004D004D004D")
      port map(
         RESET => startup_reset,
         CLK => clk_33m,
         WR_EN => wen(reg_pwm7),
         DIN(15 downto 0)  => wreg(reg_pwm4),
         DIN(31 downto 16) => wreg(reg_pwm5),
         DIN(47 downto 32) => wreg(reg_pwm6),
         DIN(63 downto 48) => wreg(reg_pwm7),
         RD_EN => pwm_fifo_ren,
         DOUT => pwm_fifo_rdata,
         -- Status
         LEVEL => pwm_fifo_level,
         EMPTY => pwm_fifo_empty);
      
      leds(17)(4 downto 0) <= pwm_fifo_level(4 downto 0);
      leds(17)(5) <= pwm_fifo_empty;
      leds(17)(6) <= pwm_seq_en;
      leds(17)(7) <= pwm_seq_override;

      pwm_seq_en <= wreg(reg_pwm_cfg)(8); -- Set this bit to enable the sequencer to run at 1Hz
      pwm_seq_override <= wreg(reg_pwm_cfg)(9); -- Set this bit to enable the sequencer to run immediately 
      
      process(startup_reset, clk_33m)
      begin
         if startup_reset = '1' then
         elsif rising_edge(clk_33m) then
            pwm_fifo_ren <= '0';
            if (en_1hz = '1' and pwm_seq_en = '1') or pwm_seq_override = '1' then
               if pwm_fifo_empty = '0' then
                  pwm_pos(4)(PWM_BITS-1 downto 0) <= pwm_fifo_rdata(PWM_BITS-1 downto 0);
                  pwm_pos(4)(15)                  <= pwm_fifo_rdata(15);
                  pwm_pos(5)(PWM_BITS-1 downto 0) <= pwm_fifo_rdata(25 downto 16);
                  pwm_pos(5)(15)                  <= pwm_fifo_rdata(31);
                  pwm_pos(6)(PWM_BITS-1 downto 0) <= pwm_fifo_rdata(41 downto 32);
                  pwm_pos(6)(15)                  <= pwm_fifo_rdata(47);
                  pwm_pos(7)(PWM_BITS-1 downto 0) <= pwm_fifo_rdata(57 downto 48);
                  pwm_pos(7)(15)                  <= pwm_fifo_rdata(63);
                  pwm_fifo_ren <= '1';
               else
                  pwm_pos(4)(PWM_BITS-1 downto 0) <= (others => '0');
                  pwm_pos(4)(15)                  <= '0';
                  pwm_pos(5)(PWM_BITS-1 downto 0) <= (others => '0');
                  pwm_pos(5)(15)                  <= '0';
                  pwm_pos(6)(PWM_BITS-1 downto 0) <= (others => '0');
                  pwm_pos(6)(15)                  <= '0';
                  pwm_pos(7)(PWM_BITS-1 downto 0) <= (others => '0');
                  pwm_pos(7)(15)                  <= '0';
               end if;
            end if;
         end if;
      end process;

   end generate; -- pwm_seq_gen


-- ********************************************
-- ***** UARTs                            *****
-- ********************************************
   uart_blk : block
   
   begin
   
   end block;


-- ********************************************
-- ***** Timer Function                   *****
-- ********************************************
   timer_gen : if ENABLE_TIMER generate
   begin
   end generate;

-- ********************************************
-- ***** Counter Function                 *****
-- ********************************************
   counter_gen : if ENABLE_COUNTER generate
      signal count_reset : std_logic;
      signal count_enable : std_logic;
      signal count_clk : std_logic;
      signal count : std_logic_vector(31 downto 0);
   begin
   
      count_clk <=    clk_33m         when wreg(reg_counter_cfg)(3 downto 0) = X"0" else -- 33MHz clock
                      GPIO1(0)        when wreg(reg_counter_cfg)(3 downto 0) = X"1" else -- GPIO1(0)
                      PI_GPIO_GCLK    when wreg(reg_counter_cfg)(3 downto 0) = X"2" else -- PI GPIO_GCLK
                      PI_GPIO_GEN(0)  when wreg(reg_counter_cfg)(3 downto 0) = X"3" else -- PI GPIO_GEN(0)
                      SW(2);                                                             -- SW(2)
                   
      count_enable <= GPIO1(1)        when wreg(reg_counter_cfg)(3 downto 0) = X"0" else -- 33MHz clock
                      GPIO1(1)        when wreg(reg_counter_cfg)(3 downto 0) = X"0" else -- GPIO1(0)
                      PI_GPIO_GEN(1)  when wreg(reg_counter_cfg)(3 downto 0) = X"0" else -- PI GPIO_GCLK
                      PI_GPIO_GEN(1)  when wreg(reg_counter_cfg)(3 downto 0) = X"0" else -- PI GPIO_GEN(0)
                      SW(3);                                                             -- SW(2)

      count_reset <=  GPIO1(2)        when wreg(reg_counter_cfg)(3 downto 0) = X"0" else -- 33MHz clock
                      GPIO1(2)        when wreg(reg_counter_cfg)(3 downto 0) = X"0" else -- GPIO1(0)
                      PI_GPIO_GEN(2)  when wreg(reg_counter_cfg)(3 downto 0) = X"0" else -- PI GPIO_GCLK
                      PI_GPIO_GEN(2)  when wreg(reg_counter_cfg)(3 downto 0) = X"0" else -- PI GPIO_GEN(0)
                      SW(4);                                                             -- SW(2)

      process(count_clk)
      begin
         if count_reset = '1' then
            count <= (others => '0');
         elsif rising_edge(count_clk) then
            if count_enable = '1' then
               count <= count + 1;
            end if;
         end if;
      end process;

      rreg(reg_counter0) <= count(15 downto 0);
      rreg(reg_counter1) <= count(31 downto 16);

   end generate;


-- ********************************************
-- ***** Expansion (routability test)     *****
-- ********************************************

   -- Expansion clock input
   IBUFGDS_inst : IBUFGDS
   generic map (
      DIFF_TERM => TRUE, -- Differential Termination 
      IBUF_DELAY_VALUE => "0",
      IOSTANDARD => "LVDS_33")
   port map (
      O => exp_clk,
      I => EXP_IP(4),
      IB => EXP_IN(4));

   -- Expansion clk output buffer
   OBUFDS_inst : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_33")
   port map (
      O => EXP_OP(9),
      OB => EXP_ON(9),
      I => exp_clk);

   -- Expansion loop-through test
   exp_gen : for i in 0 to 3 generate
   signal n0 : std_logic;
   signal n1 : std_logic;
   begin

      IBUFDS_inst : IBUFDS
      generic map (
         DIFF_TERM => TRUE,
         IBUF_DELAY_VALUE => "0",
         IFD_DELAY_VALUE => "AUTO",
         IOSTANDARD => "LVDS_33")
      port map (
         O => n0,
         I => EXP_IP(i),
         IB => EXP_IN(i));

      process(exp_clk)
      begin
         if rising_edge(exp_clk) then
            n1 <= n0;
         end if;
      end process;

      OBUFDS_inst : OBUFDS
      generic map (
         IOSTANDARD => "LVDS_33")
      port map (
         O => EXP_OP(i+5),
         OB => EXP_ON(i+5),
         I => n1);
 
   end generate;


-- ********************************************
-- ***** USER LOGIC                       *****
-- ********************************************
-- This is a good starting point for customising the FPGA designs or learning VHDL.

   user_logic_gen : if ENABLE_USERLOGIC generate -- Enable this function by setting ENABLE_USERLOGIC to 'true' in the code above.
   
      user_logic0 : entity work.user_logic 
      generic map (
         OPTION_1 => 0,
         OPTION_2 => 0)
      port map(
         RESET => startup_reset,
         CLK => clk_33m,
         SW => SW,
         LEDS => leds(15),
         GPIO1 => gpio1_f3,
         GPIO2 => gpio2_f3,
         GPIO3 => gpio3_f3,
         EXP => exp_f3);

   end generate;
   
   rreg(reg_switches) <= "00000000" & sw_event(4) & SW(4) & sw_event(3) & SW(3) & sw_event(2) & SW(2) & sw_event(1) & SW(1);
   
-- ********************************************
-- ***** Test & Debug                     *****
-- ********************************************

   test_blk : block
   begin
   
   end block;

end rtl;

