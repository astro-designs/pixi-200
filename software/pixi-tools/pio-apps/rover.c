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
#include "Command.h"
#include "log.h"

const uint MotorGpioController = 2;
const uint MotorGpioPin        = 0;

// PWM pins
const uint FrontLeft  = 7;
const uint BackLeft   = 6;
const uint FrontRight = 5;
const uint BackRight  = 4;

typedef enum MotorDirection {
	Forward = 0,
	Reverse = 1
} MotorDirection;

const uint MotorDirectionValues[2] = {0, 0x8000};

static void prepare (void)
{
	pixiOpenOrDie();
	pixiAdcOpenOrDie();
//	gpioSetPinMode (MotorGpioController, MotorGpioPin, ??);
	gpioWritePin   (MotorGpioController, MotorGpioPin, true);
}

static void unprepare (void)
{
	gpioWritePin (MotorGpioController, MotorGpioPin, false);
	pixiAdcClose();
	pixiClose();
}

static double readVoltage (void)
{
	double power = adcRead (0);
	double voltage = 10.277 * power / 4096.0;
	return voltage;
}

static void moveRover (MotorDirection leftSide, MotorDirection rightSide, double speed)
{
	uint pwmSpeed = ((uint) (speed * 1023.0 / 100.0)) & 0x000003ff;
	PIO_LOG_INFO ("moveRover left=%d right=%d speed=%f pwmSpeed=0x%4x", leftSide, rightSide, speed, pwmSpeed);

	// each side must be synchronised, but each side the motors are opposed:
	pwmWritePin (FrontRight, pwmSpeed + MotorDirectionValues[ rightSide]);
	pwmWritePin (BackRight , pwmSpeed + MotorDirectionValues[!rightSide]);
	pwmWritePin (BackLeft  , pwmSpeed + MotorDirectionValues[!leftSide ]);
	pwmWritePin (FrontLeft , pwmSpeed + MotorDirectionValues[ leftSide ]); // Front left must be last!
}

static void moveForward  (double speed) {moveRover (Forward, Forward, speed);}
static void moveBackward (double speed) {moveRover (Reverse, Reverse, speed);}
static void turnLeft     (double speed) {moveRover (Reverse, Forward, speed);}
static void turnRight    (double speed) {moveRover (Forward, Reverse, speed);}

static void rest (void) {
	PIO_LOG_INFO("Power = %.3fv", readVoltage());
	PIO_LOG_INFO("Waiting...");
	sleep (2);
	PIO_LOG_INFO("Power = %.3fv", readVoltage());
}

static int roverFn (uint argc, char*const*const argv)
{
	if (argc != 3)
	{
		PIO_LOG_ERROR ("usage: %s f[orward]|b[ackward]|l[eft]|r[ight] speed", argv[0]);
		return -EINVAL;
	}

	const char* move = argv[1];
	double speed = atof (argv[2]);

	prepare();
	PIO_LOG_INFO("Power = %.3fv", readVoltage());
	if      (pixi_strStartsWithI ("forward" , move)) moveForward  (speed);
	else if (pixi_strStartsWithI ("backward", move)) moveBackward (speed);
	else if (pixi_strStartsWithI ("left"    , move)) turnLeft     (speed);
	else if (pixi_strStartsWithI ("right"   , move)) turnRight    (speed);
	else
		PIO_LOG_ERROR ("Unknown movement: %s", move);
	rest();
	unprepare();
	return 0;
}

static Command roverCmd =
{
	.name        = "rover",
	.description = "Move the rover in a given way at a given speed",
	.function    = roverFn
};

static int roverDemoFn (uint argc, char*const*const argv)
{
	double speed = 100;
	if (argc > 1)
		speed = atof (argv[1]);

	prepare();
	moveForward  (speed); rest();
	moveBackward (speed); rest();
	turnLeft     (speed); rest();
	turnRight    (speed); rest();
	unprepare();
	return 0;
}

static Command roverDemoCmd =
{
	.name        = "rover-demo",
	.description = "Run a sequence of four moves to demonstrate the rover",
	.function    = roverDemoFn
};

static const Command* commands[] =
{
	&roverCmd,
	&roverDemoCmd,
};

static CommandGroup roverGroup =
{
	.name      = "rover",
	.count     = ARRAY_COUNT(commands),
	.commands  = commands,
	.nextGroup = NULL
};

static void PIO_CONSTRUCTOR (10001) initGroup (void)
{
	addCommandGroup (&roverGroup);
}
