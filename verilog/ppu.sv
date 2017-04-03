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
	output logic [7:0] PPU_PTR_X,
	output logic [7:0] PPU_PTR_Y,
	output logic VGA_STREAM_READY,	// ppu video ready output
	input logic PPU_SLOW_CLOCK // phase locked ppu slow processing clock
);

parameter X_PIXELS = 340; 	// The maximum number of pixels per scanline
parameter Y_PIXELS = 240;	// the maximum number of scanlinesh
parameter PATTERN_TABLE_0 = 'h0000;
parameter PATTERN_TABLE_1 = 'h1000;
parameter PPU_RAM = 'h2000;// 2kb divided into name tables
parameter NT_0 = 'h2000;
parameter NT_1 = 'h2400;
parameter NT_2 = 'h2800;
parameter NT_3 = 'h2C00;
parameter NT_MIRROR = 'h3000;
parameter OAM_SPR_YPOS = 0;
parameter OAM_SPR_INDX = 1;
parameter OAM_SPR_ATTR = 2;
parameter OAM_SPR_XPOS = 3;


logic [9:0]pixel_x=0;
logic [7:0]pixel_y=0; // 
logic [17:0]frame_pix;
assign frame_pix = {pixel_y[7:0],pixel_x[9:0]};
logic [5:0]cdat_out=0;

assign VGA_STREAM_DATA = cdat_out;
assign PPU_PTR_X = {pixel_x[7:0]};
assign PPU_PTR_Y = pixel_y;
// PPU OBJECT ATTRIBUTE MEMORY (OAM)
// EACH SPRITE CONTAINS 4 BYTES OF INFORMATION USED FOR RENDERINIG

logic [7:0]OAM[255:0];
logic [13:0]ppu_ab;
// CHR ROM 
logic [7:0] CHR_ROM ['h1FFF:0]; // CHR ROM location
logic [11:0] chr_rom_ptr;
assign chr_rom_ptr = {ppu_ab[11:0]};
/*
initial begin // We dont have time to test all programming we are only gonna use preloaded data for this test.
	$readmemh("CHR_ROM.dat", CHR_ROM);
end */
// ========= PIXEL GENERATOR FSM ==============

always_ff@(posedge PPU_SLOW_CLOCK)begin 
	if(RST)begin
	
	end else begin
		pixel_x = pixel_x + 1; 
		if(pixel_x == X_PIXELS) begin
			pixel_x = 0;
			pixel_y = pixel_y + 1;
			if (pixel_y == Y_PIXELS) 
				pixel_y = 0;
		end
	end
	cdat_out = cdat_out + 1;
end


endmodule
