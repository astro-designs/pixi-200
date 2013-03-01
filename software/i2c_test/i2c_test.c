// I2C example c code for the Raspberry pi
// Written to test I2C interfaces on PiXi-200
// Based on original code by James Henderson, 2012.

// Usage: channel slave_address read(1)/write(0) read_length/write_byte1 write_byte2 write_byte3...
// Usage example: write three bytes
// i2c_test channel slave_address 0 write_byte1 write_byte2 write_byte3
// Usage example: read 3 bytes
// i2c_test channel slave_address 1 3
// Usage example: run test no. 2
// i2c_test 2

// Test no. 1: Write single byte
// Test no. 2: Read single byte
// Test no. 3: Write single byte to EEPROM address 0x00 and read back

#include <stdio.h>
#include <stdlib.h>
#include <linux/i2c-dev.h>
#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char **argv)
{
   printf("**** I2C Read / Write program ****\n");
   
   int  fd;                         // File descrition
   char *fileName0 = "/dev/i2c-0";  // Name of the port we will be using
   char *fileName1 = "/dev/i2c-1";  // Name of the port we will be using
   int  channel;                    // I2C Channel No.
   int  address;                    // I2C Slave Address
   int  i2c_fn_address;             // Modified slave address
   int  rnw;                        // Read / Write flag
   char buf[16];                    // Data buffer
   int  length;                     // No. of bytes to read or write
   int  testno;                     // Test selection no.
   int  i;

   printf("Arguments: %d\n",argc);
   if (argc < 5) {
      channel = 1;
      address = 0x4C;
      printf("Missing arguments, assuming default channel = %d, slave address = 0x%2x.\n", channel, address);
      if (argc != 2) {
         testno = 1; // Default test no. = 1 if not specified
         printf("Missing arguments, assuming default test no. = %d.\n", testno);
      }
      else
         testno = atoi(argv[1]);

   }
   else {
      testno = 0;                   // No tests to run / normal operation
      channel = atoi(argv[1]);      // Get I2C channel option
      address = atoi(argv[2]);      // Get I2C slave address
      i2c_fn_address = address;     // Tweak slave address so it's compatible with i2c function
      rnw = atoi(argv[3]);          // Get I2C read / write mode option
      if (rnw == 0) {
         length = argc-4;           // Get no of I2C bytes to write
         for (i = 1; i <= length; i++) // Get I2C data 
            buf[i-1] = atoi(argv[3+i]);
      }
      else
         length = atoi(argv[4]);    // Get no of I2C bytes to read
   }

   // Open the specified I2C channel
   if (channel == 0) {
      if ((fd = open(fileName0, O_RDWR)) < 0) {
         printf("Failed to open i2c port\n");
         exit(1);
      }
   }
   else {
      if ((fd = open(fileName1, O_RDWR)) < 0) {
         printf("Failed to open i2c port\n");
         exit(1);
      }
   }

   // Run tests
   if (testno == 0) { // No test, run specified normal read or write operation
      // Set the port options and set the address of the device we wish to speak to
      if (ioctl(fd, I2C_SLAVE, i2c_fn_address) < 0) {
         printf("Unable to get bus access to talk to slave\n");
         exit(1);
      }

      if (rnw == 0) { // Write...
         printf("I2C test %d\n", testno);
         printf("Writing %d bytes to I2C channel: %d, address: 0x%02x\n", length, channel, address);
         if ((write(fd, buf, length)) != length) {
            printf("Error writing to slave\n");
            exit(1);
         }
         else {
            printf("Written I2C channel: %d, address: 0x%02x, length: %d, ", channel, address, length);
            for (i = 1; i <= length; i ++)
               printf("0x%02x ",buf[i-1]);
            printf("\n");
         }
      }
      else { // Read...
         printf("Reading %d bytes from I2C channel: %d, address: 0x%02x\n", length, channel, address);
         if (read(fd, buf, length) != length) {
            printf("Unable to read from slave\n");
            exit(1);
         }
         else {
            printf("Read I2C channel: %d, address: 0x%02x, Response: ", channel, address);
            for (i = 1; i <= length; i ++)
               printf("0x%02x ",buf[i-1]);
            printf("\n");
         }
      }
   }

   if (testno == 1) { // Write 1 byte
      // Set the port options and set the address of the device we wish to speak to
      if (ioctl(fd, I2C_SLAVE, i2c_fn_address) < 0) {
         printf("Unable to get bus access to talk to slave\n");
         exit(1);
      }
      buf[0] = 0xa5;
      printf("I2C test no. %d: Write 0x%02x\n", testno, buf[0]);
   
      if ((write(fd, buf, 1)) != 1) {
         printf("Error writing to slave\n");
         exit(1);
      }
   }

   if (testno == 2) { // Read 1 byte
      // Set the port options and set the address of the device we wish to speak to
      if (ioctl(fd, I2C_SLAVE, i2c_fn_address) < 0) {
         printf("Unable to get bus access to talk to slave\n");
         exit(1);
      }
      printf("I2C test no. %d: Read 1 byte...\n", testno);
      if (read(fd, buf, 1) != 1) {
         printf("Unable to read from slave\n");
         exit(1);
      }
      else
         printf("Read: 0x%02x \n",buf[0]);
   }

   if (testno == 3) { // Write byte toe EEPROM address, read back and compare
      // Set the port options and set the address of the device we wish to speak to
      if (ioctl(fd, I2C_SLAVE, i2c_fn_address) < 0) {
         printf("Unable to get bus access to talk to slave\n");
         exit(1);
      }
      buf[0] = 0x00; // Write address
      buf[1] = 0xa5; // Write data
      printf("I2C test %d: Write 0x%2x to EEPROM address 0x%02x\n", testno, buf[1], buf[0]);
      if ((write(fd, buf, 2)) != 2) {
         printf("Error writing to EEPROM\n");
         exit(1);
      }

      if (read(fd, buf, 1) != 1) {
         printf("Unable to read from slave\n");
         exit(1);
      }
      else
         printf("Read: 0x%02x \n",buf[0]);
   }

   if (testno == 4) { // Scan for responses
      printf("Scanning slave addresses 0 to 127...\n");
      buf[0] = 0x00; // Read address
      for (address = 0; address <= 127; address = address + 1) {
         i2c_fn_address = address;     // Tweak slave address so it's compatible with i2c function
         // Set the port options and set the address of the device we wish to speak to
         if (ioctl(fd, I2C_SLAVE, i2c_fn_address) < 0) {
            printf("Address: %d, Unable to get bus access to talk to slave", address);
            exit(1);
         }
         
         printf("Slave Address: 0x%02x: ", address);
         if (read(fd, buf, 1) != 1) {
            printf("Unable to read from slave\n");
         }
         else
            printf("Read: 0x%02x \n", buf[0]);
      }
   }
   return 0;
}
