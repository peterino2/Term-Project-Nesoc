#include <stdio.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include <stdlib.h>
#include "altera_avalon_timer_regs.h"
#include "altera_avalon_timer.h"

#define TEST_TIMER_BASE 0x0200020 	// timer base
#define FRAME_BUFF_SIZE  61440//240*256
int main()
{
    printf("This program is running from SDRAM!\n");
    void* frameBuffer =  malloc(61440);
    void* secondMalloc = malloc(10000); // lets allocate 10 megabytes for funzies
    int count = 0;
    printf("malloc working returned: %08x\n", (unsigned int)frameBuffer);
    printf("huge 10MB block at: %08x", (unsigned int)secondMalloc);
    void* scanstart = (void*)0x02008000; // test to see how long it takes to copy 256 bytes from
    // sdram to onchip
    // onchip starts at 0x0200_8000 for 256 bytes ends at 0x0200_80FF
    unsigned int i = 1;
    unsigned int tv_0 = 0;	//timer value 0
    unsigned int tv_1 = 0;	// timer value 1
    while(1) {
    	IOWR_ALTERA_AVALON_TIMER_SNAPL( 0x02000020, 0xFFFF);
    	tv_0 = IORD_ALTERA_AVALON_TIMER_SNAPL(0x02000020);

    	for(i = 0;i< 256;i++){
    		*(int*)(scanstart+i) = *(int*)(frameBuffer + i);
    	}
    	IOWR_ALTERA_AVALON_TIMER_SNAPL( 0x02000020, 0xFFFF);
    	tv_1 = IORD_ALTERA_AVALON_TIMER_SNAPL(0x02000020);
    	printf("%u %u %u\n", tv_0, tv_1, tv_1 - tv_0);
    	IOWR_ALTERA_AVALON_PIO_DATA(LED_BASE, count & 0x01);
        count++;
    }

  return 0;
}
