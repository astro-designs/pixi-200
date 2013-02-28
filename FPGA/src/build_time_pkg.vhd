-- Build_Time FPGA version tracking file
-- 
library ieee;
use ieee.std_logic_1164.all;
package build_time_pkg is
constant BUILD_TIME : std_logic_vector(47 downto 0) := X"203812260213";
end package build_time_pkg;
