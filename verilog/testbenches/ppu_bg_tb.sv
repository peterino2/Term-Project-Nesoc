module ppu_bkg_tb();

logic [2:0] CPUA;		// PPU register select Selects ppu register 0-7 (mapped to $2000-$2007 by PPUMMC)
logic [7:0] CPUDI;  	// CPU data input
logic[7:0] CPUDO; 	// CPU data read 
logic CPUCLK;			// Cpu clock for read/write 
logic RW; 			// Read/Write
logic CS; 			// Chip Select
logic RST;			// Chip reset
logic NMI;			// Non interruptable Interrupted (signifies the start of VBLANK)
logic ALE; 			// Address latch enable
logic [13:0] APPU; 	// Address and data pins 
logic [7:0] PPUDO; 	// PPU data output
logic [7:0] PPUDI; 	// PPU data input 
logic [5:0]VGA_STREAM_DATA; // PPU video pipeline out
logic [7:0] PPU_PTR_X;
logic [7:0] PPU_PTR_Y;
logic VGA_STREAM_READY;	// ppu video ready output
logic PPU_SLOW_CLOCK; // phase locked ppu slow processing clock

ppu_core dut0(.*);

	initial begin
	PPU_SLOW_CLOCK = '0;
	end

   // clock
   always
     #10ns PPU_SLOW_CLOCK = ~PPU_SLOW_CLOCK ;

endmodule
