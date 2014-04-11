/*
    pixi-tools: a set of software to interface with the Raspberry Pi
    and PiXi-200 hardware
    Copyright (C) 2013 Simon Cantrill

    pixi-tools is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include <libpixi/pixi/simple.h>
#include <libpixi/util/string.h>
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

#include "Command.h"
#include "log.h"

static int pixi_dalek_stop(int duration);
static int pixi_dalek_f(int speed, int duration);
static int pixi_dalek_b(int speed, int duration);
static int pixi_dalek_l(int speed, int duration);
static int pixi_dalek_r(int speed, int duration);
static int pixi_dalek_look(int start_alt, int start_az, int alt, int az, int inc);
static int pixi_dalek_speak(int voice);
static int pixi_dalek_demo(int demo);
static int pixi_dalek_remote(int demo);



// Keyboard scanning stuff...
static void ttyRaw (int fd)
{
	struct termios term;
	int result = tcgetattr(fd, &term);
	if (result < 0)
		perror("tcgetattr");
	cfmakeraw (&term);
	result = tcsetattr(fd, TCSAFLUSH, &term);
	if (result < 0)
		perror("tcgetattr");
}

/// Disable line-buffering
/// This can screw up your terminal, use the 'reset' command to fix it.
static void ttyInputRaw (int fd)
{
	struct termios term;
	int result = tcgetattr(fd, &term);
	if (result < 0)
		perror("tcgetattr");
	term.c_lflag &= ~(ICANON | ECHO);
	result = tcsetattr(fd, TCSAFLUSH, &term);
	if (result < 0)
		perror("tcgetattr");
}

/// Enable line-buffering
static void ttyInputNormal (int fd)
{
	struct termios term;
	int result = tcgetattr(fd, &term);
	if (result < 0)
		perror("tcgetattr");
	term.c_lflag |= (ICANON | ECHO);
	result = tcsetattr(fd, TCSAFLUSH, &term);
	if (result < 0)
		perror("tcgetattr");
}

static const char keyUp[]    = {0x1b, 0x5b, 0x41, 0};
static const char keyDown[]  = {0x1b, 0x5b, 0x42, 0};
static const char keyRight[] = {0x1b, 0x5b, 0x43, 0};
static const char keyLeft[]  = {0x1b, 0x5b, 0x44, 0};



//	Should replace calls to pixi_spi_set/pixi_spi_get with
//	pixiOpen, gpioSetPinMode, gpioWritePin, pwmWritePin, etc.
//	but meanwhile...

static int pixi_spi_set (int channel, int address, int data) {
	LIBPIXI_UNUSED(channel);
	return registerWrite (address, data);
}

static int pixi_spi_get (int channel, int address, int data) {
	LIBPIXI_UNUSED(channel);
	LIBPIXI_UNUSED(data);
	return registerRead (address);
}

/*
 * dalek_stop:
 *********************************************************************************
 */
int pixi_dalek_stop(int duration)
{
   pixi_spi_set(0, 0x25, 0x00);

   usleep(1000000 * duration);
   return(0);
}

/*
 * dalek_forward:
 *********************************************************************************
 */
int pixi_dalek_f(int speed, int duration)
{
   float left_mult = 1.0;
   float right_mult = 1.0;

   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // direction...
   pixi_spi_set(0, 0x25, 0x05);

   usleep(1000000 * duration);
   return(0);
}

/*
 * dalek_backward:
 *********************************************************************************
 */
int pixi_dalek_b(int speed, int duration)
{
   float left_mult = 1.0;
   float right_mult = 1.0;

   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // direction...
   pixi_spi_set(0, 0x25, 0x0A);

   usleep(1000000 * duration);
   return(0);
}

/*
 * dalek_left:
 *********************************************************************************
 */
int pixi_dalek_l(int speed, int duration)
{
   float left_mult = 1.0;
   float right_mult = 1.0;

   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // direction...
   pixi_spi_set(0, 0x25, 0x09);

   usleep(1000000 * duration);
   return(0);
}

/*
 * dalek_right:
 *********************************************************************************
 */
int pixi_dalek_r(int speed, int duration)
{
   float left_mult = 1.0;
   float right_mult = 1.0;

   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // direction...
   pixi_spi_set(0, 0x25, 0x06);

   usleep(1000000 * duration);
   return(0);
}

/*
 * dalek_look:
 *********************************************************************************
 */
int pixi_dalek_look(int start_alt, int start_az, int alt, int az, int inc)
{
   int current_alt;
   int current_az;

   if (start_az == 0)
      start_az = (((pixi_spi_get(0, 0x43, 0) & 1023)-76.5)/51.0)*90.0;
   if (az < start_az) {
      for (current_az = start_az; current_az > az; current_az = current_az - inc) {
         pixi_spi_set(0, 0x43, (int)(((current_az/90.0)*51.0)+76.5));
         usleep (20000); } }
   if (az > start_az) {
      for (current_az = start_az; current_az < az; current_az = current_az + inc) {
         pixi_spi_set(0, 0x43, (int)(((current_az/90.0)*51.0)+76.5));
         usleep (20000); } }

   if (start_alt == 0)
      start_alt = ((102 - (pixi_spi_get(0, 0x42, 0) & 1023))/51.0)*90;
   if (alt < start_alt) {
      for (current_alt = start_alt; current_alt > alt; current_alt = current_alt - inc) {
	     pixi_spi_set(0, 0x42, (102-(int)((current_alt/90.0)*51)));
         usleep (20000); } }
   else {
      for (current_alt = start_alt; current_alt < alt; current_alt = current_alt + inc) {
	     pixi_spi_set(0, 0x42, (102-(int)((current_alt/90.0)*51)));
         usleep (20000); } }

   return(0);
}

/*
 * dalek_mlook
 *********************************************************************************
 */
/*
int pixi_dalek_mlook (int argc, char *argv [])
{

   if (argc < 4)
   {
      fprintf (stderr, "Usage: %s pixi_daleklook <alt> <az>\n", argv [0]) ;
      exit (1) ;
   }

   if (wiringPiSPISetup (0, 8000000) < 0) { // setup for 8MHz
      fprintf (stderr, "SPI Setup failed: %s\n", strerror (errno));
      exit(1);
   }

   pixi_dalek_look(0, 0, atoi (argv [2]), atoi (argv [3]), 1);

   return(0);
}
*/


/*
 * dalek_speak:
 *********************************************************************************
 */
int pixi_dalek_speak(int voice)
{
   pixi_spi_set(0, 0x25, 32);
   usleep (500000);

   pixi_spi_set(0, 0x25, 0);
   usleep (500000);

   return(0);
}

/*

 * Dalek Demo:
 *********************************************************************************
 */
int pixi_dalek_demo(int demo)
{
   pixi_spi_set (0, 0x27, 0); // Set up GPIO1 for input

   while (1) {

   printf("Press the button to start...\n");
   // Wait for button to be pressed
   while ((pixi_spi_get(0, 0x20, 0) & 0x0001) == 1) { // GPIO1(0)
   }

   printf("Starting Demo...\n");

   usleep(5000000);

// Looking straight ahead...
   pixi_dalek_look(0,0,0,0,1);
// forward for 2s
   pixi_dalek_f(512,0);
// look left
   pixi_dalek_look(0,0,0,90,1);
// look right
   pixi_dalek_look(0,0,0,-90,2);
// look left
   pixi_dalek_look(0,0,0,90,2);
// look straight ahead
   pixi_dalek_look(0,0,0,0,1);
// turn 180 degrees
   pixi_dalek_r(1023,2);
// forward for 2s
   pixi_dalek_f(512,0);
// look left
   pixi_dalek_look(0,0,0,90,1);
// look right
   pixi_dalek_look(0,0,0,-90,2);
// look left
   pixi_dalek_look(0,0,0,90,2);
// look straight ahead
   pixi_dalek_look(0,0,0,0,1);
// turn 180 degrees
//   pixi_dalek_l(1023,2);
// stop
   pixi_dalek_stop(1);

// look right
   pixi_dalek_look(0,0,0,-90,1);
// turn right / look straight ahead
   pixi_dalek_r(512,0);
   pixi_dalek_look(0,0,0,0,1);
   pixi_dalek_stop(1);
// forward 0.5s
   pixi_dalek_f(512,1);
   pixi_dalek_stop(1);
// look up
   pixi_dalek_look(0,0,45,0,1);
// look down
   pixi_dalek_look(0,0,0,0,1);
// look 45
   pixi_dalek_look(0,0,22,0,1);

// Exterminate!
   pixi_dalek_speak(0);

} // while...

   return(demo);
}

/*

 * Dalek Remote:
 *********************************************************************************
 */
int pixi_dalek_remote(int demo)
{
	int i;
	char buf[16];
	int count;
	ttyInputRaw (STDIN_FILENO);
	printf("press 'q' to quit\n");
	while ((count = read(STDIN_FILENO, buf, sizeof(buf)-1)) > 0)
	{
		/* This doesn't handle multiple keys being pressed simultaneously */
		buf[count] = 0;
		printf("byte-count=%d, byte-values=", count);
		for (i = 0; i < count; i++)
			printf ("%02x,", buf[i]);
		if (0 == strcmp(buf, keyUp))
			printf("up");
		else if (0 == strcmp(buf, keyDown))
			printf("down");
		else if (0 == strcmp(buf, keyRight))
			printf("right");
		else if (0 == strcmp(buf, keyLeft))
			printf("left");
		else if (count == 1)
		{
			if (buf[0] == 'q')
			{
				printf("quitting\n");
				break;
			}
			else if (buf[0] == 's')
			{
                pixi_dalek_look(0,0,0,0,1);
				printf("Look straight ahead...\n");
			}
			else if (buf[0] == 'a')
			{
                pixi_dalek_look(0,0,0,90,1);
				printf("Look left...\n");
			}
			else if (buf[0] == 'd')
			{
                pixi_dalek_look(0,0,0,-90,1);
				printf("Look right...\n");
			}
			else if (buf[0] == 'w')
			{
                pixi_dalek_look(0,0,45,0,1);
				printf("Look up...\n");
			}
			else if (buf[0] == 'x')
			{
                pixi_dalek_look(0,0,0,0,1);
				printf("Look down...\n");
			}
			else if (buf[0] == 'e')
			{
                pixi_dalek_look(0,0,22,0,1);
				printf("Look 45deg...\n");
			}
			else if (buf[0] == '4')
			{
                pixi_dalek_l(512,0);
				printf("Left...\n");
			}
			else if (buf[0] == '6')
			{
                pixi_dalek_r(512,0);
				printf("Right...\n");
			}
			else if (buf[0] == '8')
			{
                pixi_dalek_f(512,0);
				printf("Forwards...\n");
			}
			else if (buf[0] == '2')
			{
                pixi_dalek_b(512,0);
				printf("Backwards...\n");
			}
			else if (buf[0] == '5')
			{
                pixi_dalek_stop(0);
				printf("Stop...\n");
			}
			else if (buf[0] == ' ')
			{
                pixi_dalek_speak(0);
				printf("Speak...\n");
			}
			if (isprint(buf[0]))
				printf("printable:%c", buf[0]);
		}
		printf("\n");
	}
	ttyInputNormal (STDIN_FILENO);
    return(demo);
}	
	
	
static int dalekDemoFn (uint argc, char*const*const argv)
{
	if (argc != 1)
	{
		PIO_LOG_ERROR ("usage: %s", argv[0]);
		return -EINVAL;
	}
	pixiOpenOrDie();
	pixi_dalek_demo (0);
	return 0;
}
static Command dalekDemoCmd =
{
	.name        = "dalek-demo",
	.description = "Run a sequence of moves to demonstrate the dalek",
	.function    = dalekDemoFn
};

static int dalekRemoteFn (uint argc, char*const*const argv)
{
	if (argc != 1)
	{
		PIO_LOG_ERROR ("usage: %s", argv[0]);
		return -EINVAL;
	}
	pixiOpenOrDie();
	pixi_dalek_remote (0);
	return 0;
}
static Command dalekRemoteCmd =
{
	.name        = "dalek-remote",
	.description = "Allows the Dalek to be controlled from the keyboard...",
	.function    = dalekRemoteFn
};

static int dalekSpeakFn (uint argc, char*const*const argv)
{
	if (argc != 1)
	{
		PIO_LOG_ERROR ("usage: %s", argv[0]);
		return -EINVAL;
	}
	pixiOpenOrDie();
	pixi_dalek_speak (0);
	return 0;
}
static Command dalekSpeakCmd =
{
	.name        = "dalek-speak",
	.description = "Make the dalek speak",
	.function    = dalekSpeakFn
};

static int dalekLookFn (uint argc, char*const*const argv)
{
	if (argc != 3)
	{
		PIO_LOG_ERROR ("usage: %s <alt> <az>", argv[0]);
		return -EINVAL;
	}
	int start_alt = 0;
	int start_az = 0;
	int alt = pixi_parseLong (argv[1]);
	int az  = pixi_parseLong (argv[2]);
	int inc = 1;
	pixiOpenOrDie();
	pixi_dalek_look (start_alt, start_az, alt, az, inc);
	return 0;
}
static Command dalekLookCmd =
{
	.name        = "dalek-look",
	.description = "Move the dalek's eye piece",
	.function    = dalekLookFn
};

static const Command* commands[] =
{
	&dalekRemoteCmd,
	&dalekDemoCmd,
	&dalekSpeakCmd,
	&dalekLookCmd,
};

static CommandGroup dalekGroup =
{
	.name      = "dalek",
	.count     = ARRAY_COUNT(commands),
	.commands  = commands,
	.nextGroup = NULL
};

static void PIO_CONSTRUCTOR (10002) initGroup (void)
{
	addCommandGroup (&dalekGroup);
}
