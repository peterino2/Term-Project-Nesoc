/*
	PPU.sv
*/
module ppu_top();

endmodule

module ppu_core( 				// PPU Component
	input logic [2:0] CPUA,		// PPU register select Selects ppu register 0-7 (mapped to $2000-$2007 by PPUMMC)
	input logic [7:0] CPUDI,  	// CPU data input
	output logic[7:0] CPUDO,  	// CPU data read 
	input logic CPUCLK,			// Cpu clock for read/write 
	input logic RW, 			// Read/Write
	input logic CS, 			// Chip Select
	input logic RST,			// Chip reset
	output logic NMI,			// Non interruptable Interrupted (signifies the start of VBLANK)
	output logic ALE, 			// Address latch enable
	output logic [13:0] APPU, 	// Address and data pins 
	output logic [7:0] PPUDO, 	// PPU data output
	input logic [7:0] PPUDI, 	// PPU data input 
	output logic [5:0]VGA_STREAM_DATA, // PPU video pipeline out
	output logic VGA_STREAM_READY,	// ppu video ready output
	input logic PPU_SLOW_CLOCK // phase locked ppu slow processing clock
);


// All this does right now is output a colour
assign VGA_STREAM_DATA = 'h27;

logic [9:0]pixel_x;
logic [9:0]pixel_y; // 

// ========= PIXEL GENERATOR FSM ==============

endmodule
