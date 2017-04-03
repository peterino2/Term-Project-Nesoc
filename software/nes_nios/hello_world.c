
// this is a

#include <stdio.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include <stdlib.h>
#include "altera_avalon_timer_regs.h"
#include "altera_avalon_timer.h"
#include <sys/alt_irq.h>
#include <priv/alt_legacy_irq.h>
#include <io.h>
#include <alt_types.h>

//alt_irq_disable_all
//alt_irq_init
//alt_ic_isr_register
#define BIT0 1
#define BIT1 2
#define BIT2 4
#define BIT3 8

#define BIT4 16
#define BIT5 32
#define BIT6 64
#define BIT7 128

#define VGA_STREAM_OUT 0x02000010 // base of the vga stream
#define VGA_WRITE BIT6
#define VGA_BUFF_SEND(C_DAT) IOWR_ALTERA_AVALON_PIO_DATA(VGA_STREAM_OUT, BIT7|C_DAT|VGA_WRITE)
#define VGA_STREAM_LATCH_RESET(foo) IOWR_ALTERA_AVALON_PIO_DATA(VGA_STREAM_OUT, 0)


#define VGA_STREAM_IRQ 2
#define NES_COLOURS_MAX 64

#define FRAME_BUFFER_SIZE 61440
#define FRAME_BUFFER_XMAX 256
#define FRAME_BUFFER_YMAX 240

volatile char FRAME_BUFFER[FRAME_BUFFER_SIZE]={0}; // Huge block for frame_buffer
volatile char* frame_buffer_ptr = FRAME_BUFFER;

void init_vga_read(){
	static int i = 0;
	IOWR_ALTERA_AVALON_PIO_CLEAR_BITS(0x2000000,0x1);
	for ( i = 0 ; i < 256; i++){
		VGA_STREAM_LATCH_RESET();
		VGA_BUFF_SEND(*(FRAME_BUFFER+i));
	}
	VGA_STREAM_LATCH_RESET();
}

int main()
{
    unsigned int c_dat = 0;
    unsigned int i,j;
    printf("This progsdsdram is running from SDRAM!dwhajkdhskjalhdkjslahdfdjald\n");
    // sdram to onchip
    // onchip starts at 0x0200_8000 for 256 bytes ends at 0x0200_80FF
  //  alt_irq_register(VGA_STREAM_IRQ, NULL, init_vga_read ); // register the irq
   // IOWR_ALTERA_AVALON_PIO_IRQ_MASK(0x2000000, 0xff);
   // alt_irq_enable_all(0);
    for (i = 0; i< 240; i++){
    	for(j = 0 ; j < 256; j++){
    		if(j < 128) c_dat = 0x11;
    		else c_dat = 0x38;
    		FRAME_BUFFER[((i<<8)+j)] = c_dat;
    	}
    }
    while(1) {
    	VGA_BUFF_SEND(0);

        VGA_STREAM_LATCH_RESET();
    }

  return 0;
}
