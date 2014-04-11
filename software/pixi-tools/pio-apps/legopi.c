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

static int pixi_truck_stop(int duration);
static int pixi_truck_f(int speed, int duration);
static int pixi_truck_fl(int speed, int duration);
static int pixi_truck_fr(int speed, int duration);
static int pixi_truck_b(int speed, int duration);
static int pixi_truck_bl(int speed, int duration);
static int pixi_truck_br(int speed, int duration);
static int pixi_truck_l(int speed, int duration);
static int pixi_truck_r(int speed, int duration);
static int pixi_truck_demo(int demo);
static int pixi_truck_remote(int demo);



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
 * truck_stop:
 *********************************************************************************
 */
int pixi_truck_stop(int duration)
{
   // Setup GPIO2 mode
   pixi_spi_set(0, 0x2A, 0x5555);
   pixi_spi_set(0, 0x2B, 0x5555);

   // f/b & steering...
   pixi_spi_set(0, 0x23, 0x3d);

   // Disable f/b motor
   // Get current motor status
   pixi_spi_set(0, 0x24, 0x00ff);

   usleep(1000000 * duration);
   return(0);
}

/*
 * truck_forward:
 *********************************************************************************
 */
int pixi_truck_f(int speed, int duration)
{
//   float left_mult = 1.0;
//   float right_mult = 1.0;

//   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
//   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // Setup GPIO2 mode
   pixi_spi_set(0, 0x2A, 0x5555);
   pixi_spi_set(0, 0x2B, 0x5555);

   // f/b & steering...
   pixi_spi_set(0, 0x23, 0x3e);

   // Enable motor
   // Get current motor status
   pixi_spi_set(0, 0x24, 0x00fc);

   usleep(1000000 * duration);
   return(0);
}

/*
 * truck_forward:
 *********************************************************************************
 */
int pixi_truck_fl(int speed, int duration)
{
//   float left_mult = 1.0;
//   float right_mult = 1.0;

//   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
//   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // Setup GPIO2 mode
   pixi_spi_set(0, 0x2A, 0x5555);
   pixi_spi_set(0, 0x2B, 0x5555);

   // f/b & steering...
   pixi_spi_set(0, 0x23, 0x36);

   // Enable motor
   // Get current motor status
   pixi_spi_set(0, 0x24, 0x00fc);

   usleep(1000000 * duration);
   return(0);
}

/*
 * truck_forward:
 *********************************************************************************
 */
int pixi_truck_fr(int speed, int duration)
{
//   float left_mult = 1.0;
//   float right_mult = 1.0;

//   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
//   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // Setup GPIO2 mode
   pixi_spi_set(0, 0x2A, 0x5555);
   pixi_spi_set(0, 0x2B, 0x5555);

   // f/b & steering...
   pixi_spi_set(0, 0x23, 0x3a);

   // Enable motor
   // Get current motor status
   pixi_spi_set(0, 0x24, 0x00fc);

   usleep(1000000 * duration);
   return(0);
}

/*
 * truck_backward:
 *********************************************************************************
 */
int pixi_truck_b(int speed, int duration)
{
//   float left_mult = 1.0;
//   float right_mult = 1.0;

//   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
//   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // Setup GPIO2 mode
   pixi_spi_set(0, 0x2A, 0x5555);
   pixi_spi_set(0, 0x2B, 0x5555);

   // f/b & steering...
   pixi_spi_set(0, 0x23, 0x3d);

   // Enable motor
   // Get current motor status
   pixi_spi_set(0, 0x24, 0x00fc);

   usleep(1000000 * duration);
   return(0);
}

/*
 * truck_backward:
 *********************************************************************************
 */
int pixi_truck_bl(int speed, int duration)
{
//   float left_mult = 1.0;
//   float right_mult = 1.0;

//   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
//   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // Setup GPIO2 mode
   pixi_spi_set(0, 0x2A, 0x5555);
   pixi_spi_set(0, 0x2B, 0x5555);

   // f/b & steering...
   pixi_spi_set(0, 0x23, 0x35);

   // Enable motor
   // Get current motor status
   pixi_spi_set(0, 0x24, 0x00fc);

   usleep(1000000 * duration);
   return(0);
}

/*
 * truck_backward:
 *********************************************************************************
 */
int pixi_truck_br(int speed, int duration)
{
//   float left_mult = 1.0;
//   float right_mult = 1.0;

//   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
//   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // Setup GPIO2 mode
   pixi_spi_set(0, 0x2A, 0x5555);
   pixi_spi_set(0, 0x2B, 0x5555);

   // f/b & steering...
   pixi_spi_set(0, 0x23, 0x39);

   // Enable motor
   // Get current motor status
   pixi_spi_set(0, 0x24, 0x00fc);

   usleep(1000000 * duration);
   return(0);
}

/*
 * truck_left:
 *********************************************************************************
 */
int pixi_truck_l(int speed, int duration)
{
//   float left_mult = 1.0;
//   float right_mult = 1.0;

//   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
//   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // Setup GPIO2 mode
   pixi_spi_set(0, 0x2A, 0x5555);
   pixi_spi_set(0, 0x2B, 0x5555);

   // f/b & steering...
   pixi_spi_set(0, 0x23, 0x35);

   // Enable motor
   // Get current motor status
   pixi_spi_set(0, 0x24, 0x00ff);

   usleep(1000000 * duration);
   return(0);
}

/*
 * truck_right:
 *********************************************************************************
 */
int pixi_truck_r(int speed, int duration)
{
//   float left_mult = 1.0;
//   float right_mult = 1.0;

//   pixi_spi_set(0, 0x40, (int)(speed * left_mult));
//   pixi_spi_set(0, 0x41, (int)(speed * right_mult));

   // Setup GPIO2 mode
   pixi_spi_set(0, 0x2A, 0x5555);
   pixi_spi_set(0, 0x2B, 0x5555);

   // f/b & steering...
   pixi_spi_set(0, 0x23, 0x39);

   // Enable motor
   // Get current motor status
   pixi_spi_set(0, 0x24, 0x00ff);

   usleep(1000000 * duration);
   return(0);
}


/*
 * truck Demo:
 *********************************************************************************
 */
int pixi_truck_demo(int demo)
{
   pixi_spi_set (0, 0x27, 0); // Set up GPIO1 for input

   while (1) {

   printf("Press the button to start...\n");
   // Wait for button to be pressed
   while ((pixi_spi_get(0, 0x20, 0) & 0x0001) == 1) { // GPIO1(0)
   }

   printf("Starting Demo...\n");

   usleep(5000000);

// forward for 2s
   pixi_truck_f(512,0);
// turn 180 degrees
   pixi_truck_r(1023,2);
// forward for 2s
   pixi_truck_f(512,0);
// stop
   pixi_truck_stop(1);

// turn right / look straight ahead
   pixi_truck_r(512,0);
   pixi_truck_stop(1);
// forward 0.5s
   pixi_truck_f(512,1);
   pixi_truck_stop(1);


} // while...

   return(demo);
}

/*

 * Truck Remote:
 *********************************************************************************
 */
int pixi_truck_remote(int demo)
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
			else if (buf[0] == '4')
			{
                pixi_truck_l(512,0);
				printf("Left...\n");
			}
			else if (buf[0] == '6')
			{
                pixi_truck_r(512,0);
				printf("Right...\n");
			}
			else if (buf[0] == '8')
			{
                pixi_truck_f(512,0);
				printf("Forwards...\n");
			}
			else if (buf[0] == '7')
			{
                pixi_truck_fl(512,0);
				printf("Forwards...\n");
			}
			else if (buf[0] == '9')
			{
                pixi_truck_fr(512,0);
				printf("Forwards...\n");
			}
			else if (buf[0] == '2')
			{
                pixi_truck_b(512,0);
				printf("Backwards...\n");
			}
			else if (buf[0] == '1')
			{
                pixi_truck_bl(512,0);
				printf("Backwards...\n");
			}
			else if (buf[0] == '3')
			{
                pixi_truck_br(512,0);
				printf("Backwards...\n");
			}
			else if (buf[0] == '5')
			{
                pixi_truck_stop(0);
				printf("Stop...\n");
			}
			if (isprint(buf[0]))
				printf("printable:%c", buf[0]);
		}
		printf("\n");
	}
	ttyInputNormal (STDIN_FILENO);
    return(demo);
}	
	
	
static int truckDemoFn (uint argc, char*const*const argv)
{
	if (argc != 1)
	{
		PIO_LOG_ERROR ("usage: %s", argv[0]);
		return -EINVAL;
	}
	pixiOpenOrDie();
	pixi_truck_demo (0);
	return 0;
}
static Command truckDemoCmd =
{
	.name        = "truck-demo",
	.description = "Run a sequence of moves to demonstrate the truck",
	.function    = truckDemoFn
};

static int truckRemoteFn (uint argc, char*const*const argv)
{
	if (argc != 1)
	{
		PIO_LOG_ERROR ("usage: %s", argv[0]);
		return -EINVAL;
	}
	pixiOpenOrDie();
	pixi_truck_remote (0);
	return 0;
}
static Command truckRemoteCmd =
{
	.name        = "truck-remote",
	.description = "Allows the truck to be controlled from the keyboard...",
	.function    = truckRemoteFn
};

static const Command* commands[] =
{
	&truckRemoteCmd,
	&truckDemoCmd,
};

static CommandGroup truckGroup =
{
	.name      = "truck",
	.count     = ARRAY_COUNT(commands),
	.commands  = commands,
	.nextGroup = NULL
};

static void PIO_CONSTRUCTOR (10002) initGroup (void)
{
	addCommandGroup (&truckGroup);
}
