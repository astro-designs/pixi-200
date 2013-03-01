/*
 * gpio.c:
 *	Swiss-Army-Knife, Set-UID command-line interface to the Raspberry
 *	Pi's GPIO.
 *	Copyright (c) 2012 Gordon Henderson
 ***********************************************************************
 * This file is part of wiringPi:
 *	https://projects.drogon.net/raspberry-pi/wiringpi/
 *
 *    wiringPi is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU Lesser General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    wiringPi is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public License
 *    along with wiringPi.  If not, see <http://www.gnu.org/licenses/>.
 ***********************************************************************
 * Added functionality to program, operate & test the PiXi-200 FPGA
 * Astro Designs Ltd. February 2012
 ***********************************************************************
 */


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <fcntl.h>

#include <wiringPi.h>
#include <gertboard.h>

#ifndef TRUE
#  define	TRUE	(1==1)
#  define	FALSE	(1==2)
#endif

#define VERSION "1.4"


/***********************************************************************
 * PiXi-200 Specific definitions
 ***********************************************************************
*/
#define FPGAFILE     "/home/pixi-200/pixi.bin"          // FPGA default configuration file
#define FPGADEMO_001 "/home/pixi-200/pixi_demo_001.bin" // FPGA demo configuration file
#define FPGADEMO_002 "/home/pixi-200/pixi_demo_002.bin" // FPGA demo configuration file
#define FPGADEMO_003 "/home/pixi-200/pixi_demo_003.bin" // FPGA demo configuration file
#define FPGADEMO_004 "/home/pixi-200/pixi_demo_004.bin" // FPGA demo configuration file
#define FPGADEMO_005 "/home/pixi-200/pixi_demo_005.bin" // FPGA demo configuration file
#define FPGADEMO_006 "/home/pixi-200/pixi_demo_006.bin" // FPGA demo configuration file
#define PROG_PIN 6                                      // GPIO(6)
#define INIT_PIN 2                                      // GPIO(2) Note this pin is different for a rev1 or rev 2 board but wiringPi sorts this out very nicely!
#define CCLK_PIN 0                                      // GPIO(0)
#define DATA_PIN 1                                      // GPIO(1)


static int wpMode ;

char *usage = "Usage: gpio -v\n"
              "       gpio -h\n"
              "       gpio [-g] <read/write/pwm/mode> ...\n"
              "       gpio [-p] <read/write/mode> ...\n"
	      "       gpio readall\n"
	      "       gpio unexportall/exports ...\n"
	      "       gpio export/edge/unexport ...\n"
	      "       gpio drive <group> <value>\n"
	      "       gpio pwm-bal/pwm-ms \n"
	      "       gpio pwmr <range> \n"
	      "       gpio pwmc <divider> \n"
	      "       gpio load spi/i2c\n"
	      "       gpio gbr <channel>\n"
	      "       gpio gbw <channel> <value>\n"
	      "       gpio pixi_prog\n"
	      "       gpio spi_set <address> <data>\n"
	      "       gpio spi_get <address> <data>" ;	// No trailing newline needed here.


/*
 * changeOwner:
 *	Change the ownership of the file to the real userId of the calling
 *	program so we can access it.
 *********************************************************************************
 */

static void changeOwner (char *cmd, char *file)
{
  uid_t uid = getuid () ;
  uid_t gid = getgid () ;

  if (chown (file, uid, gid) != 0)
  {
    if (errno == ENOENT)	// Warn that it's not there
      fprintf (stderr, "%s: Warning: File not present: %s\n", cmd, file) ;
    else
    {
      fprintf (stderr, "%s: Unable to change ownership of %s: %s\n", cmd, file, strerror (errno)) ;
      exit (1) ;
    }
  }
}


/*
 * moduleLoaded:
 *	Return true/false if the supplied module is loaded
 *********************************************************************************
 */

static int moduleLoaded (char *modName)
{
  int len   = strlen (modName) ;
  int found = FALSE ;
  FILE *fd = fopen ("/proc/modules", "r") ;
  char line [80] ;

  if (fd == NULL)
  {
    fprintf (stderr, "gpio: Unable to check modules: %s\n", strerror (errno)) ;
    exit (1) ;
  }

  while (fgets (line, 80, fd) != NULL)
  {
    if (strncmp (line, modName, len) != 0)
      continue ;

    found = TRUE ;
    break ;
  }

  fclose (fd) ;

  return found ;
}


/*
 * doLoad:
 *	Load either the spi or i2c modules and change device ownerships, etc.
 *********************************************************************************
 */

static void _doLoadUsage (char *argv [])
{
  fprintf (stderr, "Usage: %s load <spi/i2c>\n", argv [0]) ;
  exit (1) ;
}

static void doLoad (int argc, char *argv [])
{
  char *module ;
  char cmd [80] ;
  char *file1, *file2 ;

  if (argc != 3)
    _doLoadUsage (argv) ;

  /**/ if (strcasecmp (argv [2], "spi") == 0)
  {
    module = "spi_bcm2708" ;
    file1  = "/dev/spidev0.0" ;
    file2  = "/dev/spidev0.1" ;
  }
  else if (strcasecmp (argv [2], "i2c") == 0)
  {
    module = "i2c_bcm2708" ;
    file1  = "/dev/i2c-0" ;
    file2  = "/dev/i2c-1" ;
  }
  else
    _doLoadUsage (argv) ;

  if (!moduleLoaded (module))
  {
    sprintf (cmd, "modprobe %s", module) ;
    system (cmd) ;
  }

  if (!moduleLoaded (module))
  {
    fprintf (stderr, "%s: Unable to load %s\n", argv [0], module) ;
    exit (1) ;
  }

  sleep (1) ;	// To let things get settled

  changeOwner (argv [0], file1) ;
  changeOwner (argv [0], file2) ;
}


/*
 * doReadall:
 *	Read all the GPIO pins
 *********************************************************************************
 */

static char *pinNames [] =
{
  "GPIO 0",
  "GPIO 1",
  "GPIO 2",
  "GPIO 3",
  "GPIO 4",
  "GPIO 5",
  "GPIO 6",
  "GPIO 7",
  "SDA   ",
  "SCL   ",
  "CE0   ",
  "CE1   ",
  "MOSI  ",
  "MISO  ",
  "SCLK  ",
  "TxD   ",
  "RxD   ",
  "GPIO 8",
  "GPIO 9",
  "GPIO10",
  "GPIO11",
} ;

static void doReadall (void)
{
  int pin ;

  printf ("+----------+------+--------+-------+\n") ;
  printf ("| wiringPi | GPIO | Name   | Value |\n") ;
  printf ("+----------+------+--------+-------+\n") ;

  for (pin = 0 ; pin < NUM_PINS ; ++pin)
    printf ("| %6d   | %3d  | %s | %s  |\n",
	pin, wpiPinToGpio (pin),
	pinNames [pin], 
	digitalRead (pin) == HIGH ? "High" : "Low ") ;

  printf ("+----------+------+--------+-------+\n") ;

  if (piBoardRev () == 1)
    return ;

  for (pin = 17 ; pin <= 20 ; ++pin)
    printf ("| %6d   | %3d  | %s | %s  |\n",
	pin, wpiPinToGpio (pin),
	pinNames [pin], 
	digitalRead (pin) == HIGH ? "High" : "Low ") ;

  printf ("+----------+------+--------+-------+\n") ;
}


/*
 * doExports:
 *	List all GPIO exports
 *********************************************************************************
 */

static void doExports (int argc, char *argv [])
{
  int fd ;
  int i, l, first ;
  char fName [128] ;
  char buf [16] ;

// Rather crude, but who knows what others are up to...

  for (first = 0, i = 0 ; i < 64 ; ++i)
  {

// Try to read the direction

    sprintf (fName, "/sys/class/gpio/gpio%d/direction", i) ;
    if ((fd = open (fName, O_RDONLY)) == -1)
      continue ;

    if (first == 0)
    {
      ++first ;
      printf ("GPIO Pins exported:\n") ;
    }

    printf ("%4d: ", i) ;

    if ((l = read (fd, buf, 16)) == 0)
      sprintf (buf, "%s", "?") ;
 
    buf [l] = 0 ;
    if ((buf [strlen (buf) - 1]) == '\n')
      buf [strlen (buf) - 1] = 0 ;

    printf ("%-3s", buf) ;

    close (fd) ;

// Try to Read the value

    sprintf (fName, "/sys/class/gpio/gpio%d/value", i) ;
    if ((fd = open (fName, O_RDONLY)) == -1)
    {
      printf ("No Value file (huh?)\n") ;
      continue ;
    }

    if ((l = read (fd, buf, 16)) == 0)
      sprintf (buf, "%s", "?") ;

    buf [l] = 0 ;
    if ((buf [strlen (buf) - 1]) == '\n')
      buf [strlen (buf) - 1] = 0 ;

    printf ("  %s", buf) ;

// Read any edge trigger file

    sprintf (fName, "/sys/class/gpio/gpio%d/edge", i) ;
    if ((fd = open (fName, O_RDONLY)) == -1)
    {
      printf ("\n") ;
      continue ;
    }

    if ((l = read (fd, buf, 16)) == 0)
      sprintf (buf, "%s", "?") ;

    buf [l] = 0 ;
    if ((buf [strlen (buf) - 1]) == '\n')
      buf [strlen (buf) - 1] = 0 ;

    printf ("  %-8s\n", buf) ;

    close (fd) ;
  }
}


/*
 * doExport:
 *	gpio export pin mode
 *	This uses the /sys/class/gpio device interface.
 *********************************************************************************
 */

void doExport (int argc, char *argv [])
{
  FILE *fd ;
  int pin ;
  char *mode ;
  char fName [128] ;

  if (argc != 4)
  {
    fprintf (stderr, "Usage: %s export pin mode\n", argv [0]) ;
    exit (1) ;
  }

  pin = atoi (argv [2]) ;

  mode = argv [3] ;

  if ((fd = fopen ("/sys/class/gpio/export", "w")) == NULL)
  {
    fprintf (stderr, "%s: Unable to open GPIO export interface: %s\n", argv [0], strerror (errno)) ;
    exit (1) ;
  }

  fprintf (fd, "%d\n", pin) ;
  fclose (fd) ;

  sprintf (fName, "/sys/class/gpio/gpio%d/direction", pin) ;
  if ((fd = fopen (fName, "w")) == NULL)
  {
    fprintf (stderr, "%s: Unable to open GPIO direction interface for pin %d: %s\n", argv [0], pin, strerror (errno)) ;
    exit (1) ;
  }

  /**/ if ((strcasecmp (mode, "in")  == 0) || (strcasecmp (mode, "input")  == 0))
    fprintf (fd, "in\n") ;
  else if ((strcasecmp (mode, "out") == 0) || (strcasecmp (mode, "output") == 0))
    fprintf (fd, "out\n") ;
  else
  {
    fprintf (stderr, "%s: Invalid mode: %s. Should be in or out\n", argv [1], mode) ;
    exit (1) ;
  }

  fclose (fd) ;

// Change ownership so the current user can actually use it!

  sprintf (fName, "/sys/class/gpio/gpio%d/value", pin) ;
  changeOwner (argv [0], fName) ;

  sprintf (fName, "/sys/class/gpio/gpio%d/edge", pin) ;
  changeOwner (argv [0], fName) ;

}


/*
 * doEdge:
 *	gpio edge pin mode
 *	Easy access to changing the edge trigger on a GPIO pin
 *	This uses the /sys/class/gpio device interface.
 *********************************************************************************
 */

void doEdge (int argc, char *argv [])
{
  FILE *fd ;
  int pin ;
  char *mode ;
  char fName [128] ;

  if (argc != 4)
  {
    fprintf (stderr, "Usage: %s edge pin mode\n", argv [0]) ;
    exit (1) ;
  }

  pin  = atoi (argv [2]) ;
  mode = argv [3] ;

// Export the pin and set direction to input

  if ((fd = fopen ("/sys/class/gpio/export", "w")) == NULL)
  {
    fprintf (stderr, "%s: Unable to open GPIO export interface: %s\n", argv [0], strerror (errno)) ;
    exit (1) ;
  }

  fprintf (fd, "%d\n", pin) ;
  fclose (fd) ;

  sprintf (fName, "/sys/class/gpio/gpio%d/direction", pin) ;
  if ((fd = fopen (fName, "w")) == NULL)
  {
    fprintf (stderr, "%s: Unable to open GPIO direction interface for pin %d: %s\n", argv [0], pin, strerror (errno)) ;
    exit (1) ;
  }

  fprintf (fd, "in\n") ;
  fclose (fd) ;

  sprintf (fName, "/sys/class/gpio/gpio%d/edge", pin) ;
  if ((fd = fopen (fName, "w")) == NULL)
  {
    fprintf (stderr, "%s: Unable to open GPIO edge interface for pin %d: %s\n", argv [0], pin, strerror (errno)) ;
    exit (1) ;
  }

  /**/ if (strcasecmp (mode, "none")    == 0) fprintf (fd, "none\n") ;
  else if (strcasecmp (mode, "rising")  == 0) fprintf (fd, "rising\n") ;
  else if (strcasecmp (mode, "falling") == 0) fprintf (fd, "falling\n") ;
  else if (strcasecmp (mode, "both")    == 0) fprintf (fd, "both\n") ;
  else
  {
    fprintf (stderr, "%s: Invalid mode: %s. Should be none, rising, falling or both\n", argv [1], mode) ;
    exit (1) ;
  }

// Change ownership of the value and edge files, so the current user can actually use it!

  sprintf (fName, "/sys/class/gpio/gpio%d/value", pin) ;
  changeOwner (argv [0], fName) ;

  sprintf (fName, "/sys/class/gpio/gpio%d/edge", pin) ;
  changeOwner (argv [0], fName) ;

  fclose (fd) ;
}


/*
 * doUnexport:
 *	gpio unexport pin
 *	This uses the /sys/class/gpio device interface.
 *********************************************************************************
 */

void doUnexport (int argc, char *argv [])
{
  FILE *fd ;
  int pin ;

  if (argc != 3)
  {
    fprintf (stderr, "Usage: %s unexport pin\n", argv [0]) ;
    exit (1) ;
  }

  pin = atoi (argv [2]) ;

  if ((fd = fopen ("/sys/class/gpio/unexport", "w")) == NULL)
  {
    fprintf (stderr, "%s: Unable to open GPIO export interface\n", argv [0]) ;
    exit (1) ;
  }

  fprintf (fd, "%d\n", pin) ;
  fclose (fd) ;
}


/*
 * doUnexportAll:
 *	gpio unexportall
 *	Un-Export all the GPIO pins.
 *	This uses the /sys/class/gpio device interface.
 *********************************************************************************
 */

void doUnexportall (int argc, char *argv [])
{
  FILE *fd ;
  int pin ;

  for (pin = 0 ; pin < 63 ; ++pin)
  {
    if ((fd = fopen ("/sys/class/gpio/unexport", "w")) == NULL)
    {
      fprintf (stderr, "%s: Unable to open GPIO export interface\n", argv [0]) ;
      exit (1) ;
    }
    fprintf (fd, "%d\n", pin) ;
    fclose (fd) ;
  }
}


/*
 * doMode:
 *	gpio mode pin mode ...
 *********************************************************************************
 */

void doMode (int argc, char *argv [])
{
  int pin ;
  char *mode ;

  if (argc != 4)
  {
    fprintf (stderr, "Usage: %s mode pin mode\n", argv [0]) ;
    exit (1) ;
  }

  pin = atoi (argv [2]) ;

  if ((wpMode == WPI_MODE_PINS) && ((pin < 0) || (pin >= NUM_PINS)))
    return ;

  mode = argv [3] ;

  /**/ if (strcasecmp (mode, "in")   == 0) pinMode         (pin, INPUT) ;
  else if (strcasecmp (mode, "out")  == 0) pinMode         (pin, OUTPUT) ;
  else if (strcasecmp (mode, "pwm")  == 0) pinMode         (pin, PWM_OUTPUT) ;
  else if (strcasecmp (mode, "up")   == 0) pullUpDnControl (pin, PUD_UP) ;
  else if (strcasecmp (mode, "down") == 0) pullUpDnControl (pin, PUD_DOWN) ;
  else if (strcasecmp (mode, "tri")  == 0) pullUpDnControl (pin, PUD_OFF) ;
  else
  {
    fprintf (stderr, "%s: Invalid mode: %s. Should be in/out/pwm/up/down/tri\n", argv [1], mode) ;
    exit (1) ;
  }
}


/*
 * doPadDrive:
 *	gpio drive group value
 *********************************************************************************
 */

static void doPadDrive (int argc, char *argv [])
{
  int group, val ;

  if (argc != 4)
  {
    fprintf (stderr, "Usage: %s drive group value\n", argv [0]) ;
    exit (1) ;
  }

  group = atoi (argv [2]) ;
  val   = atoi (argv [3]) ;

  if ((group < 0) || (group > 2))
  {
    fprintf (stderr, "%s: drive group not 0, 1 or 2: %d\n", argv [0], group) ;
    exit (1) ;
  }

  if ((val < 0) || (val > 7))
  {
    fprintf (stderr, "%s: drive value not 0-7: %d\n", argv [0], val) ;
    exit (1) ;
  }

  setPadDrive (group, val) ;
}


/*
 * doGbw:
 *	gpio gbw channel value
 *********************************************************************************
 */

static void doGbw (int argc, char *argv [])
{
  int channel, value ;

  if (argc != 4)
  {
    fprintf (stderr, "Usage: %s gbr <channel> <value>\n", argv [0]) ;
    exit (1) ;
  }

  channel = atoi (argv [2]) ;
  value   = atoi (argv [3]) ;

  if ((channel < 0) || (channel > 1))
  {
    fprintf (stderr, "%s: channel must be 0 or 1\n", argv [0]) ;
    exit (1) ;
  }

  if ((value < 0) || (value > 1023))
  {
    fprintf (stderr, "%s: value must be from 0 to 255\n", argv [0]) ;
    exit (1) ;
  }

  if (gertboardSPISetup () == -1)
  {
    fprintf (stderr, "Unable to initialise the Gertboard SPI interface: %s\n", strerror (errno)) ;
    exit (1) ;
  }

  gertboardAnalogWrite (channel, value) ;
}


/*
 * doGbr:
 *	gpio gbr channel
 *********************************************************************************
 */

static void doGbr (int argc, char *argv [])
{
  int channel ;

  if (argc != 3)
  {
    fprintf (stderr, "Usage: %s gbr <channel>\n", argv [0]) ;
    exit (1) ;
  }

  channel = atoi (argv [2]) ;

  if ((channel < 0) || (channel > 1))
  {
    fprintf (stderr, "%s: channel must be 0 or 1\n", argv [0]) ;
    exit (1) ;
  }

  if (gertboardSPISetup () == -1)
  {
    fprintf (stderr, "Unable to initialise the Gertboard SPI interface: %s\n", strerror (errno)) ;
    exit (1) ;
  }

  printf ("%d\n",gertboardAnalogRead (channel)) ;
}



/*
 * doWrite:
 *	gpio write pin value
 *********************************************************************************
 */

static void doWrite (int argc, char *argv [])
{
  int pin, val ;

  if (argc != 4)
  {
    fprintf (stderr, "Usage: %s write pin value\n", argv [0]) ;
    exit (1) ;
  }

  pin = atoi (argv [2]) ;

  if ((wpMode == WPI_MODE_PINS) && ((pin < 0) || (pin >= NUM_PINS)))
    return ;

  val = atoi (argv [3]) ;

  /**/ if (val == 0)
    digitalWrite (pin, LOW) ;
  else
    digitalWrite (pin, HIGH) ;
}


/*
 * doRead:
 *	Read a pin and return the value
 *********************************************************************************
 */

void doRead (int argc, char *argv []) 
{
  int pin, val ;

  if (argc != 3)
  {
    fprintf (stderr, "Usage: %s read pin\n", argv [0]) ;
    exit (1) ;
  }

  pin = atoi (argv [2]) ;

  if ((wpMode == WPI_MODE_PINS) && ((pin < 0) || (pin >= NUM_PINS)))
  {
    printf ("0\n") ;
    return ;
  }

  val = digitalRead (pin) ;

  printf ("%s\n", val == 0 ? "0" : "1") ;
}


/*
 * doPwm:
 *	Output a PWM value on a pin
 *********************************************************************************
 */

void doPwm (int argc, char *argv [])
{
  int pin, val ;

  if (argc != 4)
  {
    fprintf (stderr, "Usage: %s pwm <pin> <value>\n", argv [0]) ;
    exit (1) ;
  }

  pin = atoi (argv [2]) ;

  if ((wpMode == WPI_MODE_PINS) && ((pin < 0) || (pin >= NUM_PINS)))
    return ;

  val = atoi (argv [3]) ;

  pwmWrite (pin, val) ;
}


/*
 * doPwmMode: doPwmRange: doPwmClock:
 *	Change the PWM mode, range and clock divider values
 *********************************************************************************
 */

static void doPwmMode (int mode)
{
  pwmSetMode (mode) ;
}

static void doPwmRange (int argc, char *argv [])
{
  unsigned int range ;

  if (argc != 3)
  {
    fprintf (stderr, "Usage: %s pwmr <range>\n", argv [0]) ;
    exit (1) ;
  }

  range = (unsigned int)strtoul (argv [2], NULL, 10) ;

  if (range == 0)
  {
    fprintf (stderr, "%s: range must be > 0\n", argv [0]) ;
    exit (1) ;
  }

  pwmSetRange (range) ;
}

static void doPwmClock (int argc, char *argv [])
{
  unsigned int clock ;

  if (argc != 3)
  {
    fprintf (stderr, "Usage: %s pwmc <clock>\n", argv [0]) ;
    exit (1) ;
  }

  clock = (unsigned int)strtoul (argv [2], NULL, 10) ;

  if ((clock < 1) || (clock > 4095))
  {
    fprintf (stderr, "%s: clock must be between 0 and 4096\n", argv [0]) ;
    exit (1) ;
  }

  pwmSetClock (clock) ;
}


/*
 * doSPIset:
 *	gpio SPI register write ...
 *********************************************************************************
 */

int pixi_spi_set (int channel, int address, int data)
{
  uint8_t outbuffer [4] ;
  
//  if (wiringPiSPISetup (channel, 8000000) < 0) { // setup for 8MHz
//    fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
//    exit(1);
//  }
 
  // load output buffer and send it out
  outbuffer [0] =  address & 0x00ff;
  outbuffer [1] =            0x0040; // Enable write
  outbuffer [2] = (data    & 0xff00) >> 8;
  outbuffer [3] =  data    & 0x00ff;
 
  wiringPiSPIDataRW (channel, outbuffer, 4) ;

  return(outbuffer[3] + (outbuffer[2] << 8));
}


/*
 * doSPIget:
 *	gpio SPI register write ...
 *********************************************************************************
 */

int pixi_spi_get (int channel, int address, int data)
{
  uint8_t outbuffer [4] ;

//  if (wiringPiSPISetup (channel, 8000000) < 0) { // setup for 8MHz
//    fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
//    exit(1);
//  }
 
  // load output buffer and send it out
  outbuffer [0] =  address & 0x00ff;
  outbuffer [1] =            0x0080; // Enable read
  outbuffer [2] = (data    & 0xff00) >> 8;
  outbuffer [3] =  data    & 0x00ff;
 
  wiringPiSPIDataRW (channel, outbuffer, 4) ;

  return(outbuffer[3] + (outbuffer[2] << 8));
}


/*
 * doPixiGPIOCheck
 * gpio test function
 *********************************************************************************
 */

int pixi_gpiocheck (int test, int test_data)
{
  int reg_a;
  int reg_b;
  int spi_dout;
  int spi_din;
  int invert = 0x0000;
  int gpio_errors;
  

  if (test == 1) {
    reg_a = 0x20;
    reg_b = 0x21;
    // Setup GPIO1a for output (all bits)
    pixi_spi_set(0, 0x27, 0x5555);
    // Setup GPIO1b for input (all bits)
    pixi_spi_set(0, 0x28, 0x0000);
    // Setup GPIO1c for input (all bits)
    pixi_spi_set(0, 0x29, 0x0000);
  }
  
  if (test == 2) {
    reg_a = 0x20;
    reg_b = 0x22;
    // Setup GPIO1a for output (all bits)
    pixi_spi_set(0, 0x27, 0x5555);
    // Setup GPIO1b for input (all bits)
    pixi_spi_set(0, 0x28, 0x0000);
    // Setup GPIO1c for input (all bits)
    pixi_spi_set(0, 0x29, 0x0000);
  }

  if (test == 3) {
    reg_a = 0x21;
    reg_b = 0x20;
    // Setup GPIO1a for output (all bits)
    pixi_spi_set(0, 0x27, 0x0000);
    // Setup GPIO1b for input (all bits)
    pixi_spi_set(0, 0x28, 0x5555);
    // Setup GPIO1c for input (all bits)
    pixi_spi_set(0, 0x29, 0x0000);
  }

  if (test == 4) {
    reg_a = 0x21;
    reg_b = 0x22;
    // Setup GPIO1a for output (all bits)
    pixi_spi_set(0, 0x27, 0x0000);
    // Setup GPIO1b for input (all bits)
    pixi_spi_set(0, 0x28, 0x5555);
    // Setup GPIO1c for input (all bits)
    pixi_spi_set(0, 0x29, 0x0000);
  }

  if (test == 5) {
    reg_a = 0x22;
    reg_b = 0x20;
    // Setup GPIO1a for output (all bits)
    pixi_spi_set(0, 0x27, 0x0000);
    // Setup GPIO1b for input (all bits)
    pixi_spi_set(0, 0x28, 0x0000);
    // Setup GPIO1c for input (all bits)
    pixi_spi_set(0, 0x29, 0x5555);
  }

  if (test == 6) {
    reg_a = 0x22;
    reg_b = 0x21;
    // Setup GPIO1a for output (all bits)
    pixi_spi_set(0, 0x27, 0x0000);
    // Setup GPIO1b for input (all bits)
    pixi_spi_set(0, 0x28, 0x0000);
    // Setup GPIO1c for input (all bits)
    pixi_spi_set(0, 0x29, 0x5555);
  }

  if (test == 7) {
    reg_a = 0x25; //GPIO3a
    reg_b = 0x26; //GPIO3b
    // Setup GPIO2a output mode to register & set to off
    pixi_spi_set(0, 0x2A, 0x5555);
    pixi_spi_set(0, 0x23, 0x0000); // Note GPIO2b output is inverted
    // Setup GPIO2b output mode to register & set to off
    pixi_spi_set(0, 0x2B, 0x5555);
    pixi_spi_set(0, 0x24, 0xFFFF); // Note GPIO2b output is non-inverted
    // Setup GPIO3a for output (all bits)
    pixi_spi_set(0, 0x2C, 0x0001);
    // Setup GPIO3b for input (all bits)
    pixi_spi_set(0, 0x2D, 0x0000);
  }

  if (test == 8) {
    reg_a = 0x26; //GPIO3b
    reg_b = 0x25; //GPIO3a
    // Setup GPIO2a output mode to register & set to off
    pixi_spi_set(0, 0x2A, 0x5555);
    pixi_spi_set(0, 0x23, 0x0000); // Note GPIO2b output is inverted
    // Setup GPIO2b output mode to register & set to off
    pixi_spi_set(0, 0x2B, 0x5555);
    pixi_spi_set(0, 0x24, 0xFFFF); // Note GPIO2b output is non-inverted
    // Setup GPIO3a for input (all bits)
    pixi_spi_set(0, 0x2C, 0x0000);
    // Setup GPIO3b for output (all bits)
    pixi_spi_set(0, 0x2D, 0x0001);
  }

  if (test == 9) {
    reg_a = 0x23; //GPIO2a
    reg_b = 0x26; //GPIO3b
    invert = 0x00FF;
    // Setup GPIO2a output mode to register & set to off
    pixi_spi_set(0, 0x2A, 0x5555);
    pixi_spi_set(0, 0x23, 0x0000); // Note GPIO2b output is inverted
    // Setup GPIO2b output mode to register & set to off
    pixi_spi_set(0, 0x2B, 0x5555);
    pixi_spi_set(0, 0x24, 0xFFFF); // Note GPIO2b output is non-inverted
    // Setup GPIO3a for output (all bits)
    pixi_spi_set(0, 0x2C, 0x0000);
    // Setup GPIO3b for input (all bits)
    pixi_spi_set(0, 0x2D, 0x0000);
  }

  if (test == 10) {
    reg_a = 0x24; //GPIO2b
    reg_b = 0x26; //GPIO3b
    invert = 0x0000;
    // Setup GPIO2a output mode to register & set to off
    pixi_spi_set(0, 0x2A, 0x5555);
    pixi_spi_set(0, 0x23, 0x0000); // Note GPIO2b output is inverted
    // Setup GPIO2b output mode to register & set to off
    pixi_spi_set(0, 0x2B, 0x5555);
    pixi_spi_set(0, 0x24, 0xFFFF); // Note GPIO2b output is non-inverted
    // Setup GPIO3a for output (all bits)
    pixi_spi_set(0, 0x2C, 0x0000);
    // Setup GPIO3b for input (all bits)
    pixi_spi_set(0, 0x2D, 0x0000);
  }

  if (test == 11) {
    reg_a = 0x23; //GPIO2a
    reg_b = 0x25; //GPIO3a
    invert = 0x00FF;
    // Setup GPIO2a output mode to register & set to off
    pixi_spi_set(0, 0x2A, 0x5555);
    pixi_spi_set(0, 0x23, 0x0000); // Note GPIO2b output is inverted
    // Setup GPIO2b output mode to register & set to off
    pixi_spi_set(0, 0x2B, 0x5555);
    pixi_spi_set(0, 0x24, 0xFFFF); // Note GPIO2b output is non-inverted
    // Setup GPIO3a for output (all bits)
    pixi_spi_set(0, 0x2C, 0x0000);
    // Setup GPIO3b for input (all bits)
    pixi_spi_set(0, 0x2D, 0x0000);
  }

  if (test == 12) {
    reg_a = 0x24; //GPIO2b
    reg_b = 0x25; //GPIO3a
    invert = 0x0000;
    // Setup GPIO2a output mode to register & set to off
    pixi_spi_set(0, 0x2A, 0x5555);
    pixi_spi_set(0, 0x23, 0x0000); // Note GPIO2b output is inverted
    // Setup GPIO2b output mode to register & set to off
    pixi_spi_set(0, 0x2B, 0x5555);
    pixi_spi_set(0, 0x24, 0xFFFF); // Note GPIO2b output is non-inverted
    // Setup GPIO3a for output (all bits)
    pixi_spi_set(0, 0x2C, 0x0000);
    // Setup GPIO3b for input (all bits)
    pixi_spi_set(0, 0x2D, 0x0000);
  }

  // Write
  spi_dout = test_data;
  pixi_spi_set(0, reg_a, spi_dout);
  
  // Read
  spi_din = pixi_spi_get(0, reg_b, 0x00) ^ invert;
  gpio_errors = (spi_din != spi_dout);
  
  printf ("Test: %d, Sent: 0x%02x, Returned: 0x%02x, Errors: %d\n", test, spi_dout, spi_din, gpio_errors);
  return (gpio_errors);
}


/*
 * doPixiGPIOCheck
 * gpio test function
 *********************************************************************************
 */
void doPixiGPIOCheck (void)
{
  int i;
  int gpio_errors = 0;

  if (wiringPiSPISetup (0, 8000000) < 0) { // setup for 8MHz
    fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
    exit(1);
  }
 
  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (1, i);
  
  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (2, i);

  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (3, i);

  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (4, i);

  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (5, i);

  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (6, i);

  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (7, i);

  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (8, i);

  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (9, i);

  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (10, i);

  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (11, i);

  for (i = 0; i <= 255; i++)
  gpio_errors = gpio_errors + pixi_gpiocheck (12, i);

  printf ("Total errors: %d\n", gpio_errors);
}


/*
 * doSPIset:
 *	gpio SPI register write ...
 *********************************************************************************
 */

void doSPIset (int argc, char *argv [])
{
  int channel;
  int address;
  int data;
  uint8_t outbuffer [4] ;
  
  
  if (argc != 5)
  {
    fprintf (stderr, "Usage: %s spi_set channel address data\n", argv [0]) ;
    exit (1) ;
  }

  channel = atoi (argv [2]) ;
  address = atoi (argv [3]) ;
  data = atoi (argv [4]) ;

  if (wiringPiSPISetup (channel, 8000000) < 0) { // setup for 8MHz
    fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
    exit(1);
  }
 
  // load output buffer and send it out
  outbuffer [0] =  address & 0x00ff;
  outbuffer [1] =            0x0040; // Enable write
  outbuffer [2] = (data    & 0xff00) >> 8;
  outbuffer [3] =  data    & 0x00ff;
 
  wiringPiSPIDataRW (channel, outbuffer, 4) ;
  printf ("Returned: 0x%02x, 0x%02x, 0x%04x\n", outbuffer[0], outbuffer[1], outbuffer[3] | outbuffer[2] << 8);
 
  printf ("Done\n") ;
}


/*
 * doSPIget:
 *	gpio SPI register write ...
 *********************************************************************************
 */

void doSPIget (int argc, char *argv [])
{
  int channel;
  int address;
  int data;
  uint8_t outbuffer [4] ;
  
  if (argc != 5)
  {
    fprintf (stderr, "Usage: %s spi_get channel address null_data\n", argv [0]) ;
    exit (1) ;
  }

  channel = atoi (argv [2]) ;
  address = atoi (argv [3]) ;
  data = atoi (argv [4]) ;

  if (wiringPiSPISetup (channel, 8000000) < 0) { // setup for 8MHz
    fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
    exit(1);
  }
 
  // load output buffer and send it out
  outbuffer [0] =  address & 0x00ff;
  outbuffer [1] =            0x0080; // Enable read
  outbuffer [2] = (data    & 0xff00) >> 8;
  outbuffer [3] =  data    & 0x00ff;
 
  wiringPiSPIDataRW (channel, outbuffer, 4) ;
  printf ("Returned: 0x%02x, 0x%02x, 0x%04x\n", outbuffer[0], outbuffer[1], outbuffer[3] | outbuffer[2] << 8);
 
  printf ("Done\n") ;
}

/*
 * spi_single_read:
 * gpio SPI single register read ...
 *********************************************************************************
 */

int spi_single_read (int channel, int address)
{
  int data = 0;
  uint8_t outbuffer [4] ;
  
  if (wiringPiSPISetup (channel, 8000000) < 0) { // setup for 8MHz
    fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
    exit(1);
  }
 
  // load output buffer and send it out
  outbuffer [0] =  address & 0x00ff;
  outbuffer [1] =            0x0080; // Enable read
  outbuffer [2] = (data    & 0xff00) >> 8;
  outbuffer [3] =  data    & 0x00ff;
 
  wiringPiSPIDataRW (channel, outbuffer, 4) ;
  printf ("Returned: 0x%02x, 0x%02x, 0x%04x\n", outbuffer[0], outbuffer[1], outbuffer[3] | outbuffer[2] << 8);

  data = outbuffer[3] + (outbuffer[2] << 8);
  printf("Single Read from ch. %d, address %d: %d\n", channel, address, data);
  return(data);
}


/*
 * pixi_write:
 * Basic function to write to the PiXi-200 over SPI ...
 * Supports byte, 16-bit or 32-bit writes
 * Also supports single write or n* writes
 *********************************************************************************
 */
void pixi_spi_write(int channel, int address, int format, int num_writes, unsigned long *buffer)
{
   int i;
   int num_bytes;
   uint8_t outbuffer [258] ;
   
   if (wiringPiSPISetup (channel, 8000000) < 0) { // setup for 8MHz
      fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
      exit(1);
   }

     outbuffer [0] =  address & 0x00ff; // Address over SPI
     if (format == 0) {
        outbuffer [1] =            0x0040; // Enable 8-bit write
        num_bytes = num_writes;
     }
     else if (format == 1) {
        outbuffer [1] =            0x0050; // Enable 16-bit write
        num_bytes = num_writes*2;
     }
     else {
        outbuffer [1] =            0x0060; // Enable 32-bit write
        num_bytes = num_writes*4;
     }
     
     if (format == 0) { // Assemble output buffer with 8-bit data
        for (i = 0; i < num_writes; i++) {
           outbuffer [i*2+2] =  (buffer[i] & 0x000000ff);
        }
     }
     else if (format == 1) { // Assemble output buffer with 16-bit data
        for (i = 0; i < num_writes; i++) {
           outbuffer [i*2+2] = ((buffer[i] & 0x0000ff00) >> 8);
           outbuffer [i*2+3] =  (buffer[i] & 0x000000ff);
        }
     }
     else { // Assemble output buffer with 32-bit data
        for (i = 0; i < num_writes; i++) {
           outbuffer [i*2+2] = ((buffer[i] & 0xff000000) >> 24);
           outbuffer [i*2+3] = ((buffer[i] & 0x00ff0000) >> 16);
           outbuffer [i*2+4] = ((buffer[i] & 0x0000ff00) >> 8);
           outbuffer [i*2+5] =  (buffer[i] & 0x000000ff);
        }
     }
 
     printf ("Sending to ch%d: 0x%02x, 0x%02x, 0x%04x\n", channel, outbuffer[0], outbuffer[1], outbuffer[3] | outbuffer[2] << 8);
     wiringPiSPIDataRW (channel, outbuffer, 2 + num_bytes) ;
     printf ("Returned: 0x%02x, 0x%02x, 0x%04x\n", outbuffer[0], outbuffer[1], outbuffer[3] | outbuffer[2] << 8);
}


/*
 * pixi_read:
 * Basic function to data from the PiXi-200 over SPI ...
 * Supports byte, 16-bit or 32-bit writes
 * Also supports single read or n* reads
 *********************************************************************************
 */
void pixi_spi_read(int channel, int address, int format, int num_reads, unsigned long *buffer)
{
   int i;
   int num_bytes;
   uint8_t outbuffer [258] ;
   
   if (wiringPiSPISetup (channel, 8000000) < 0) { // setup for 8MHz
      fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
      exit(1);
   }

     outbuffer [0] =  address & 0x00ff; // Address over SPI
     if (format == 0) {
        outbuffer [1] =            0x0080; // Enable 8-bit write
        num_bytes = num_reads;
     }
     else if (format == 1) {
        outbuffer [1] =            0x0090; // Enable 16-bit write
        num_bytes = num_reads*2;
     }
     else {
        outbuffer [1] =            0x00A0; // Enable 32-bit write
        num_bytes = num_reads*4;
     }
     
     if (format == 0) { // Assemble output buffer with 8-bit data
        for (i = 0; i < num_reads; i++) {
           outbuffer [i*2+2] =  (buffer[i] & 0x000000ff);
        }
     }
     else if (format == 1) { // Assemble output buffer with 16-bit data
        for (i = 0; i < num_reads; i++) {
           outbuffer [i*2+2] = ((buffer[i] & 0x0000ff00) >> 8);
           outbuffer [i*2+3] =  (buffer[i] & 0x000000ff);
        }
     }
     else { // Assemble output buffer with 32-bit data
        for (i = 0; i < num_reads; i++) {
           outbuffer [i*2+2] = ((buffer[i] & 0xff000000) >> 24);
           outbuffer [i*2+3] = ((buffer[i] & 0x00ff0000) >> 16);
           outbuffer [i*2+4] = ((buffer[i] & 0x0000ff00) >> 8);
           outbuffer [i*2+5] =  (buffer[i] & 0x000000ff);
        }
     }
 
     printf ("Sending to ch%d: 0x%02x, 0x%02x, 0x%04x\n", channel, outbuffer[0], outbuffer[1], outbuffer[3] | outbuffer[2] << 8);
     wiringPiSPIDataRW (channel, outbuffer, 2 + num_bytes) ;
     printf ("Returned: 0x%02x, 0x%02x, 0x%04x\n", outbuffer[0], outbuffer[1], outbuffer[3] | outbuffer[2] << 8);
}


/*
 * gpio1_mode:
 *	Basic function to select GPIO3 mode ...
 *********************************************************************************
 */
void gpio1_mode(int mode)
{
   unsigned long buffer[256];

   if (mode == 0) {                  // All bits are configured for input
      buffer[0] = (0x00000000);
      pixi_spi_write(0, 0x27, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x28, 1, 1, buffer); // Configure middle byte
      pixi_spi_write(0, 0x29, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 1) {             // All bits are configured as output, tied to gpio1_out register
      buffer[0] = (0x00000001);
      pixi_spi_write(0, 0x27, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x28, 1, 1, buffer); // Configure middle byte
      pixi_spi_write(0, 0x29, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 2) {             // TBD (spare)
      buffer[0] = (0x00000002);
      pixi_spi_write(0, 0x27, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x28, 1, 1, buffer); // Configure middle byte
      pixi_spi_write(0, 0x29, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 3) {             // TBD (spare)
      buffer[0] = (0x00000003);
      pixi_spi_write(0, 0x27, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x28, 1, 1, buffer); // Configure middle byte
      pixi_spi_write(0, 0x29, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 8) {             // Factory Test Mode1
      buffer[0] = (0x00000003);
      pixi_spi_write(0, 0x27, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x28, 1, 1, buffer); // Configure middle byte
      pixi_spi_write(0, 0x29, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 9) {             // Factory Test Mode2
      buffer[0] = (0x00000003);
      pixi_spi_write(0, 0x27, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x28, 1, 1, buffer); // Configure middle byte
      pixi_spi_write(0, 0x29, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 10) {            // Factory Test Mode2
      buffer[0] = (0x00000003);
      pixi_spi_write(0, 0x27, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x28, 1, 1, buffer); // Configure middle byte
      pixi_spi_write(0, 0x29, 1, 1, buffer); // Configure upper byte
   }
}
 

/*
 * gpio2_mode:
 *	Basic function to select GPIO1 mode ...
 *********************************************************************************
 */
void gpio2_mode(int mode)
{
   unsigned long buffer[256];

   if (mode == 0) {                  // All bits are configured for input
      buffer[0] = (0x00000000);
      pixi_spi_write(0, 0x2A, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x2B, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 1) {             // All bits are configured as output, tied to gpio3_out register
      buffer[0] = (0x00000001);
      pixi_spi_write(0, 0x2A, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x2B, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 2) {             // All bits are configured as output, specific for directly driving LCD or VFD. Tied to VFDLCD register
      buffer[0] = (0x00000002);
      pixi_spi_write(0, 0x2A, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x2B, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 3) {             // TBD (spare)
      buffer[0] = (0x00000003);
      pixi_spi_write(0, 0x2A, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x2B, 1, 1, buffer); // Configure upper byte
   }
}
 

/*
 * gpio3_mode:
 *	Basic function to select GPIO3 mode ...
 *********************************************************************************
 */
void gpio3_mode(int mode)
{
   unsigned long buffer[256];

   if (mode == 0) {                  // All bits are configured for input
      buffer[0] = (0x00000000);
      pixi_spi_write(0, 0x2C, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x2D, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 1) {             // All bits are configured as output, tied to gpio3_out register
      buffer[0] = (0x00000001);
      pixi_spi_write(0, 0x2C, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x2D, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 2) {             // All bits are configured as output, specific for directly driving LCD or VFD. Tied to VFDLCD register
      buffer[0] = (0x00000002);
      pixi_spi_write(0, 0x2C, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x2D, 1, 1, buffer); // Configure upper byte
   }
   else if (mode == 3) {             // TBD (spare)
      buffer[0] = (0x00000003);
      pixi_spi_write(0, 0x2C, 1, 1, buffer); // Configure lower byte
      pixi_spi_write(0, 0x2D, 1, 1, buffer); // Configure upper byte
   }
}
 

/*
 * printlcd:
 *	Basic function to send a text string to the LCD / VFD ...
 *********************************************************************************
 */
void printlcd(char * a)
{
   int i;
   unsigned long buffer[256];

   // Configure GPIO3 I/O mode as LCD/VFD
   gpio3_mode(2);
   
   // Send string to display
   for (i = 0; i < strlen(a); i++) {
      buffer[0] = 0x00000200 + ((unsigned short)a[i] & 0x000000ff); // Set RS to '1' for display data & combine upper / lower bytes
      pixi_spi_write(0, 0x38, 1, 1, buffer);
   }
//   pixi_spi_write(0, 0x38, 1, strlen(a), buffer); // For when the FPGA supports multiple write over SPI...
}


 /*
 * configurelcd:
 *	Basic function to send a config string to the LCD / VFD ...
 *********************************************************************************
 */
int configurelcd(char * cfg_name, int *cfg_values)
{
   // init        : cfg_values[0] = TBD...
   // brightness  : cfg_values[0] = brightness, 0 => 25%, 1 => 50%, 2 => 75%, 3 => 100%
   // goto_xy     : cfg_values[0] = x, cfg_values[1] = y

   unsigned long buffer[256];

   // Configure GPIO3 I/O mode as LCD/VFD
   gpio3_mode(2);
   
   if      (strcasecmp (cfg_name, "init")       == 0) { buffer[0] = 0x0030; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x30 = Function Set
                                                        buffer[0] = 0x0203; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x83 = Brightness Control (low)
                                                        buffer[0] = 0x0001; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x01 = Display Clear
                                                        buffer[0] = 0x0002; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x02 = Cursor Home
                                                        buffer[0] = 0x0006; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x06 = Entry Mode Set
                                                        buffer[0] = 0x000C; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x0C = Display On
                                                        printlcd("Welcome to the PiXi-200!");
                                                        return(0);}
   else if (strcasecmp (cfg_name, "init1")      == 0) { buffer[0] = 0x0030; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x30 = Function Set
                                                        buffer[0] = 0x0200; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x83 = Brightness Control (full)
                                                        buffer[0] = 0x0001; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x01 = Display Clear
                                                        buffer[0] = 0x0002; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x02 = Cursor Home
                                                        buffer[0] = 0x0006; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x06 = Entry Mode Set
                                                        buffer[0] = 0x000F; pixi_spi_write(0, 0x38, 1, 1, buffer); // 0x0C = Display On, Cursor On, Curson Blink Enabled
                                                        printlcd("Welcome to the PiXi-200!");
                                                        return(0);}
   else if (strcasecmp (cfg_name, "brightness") == 0) { buffer[0] = 0x0030; pixi_spi_write(0, 0x38, 1, 1, buffer); buffer[0] = 0x0200 + (cfg_values[0] & 0x0003); pixi_spi_write(0, 0x38, 1, 1, buffer); return(0);}
   else if (strcasecmp (cfg_name, "clear")      == 0) { return(0);}
   else if (strcasecmp (cfg_name, "goto_xy")    == 0) { buffer[0] = 0x0080 + ((cfg_values[1] & 0x3f) << 6) + (cfg_values[0] & 0x3f); pixi_spi_write(0, 0x38, 1, 1, buffer); return(0);}
   else return(1);

}


/*
 * lcdwritexy:
 *	gpio LCV / VFD display write ...
 *********************************************************************************
 */

void lcdwritexy (char * lcdstring, int x, int y)
{
   int buffer[256];
    
   // Send x,y address
   buffer[0] = x;
   buffer[1] = y;
   configurelcd("goto_xy", buffer);
  
   printlcd(lcdstring);
}


/*
 * doLCDWriteXY:
 *	gpio LCV / VFD display write ...
 *********************************************************************************
 */

void doLCDWriteXY (int argc, char *argv [])
{
   int x;
   int y;
   char lcdstring[128];
    
   if (argc < 5)
   {
      fprintf (stderr, "Usage: %s pixi_lcdwr <x> <y> <string1>\n", argv [0]) ;
      exit (1) ;
   }

   x = atoi (argv [2]) ;
   y = atoi (argv [3]) ;
   sprintf(lcdstring, argv[4]);
   
   lcdwritexy(lcdstring, x, y);

   printf ("Done\n") ;
}


/*
 * doPiXi_PWMSeq:
 *	Automated test & verification process ...
 *********************************************************************************
 */
int pixi_pwmgo(int seq_no)
{

   int i;
   unsigned long buffer[] = {// FL      FR      RL      RR
                             0x0066, 0x0066, 0x0066, 0x0066, // Forward, 10%
                             0x0132, 0x0132, 0x0132, 0x0132, // Forward, 30%
                             0x01FE, 0x01FE, 0x01FE, 0x01FE, // Forward, 50%
                             0x0132, 0x0132, 0x0132, 0x0132, // Forward, 30%
                             0x0066, 0x0066, 0x0066, 0x0066, // Forward, 10%
                             0x8066, 0x0066, 0x8066, 0x0066, // Left turn, 10%
                             0x8066, 0x8066, 0x8066, 0x8066, // Reverse, 10%
                             0x8066, 0x0066, 0x8066, 0x0066, // Left turn, 10%
                             0x0066, 0x0066, 0x0066, 0x0066, // Forward, 10%
                             0x0066, 0x0066, 0x0066, 0x0066, // Forward, 10%
                             0x8066, 0x0066, 0x0066, 0x0066, // Left turn, 10%
                             0x0066, 0x0066, 0x0066, 0x0066, // Forward, 10%
                             0x0066, 0x8066, 0x0066, 0x8066, // Right turn, 10%
                             0x0066, 0x8066, 0x0066, 0x8066, // Right turn, 10%
                             0x0066, 0x8066, 0x0066, 0x8066, // Right turn, 10%
                             0x8066, 0x8066, 0x8066, 0x8066};// Reverse, 10%

   if (wiringPiSPISetup (0, 8000000) < 0) { // setup for 8MHz
      fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
      exit(1);
   }

   buffer[0] = 0x0000;
   pixi_spi_write(0, 0x4f, 1, 1, buffer); // Disable PWM sequencer
   
   if (seq_no > 0) {
      for (i = 0; i <= 51; i=i+4) {
         pixi_spi_write(0, 0x40, 1, 1, &buffer[i]); // Configure lower byte
         pixi_spi_write(0, 0x41, 1, 1, &buffer[i+1]); // Configure lower byte
         pixi_spi_write(0, 0x42, 1, 1, &buffer[i+2]); // Configure lower byte
         pixi_spi_write(0, 0x43, 1, 1, &buffer[i+3]); // Configure lower byte
      }
   }
   
   buffer[0] = 0x0001;
   pixi_spi_write(0, 0x4f, 1, 1, buffer); // Enable PWM sequencer

   return(0);
}
 
 
/*
 * doPiXi_PWMSeq:
 *	Automated test & verification process ...
 *********************************************************************************
 */
int pixi_pwmprog (int argc, char *argv [])
{
   int speed;
   unsigned long pwm;
   unsigned long cmd_fl;
   unsigned long cmd_fr;
   unsigned long cmd_rl;
   unsigned long cmd_rr;
   unsigned long buffer[4];
    
   if (argc < 3)
   {
      fprintf (stderr, "Usage: %s pixi_pwmseq <cmd (f, r, l, r)> <speed>\n", argv [0]) ;
      exit (1) ;
   }

   if (wiringPiSPISetup (0, 8000000) < 0) { // setup for 8MHz
      fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
      exit(1);
   }

   speed = atoi (argv [3]) ;
   if (speed > 100)
      speed = 100;
   else if (speed < 0)
      speed = 0;
      
   pwm = (speed * 1023 / 100) & 0x000003ff;

   /**/ if (strcasecmp (argv [2], "f" )   == 0) { cmd_fl = 0x0000 + pwm; cmd_fr = 0x0000 + pwm; cmd_rl = 0x8000 + pwm; cmd_rr = 0x8000 + pwm; }
   else if (strcasecmp (argv [2], "b" )   == 0) { cmd_fl = 0x8000 + pwm; cmd_fr = 0x8000 + pwm; cmd_rl = 0x0000 + pwm; cmd_rr = 0x0000 + pwm; }
   else if (strcasecmp (argv [2], "l")    == 0) { cmd_fl = 0x8000 + pwm; cmd_fr = 0x0000 + pwm; cmd_rl = 0x0000 + pwm; cmd_rr = 0x8000 + pwm; }
   else if (strcasecmp (argv [2], "r")    == 0) { cmd_fl = 0x0000 + pwm; cmd_fr = 0x8000 + pwm; cmd_rl = 0x8000 + pwm; cmd_rr = 0x0000 + pwm; }
   else                                         { cmd_fl = 0x0000;       cmd_fr = 0x0000;       cmd_rl = 0x8000;       cmd_rr = 0x8000; }
   
   buffer[0] = cmd_fr; // FR
   pixi_spi_write(0, 0x45, 1, 1, buffer);
   
   buffer[0] = cmd_rl; // RL
   pixi_spi_write(0, 0x46, 1, 1, buffer);
   
   buffer[0] = cmd_rr; // RR
   pixi_spi_write(0, 0x44, 1, 1, buffer);

   buffer[0] = cmd_fl; // FL
   pixi_spi_write(0, 0x47, 1, 1, buffer); // Must write to 0x47 last!

   
   return(0);
}


/*
 * doPiXi_Test:
 *	Automated test & verification process ...
 *********************************************************************************
 */
int pixi_test(int test_no)
{

   // 1: test GPIO1(a) odd = out, even = in, "000000000000", "111111111111", walking '1'...
   // 2: test GPIO1(a) odd = in, even = out, "000000000000", "111111111111", walking '1'...
   
   return(0);
}
 
 
 /*
 * doPixiProg:
 *	gpio Program PiXi FPGA
 *********************************************************************************
 */
static void doPixiProg (void)
{
  unsigned short repeat;
  unsigned char byte, shift_byte;
  FILE *fp;
  long filesize;
  long i;
  int j;
  char * buffer;
  long bytes_read;
  long bytes_readDIV10;
  int percent_complete;
  int byte_counter;
  int timeout;
  int demo_build;
  

  // Setup pin I/O direction
  printf("Setting pin I/O Direction...\n");
  pinMode (PROG_PIN, OUTPUT);
  pinMode (INIT_PIN, INPUT);
  pinMode (CCLK_PIN, OUTPUT);
  pinMode (DATA_PIN, OUTPUT);

 
  demo_build = spi_single_read(0, 0xf8); // Check if a demo build is currently active in the FPGA
  
  // ***** Set PROG low *****
  printf("Setting PROG low...\n");
  digitalWrite (PROG_PIN, LOW);


  // ***** Hold PROG low line for a short while *****
  usleep (1000);


  // ***** Return PROG high *****
  printf("Setting PROG high...\n");
  digitalWrite (PROG_PIN, HIGH);


  // ***** Wait for init to go high... *****
  printf("Wait for INIT...\n");
  timeout = 100;
  while ((timeout > 1) && (!(digitalRead(INIT_PIN) == HIGH)))
  {
    usleep (1000);
    timeout--;
  }
   
  if (digitalRead(INIT_PIN) == HIGH) 
    printf("Ready to program PiXi...\n");
  else
  {
    printf("INIT did not go high!\n");
    exit(1);
  }
  
  
  // ***** Read file in preparation for programming *****
  // Check for main file first then look for demo files
  // If main file doesn't exist check for a demo configuration in the FPGA and load the next available demo build in the sequence...
  // If the FPGA has already been configured and the default FPGAFILE doesn't exist then it reads register 0xff to identify the next FPGA in the demo sequence...
  
  printf("Open file for reading...\n");
  if (((fp = fopen(FPGADEMO_001, "rb"))      != NULL) && (demo_build == 0)) {
    printf("Loading %s...\n", FPGADEMO_001); }
  else if (((fp = fopen(FPGADEMO_002, "rb")) != NULL) && (demo_build == 1)) {
    printf("Loading %s...\n", FPGADEMO_002); }
  else if (((fp = fopen(FPGADEMO_003, "rb")) != NULL) && (demo_build == 2)) {
    printf("Loading %s...\n", FPGADEMO_003); }
  else if (((fp = fopen(FPGADEMO_004, "rb")) != NULL) && (demo_build == 3)) {
    printf("Loading %s...\n", FPGADEMO_004); }
  else if (((fp = fopen(FPGADEMO_005, "rb")) != NULL) && (demo_build == 4)) {
    printf("Loading %s...\n", FPGADEMO_005); }
  else if (((fp = fopen(FPGADEMO_006, "rb")) != NULL) && (demo_build == 5)) {
    printf("Loading %s...\n", FPGADEMO_006); }
  else if ((fp = fopen(FPGAFILE, "rb"))      != NULL) { // Default to loading FPGAFILE if there are no demo builds...
    printf("Loading %s...\n", FPGAFILE); }
  else if (((fp = fopen(FPGADEMO_001, "rb")) != NULL)) { // Loop demo back to demo_001 if default FPGAFILE is not present
    printf("Loading %s...\n", FPGADEMO_001); }
  else {
    printf("FPGA configuration file not found! Missing %s\n", FPGAFILE);
    exit(1);
  }

  fseek(fp, 0, SEEK_END);
  filesize = ftell(fp);
  printf("File size: %ld\n", filesize);
  rewind(fp);

  printf("Allocate memory...\n");
  buffer = (char*) malloc (sizeof(char)*filesize);
  if (buffer == NULL)
  {
    printf("Memmory allocation error!\n");
    exit(2);
  }

  byte_counter = 0;
  percent_complete = 0;
  byte = (unsigned char) 0;
  
  usleep(1000000);

  bytes_read = fread(buffer, 1, filesize, fp);
  bytes_readDIV10 = bytes_read / 10;
   
  printf("Bytes read from file: %ld\n", bytes_read);
   

  // ***** Download to FPGA *****

  if (bytes_read == filesize) 
  {
    printf("%3d%% complete...\n", percent_complete);      
    for (i = 0; i < bytes_read; i++)
    {
      byte = *(buffer+i);
      shift_byte = byte;
      repeat = 1;

      while (repeat--)
      {
        for (j = 0; j < 8; j++)       //data goes out serially
        {
          // Set CCLK = '0'
          digitalWrite (CCLK_PIN, LOW);

          if (!(shift_byte & 0x80))
            digitalWrite (DATA_PIN, LOW);
          else
            digitalWrite (DATA_PIN, HIGH);
           
          // Set CCLK = '1', PROG = '1', DIN = data
          digitalWrite (CCLK_PIN, HIGH);
               
          shift_byte = shift_byte << 1;
        }
        byte_counter++;
      }

      if (byte_counter >= bytes_readDIV10)
      {
        percent_complete += 10;
        printf("%3d%% complete...\n", percent_complete);
        //printf(".");
        byte_counter -= bytes_readDIV10;   
      }
    }

    printf("\n");
    // Need to contine clocking CCLK for a little while after download...
    for (j = 0; j < 8; j++)
    {
      // Set CCLK low
      digitalWrite (CCLK_PIN, LOW);

      // Set CCLK high
      digitalWrite (CCLK_PIN, HIGH);
    }

    usleep(100000);
    
    if (wiringPiSPISetup (0, 8000000) < 0) { // setup for 8MHz
      fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
    }

    printf ("FPGA Version: %04x%04x%04x\n", pixi_spi_get(0, 0x02, 0x00), pixi_spi_get(0, 0x01, 0x00), pixi_spi_get(0, 0x00, 0x00));
    printf ("Freeing up memory...\n");
    free (buffer); // De-allocate memory...
    printf ("Done!\n");
  }
  else
  {
    printf("Error reading file!\n");
    exit(1);
  }
}


 /*
 * main:
 *	Start here
 *********************************************************************************
 */

int main (int argc, char *argv [])
{
  int i ;
  int buffer[256];

  if (argc == 1)
  {
    fprintf (stderr, "%s\n", usage) ;
    return 1 ;
  }

  if (strcasecmp (argv [1], "-h") == 0)
  {
    printf ("%s: %s\n", argv [0], usage) ;
    return 0 ;
  }

  if (strcasecmp (argv [1], "-v") == 0)
  {
    printf ("gpio version: %s\n", VERSION) ;
    printf ("Copyright (c) 2012 Gordon Henderson\n") ;
    printf ("This is free software with ABSOLUTELY NO WARRANTY.\n") ;
    printf ("For details type: %s -warranty\n", argv [0]) ;
    printf ("\n") ;
    printf ("This Raspberry Pi is a revision %d board.\n", piBoardRev ()) ;
    return 0 ;
  }

  if (strcasecmp (argv [1], "-warranty") == 0)
  {
    printf ("gpio version: %s\n", VERSION) ;
    printf ("Copyright (c) 2012 Gordon Henderson\n") ;
    printf ("\n") ;
    printf ("    This program is free software; you can redistribute it and/or modify\n") ;
    printf ("    it under the terms of the GNU Leser General Public License as published\n") ;
    printf ("    by the Free Software Foundation, either version 3 of the License, or\n") ;
    printf ("    (at your option) any later version.\n") ;
    printf ("\n") ;
    printf ("    This program is distributed in the hope that it will be useful,\n") ;
    printf ("    but WITHOUT ANY WARRANTY; without even the implied warranty of\n") ;
    printf ("    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n") ;
    printf ("    GNU Lesser General Public License for more details.\n") ;
    printf ("\n") ;
    printf ("    You should have received a copy of the GNU Lesser General Public License\n") ;
    printf ("    along with this program. If not, see <http://www.gnu.org/licenses/>.\n") ;
    printf ("\n") ;
    return 0 ;
  }

  if (geteuid () != 0)
  {
    fprintf (stderr, "%s: Must be root to run. Program should be suid root. This is an error.\n", argv [0]) ;
    return 1 ;
  }

// Initial test for /sys/class/gpio operations:

  /**/ if (strcasecmp (argv [1], "exports"    ) == 0)	{ doExports     (argc, argv) ;	return 0 ; }
  else if (strcasecmp (argv [1], "export"     ) == 0)	{ doExport      (argc, argv) ;	return 0 ; }
  else if (strcasecmp (argv [1], "edge"       ) == 0)	{ doEdge        (argc, argv) ;	return 0 ; }
  else if (strcasecmp (argv [1], "unexportall") == 0)	{ doUnexportall (argc, argv) ;	return 0 ; }
  else if (strcasecmp (argv [1], "unexport"   ) == 0)	{ doUnexport    (argc, argv) ;	return 0 ; }

// Check for load command:

  if (strcasecmp (argv [1], "load" ) == 0)	{ doLoad     (argc, argv) ; return 0 ; }

// Gertboard commands

  if (strcasecmp (argv [1], "gbr" ) == 0)	{ doGbr (argc, argv) ; return 0 ; }
  if (strcasecmp (argv [1], "gbw" ) == 0)	{ doGbw (argc, argv) ; return 0 ; }

// Check for -g argument

  if (strcasecmp (argv [1], "-g") == 0)
  {
    if (wiringPiSetupGpio () == -1)
    {
      fprintf (stderr, "%s: Unable to initialise GPIO mode.\n", argv [0]) ;
      exit (1) ;
    }

    for (i = 2 ; i < argc ; ++i)
      argv [i - 1] = argv [i] ;
    --argc ;
    wpMode = WPI_MODE_GPIO ;
  }

// Check for -p argument for PiFace

  else if (strcasecmp (argv [1], "-p") == 0)
  {
    if (wiringPiSetupPiFaceForGpioProg () == -1)
    {
      fprintf (stderr, "%s: Unable to initialise PiFace.\n", argv [0]) ;
      exit (1) ;
    }

    for (i = 2 ; i < argc ; ++i)
      argv [i - 1] = argv [i] ;
    --argc ;
    wpMode = WPI_MODE_PIFACE ;
  }

// Default to wiringPi mode

  else
  {
    if (wiringPiSetup () == -1)
    {
      fprintf (stderr, "%s: Unable to initialise wiringPi mode\n", argv [0]) ;
      exit (1) ;
    }
    wpMode = WPI_MODE_PINS ;
  }

// Check for PWM or Pad Drive operations

  if (wpMode != WPI_MODE_PIFACE)
  {
    if (strcasecmp (argv [1], "pwm-bal") == 0)	{ doPwmMode  (PWM_MODE_BAL) ;	return 0 ; }
    if (strcasecmp (argv [1], "pwm-ms")  == 0)	{ doPwmMode  (PWM_MODE_MS) ;	return 0 ; }
    if (strcasecmp (argv [1], "pwmr")    == 0)	{ doPwmRange (argc, argv) ;	return 0 ; }
    if (strcasecmp (argv [1], "pwmc")    == 0)	{ doPwmClock (argc, argv) ;	return 0 ; }
    if (strcasecmp (argv [1], "drive")   == 0)	{ doPadDrive (argc, argv) ;	return 0 ; }
  }

// Check for wiring commands

  /**/ if (strcasecmp (argv [1], "readall" )        == 0) doReadall       () ;
  else if (strcasecmp (argv [1], "read" )           == 0) doRead          (argc, argv) ;
  else if (strcasecmp (argv [1], "write")           == 0) doWrite         (argc, argv) ;
  else if (strcasecmp (argv [1], "pwm"  )           == 0) doPwm           (argc, argv) ;
  else if (strcasecmp (argv [1], "mode" )           == 0) doMode          (argc, argv) ;
  else if (strcasecmp (argv [1], "pixi_prog" )      == 0) doPixiProg      () ;
  else if (strcasecmp (argv [1], "pixi_gpiocheck" ) == 0) doPixiGPIOCheck () ;
  else if (strcasecmp (argv [1], "spi_set" )        == 0) doSPIset        (argc, argv) ;
  else if (strcasecmp (argv [1], "spi_get" )        == 0) doSPIget        (argc, argv) ;
  else if (strcasecmp (argv [1], "pixi_lcdinit" )   == 0) configurelcd    ("init", buffer);
  else if (strcasecmp (argv [1], "pixi_lcdinit1" )  == 0) configurelcd    ("init1", buffer);
  else if (strcasecmp (argv [1], "pixi_lcdxyw" )    == 0) doLCDWriteXY    (argc, argv) ;
  else if (strcasecmp (argv [1], "pixi_lcdcfgb0" )  == 0) {buffer[0] = 0; configurelcd ("brightness", buffer);}
  else if (strcasecmp (argv [1], "pixi_lcdcfgb1" )  == 0) {buffer[0] = 1; configurelcd ("brightness", buffer);}
  else if (strcasecmp (argv [1], "pixi_lcdcfgb3" )  == 0) {buffer[0] = 3; configurelcd ("brightness", buffer);}
  else if (strcasecmp (argv [1], "pixi_pwmseq1" )   == 0) pixi_pwmgo      (1);
  else if (strcasecmp (argv [1], "pixi_pwmstart" )  == 0) pixi_pwmgo      (0);
  else if (strcasecmp (argv [1], "pixi_pwmprog" )   == 0) pixi_pwmprog    (argc, argv) ;
  else
  {
    fprintf (stderr, "%s: Unknown command: %s.\n", argv [0], argv [1]) ;
    exit (1) ;
  }
  return 0 ;
}
