#! /bin/sh
# /etc/init.d/pixi 

### BEGIN INIT INFO
# Provides:          pixi
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Simple script to program the PiXi-200 FPGA on boot
# Description:
### END INIT INFO

# If you want a command to always run, put it here

# Carry out specific functions when asked to by the system
case "$1" in
  start)
    echo "Starting PiXi-200"
    # run application you want to start
    /usr/local/bin/gpio load spi
    /usr/local/bin/gpio pixi_prog
    ;;
  stop)
    echo "Stopping PiXi-200"
    # kill application you want to stop
    ;;
  *)
    echo "Usage: /etc/init.d/pixi {start|stop}"
    exit 1
    ;;
esac

exit 0
