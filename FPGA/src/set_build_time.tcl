# get the time in format HHMMSSDDMMYY
set now [clock seconds]
set build_time [clock format $now -format "%H%M%S%d%m%y"] 
puts "Setting BUILD_TIME constant to (hhmmssDDMMYY) $build_time"
# create a VHDL package file defining a constant called COMPILE_TIME
set fp [open "build_time_pkg.vhd" "w"]
puts $fp "-- Build_Time FPGA version tracking file"
puts $fp "-- "
puts $fp "library ieee;"
puts $fp "use ieee.std_logic_1164.all;"
puts $fp "package build_time_pkg is"
puts $fp "constant BUILD_TIME : std_logic_vector(47 downto 0) := X\"$build_time\";"
puts $fp "end package build_time_pkg;"
close $fp