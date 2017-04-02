#include <stdio.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include <stdlib.h>
#include "altera_avalon_timer_regs.h"
#include "altera_avalon_timer.h"

#define BIT0 1
#define BIT1 2
#define BIT2 4
#define BIT3 8

#define BIT4 16
#define BIT5 32
#define BIT6 64
#define BIT7 128

#define VGA_STREAM_OUT 0x02000040 // base of the vga stream
#define VGA_WRITE BIT6
#define VGA_BUFF_SEND(C_DAT) IOWR_ALTERA_AVALON_PIO_DATA(0x2000010, BIT7|C_DAT|VGA_WRITE)
#define VGA_STREAM_END(foo) IOWR_ALTERA_AVALON_PIO_DATA(0x2000010, ~(VGA_WRITE|BIT7))



#define NES_COLOURS_MAX 64

#define FRAME_BUFF_SIZE  61440//240*256
int main()
{
	unsigned int count =0;
    unsigned int test_cdat = 0;
    printf("This program is running from SDRAM!\n");
    // sdram to onchip
    // onchip starts at 0x0200_8000 for 256 bytes ends at 0x0200_80FF

    while(1) {
        test_cdat++;
    	if(test_cdat > 63)
    		test_cdat = 0;
    	VGA_STREAM_END();
    	VGA_BUFF_SEND(test_cdat);
    }

  return 0;
}
