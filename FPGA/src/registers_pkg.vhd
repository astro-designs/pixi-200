-- PiXi-200 register definition package VHDL
-- Astro Designs Ltd.
-- $Id:$

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.types_pkg.all;

package registers_pkg is

   constant num_registers    : integer := 256;

   constant reg_build_time0  : integer := 16#00#;
   constant reg_build_time1  : integer := 16#01#;
   constant reg_build_time2  : integer := 16#02#;

   constant reg_test0        : integer := 16#00#;
   constant reg_test1        : integer := 16#01#;
   constant reg_test2        : integer := 16#02#;
   constant reg_test3        : integer := 16#03#;
   constant reg_test4        : integer := 16#04#;
   constant reg_test5        : integer := 16#05#;
   constant reg_test6        : integer := 16#06#;
   constant reg_test7        : integer := 16#07#;

   constant reg_i2c_config   : integer := 16#08#;
   constant reg_spi_config   : integer := 16#09#;

   constant reg_pi_gpio_cfg0 : integer := 16#10#;
   constant reg_pi_gpio_cfg1 : integer := 16#11#;

   constant reg_gpio1a_in    : integer := 16#20#;
   constant reg_gpio1b_in    : integer := 16#21#;
   constant reg_gpio1c_in    : integer := 16#22#;
   constant reg_gpio2a_in    : integer := 16#23#;
   constant reg_gpio2b_in    : integer := 16#24#;
   constant reg_gpio3a_in    : integer := 16#25#;
   constant reg_gpio3b_in    : integer := 16#26#;
   
   constant reg_gpio1a_out   : integer := 16#20#;
   constant reg_gpio1b_out   : integer := 16#21#;
   constant reg_gpio1c_out   : integer := 16#22#;
   constant reg_gpio2a_out   : integer := 16#23#;
   constant reg_gpio2b_out   : integer := 16#24#;
   constant reg_gpio3a_out   : integer := 16#25#;
   constant reg_gpio3b_out   : integer := 16#26#;

   constant reg_gpio1a_mode  : integer := 16#27#;
   constant reg_gpio1b_mode  : integer := 16#28#;
   constant reg_gpio1c_mode  : integer := 16#29#;
   constant reg_gpio2a_mode  : integer := 16#2A#;
   constant reg_gpio2b_mode  : integer := 16#2B#;
   constant reg_gpio3a_mode  : integer := 16#2C#;
   constant reg_gpio3b_mode  : integer := 16#2D#;
   
   constant reg_leds         : integer := 16#30#;
   constant reg_led_ctrl     : integer := 16#31#;
   constant reg_switches     : integer := 16#32#;
   constant reg_keypad       : integer := 16#33#;

   constant reg_vfd          : integer := 16#38#;
   constant reg_vfd_ctrl     : integer := 16#39#;

   constant reg_pwm0         : integer := 16#40#;
   constant reg_pwm1         : integer := 16#41#;
   constant reg_pwm2         : integer := 16#42#;
   constant reg_pwm3         : integer := 16#43#;
   constant reg_pwm4         : integer := 16#44#;
   constant reg_pwm5         : integer := 16#45#;
   constant reg_pwm6         : integer := 16#46#;
   constant reg_pwm7         : integer := 16#47#;
   constant reg_pwm_gain     : integer := 16#48#;
   constant reg_pwm_offset   : integer := 16#49#;
   constant reg_pwm_cfg      : integer := 16#4F#;
   constant reg_timer0       : integer := 16#50#;
   constant reg_timer1       : integer := 16#51#;
   constant reg_timer_cfg    : integer := 16#54#;
   constant reg_counter0     : integer := 16#58#;
   constant reg_counter1     : integer := 16#59#;
   constant reg_counter_cfg  : integer := 16#5C#;

   constant reg_runtime0     : integer := 16#F0#;
   constant reg_runtime1     : integer := 16#F1#;
   constant reg_demoseq      : integer := 16#F8#;
   constant reg_options0     : integer := 16#FE#;
   constant reg_options1     : integer := 16#FF#;

end package;

