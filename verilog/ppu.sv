/*
	PPU.sv
*/

// This version of the module tests the PPU's ability to draw images without external input
// OAM and NT will be initialized to known values
// Test image: draw the mario sprite as a background and we are gonna use NT_1 for 
// 

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


// ========= frame timing parameters =========
parameter X_PIXELS = 340; 	// The maximum number of pixels per scanline
parameter Y_PIXELS = 262;	// the maximum number of scanlinesh
parameter X_BPORCH = 256; // start of the x pixel backgporch
parameter Y_BPORCH = 240; // start of the y pixel backgporch
parameter PATTERN_TABLE_0 = 'h0000; // Sprites
parameter PATTERN_TABLE_1 = 'h1000; // Backgrounds

// ============ nametable parameters =========
parameter NT_0 = 'h2000;
parameter NT_1 = 'h2400;
parameter NT_2 = 'h2800;	// NOT NEEDED
parameter NT_3 = 'h2C00;	// NOT NEEDED
parameter NT_MIRROR = 'h3000;

// ============ OAM ELEMENT OFFSETs ==============
parameter OAM_SPR_YPOS = 0;
parameter OAM_SPR_INDX = 1;
parameter OAM_SPR_ATTR = 2;
parameter OAM_SPR_XPOS = 3;

// ============ NES REGISTERS ==============

logic [7:0] PPUCTL = {'b0101_0000};		// 2000 - PPUCTL
logic [7:0] PPUMASK;		// 2001
logic [7:0] PPUSTATUS;	// 2002 
logic [7:0] OAMADDR;		// 2003
logic [7:0] OAMDATA;		// 2004
logic [7:0] PPUSCROLL;	// 2005
logic [7:0] PPUADDR;		// 2006
logic [7:0] PPUDATA;		// 2007


logic [9:0]pixel_x=0;  // x pixel for fsm
logic [9:0]pixel_x_next =0;  // x pixel for fsm
logic [7:0]pixel_y=0;  // y pixel for fsm
logic [7:0]pixel_y_next=0;  // y pixel for fsm

logic [5:0]cdat_out=0; // output pixel data


// ========= BKG RENDERING ROM =================
// Consists of name and attribute tables 
logic [7:0]NAME_TABLE_0[959:0];
logic [7:0]ATTR_TABLE_0[63:0];
logic [7:0]NAME_TABLE_1[959:0];
logic [7:0]ATTR_TABLE_1[63:0];
logic [7:0] CHR_ROM ['h1FFF:0]; 

// ============= PALLETES ================
// 0-3 is pallete 0 
// 4-7 is pallete 1
// 8-B is pallete 2
// C-F is pallete 3

logic [5:0]BKG_PALLETES[15:0]; 
logic [5:0]SPR_PALLETES[15:0];

// We dont have time to test all programming we are only gonna use preloaded data for this test.
initial begin 
	$readmemh("CHR_ROM.dat", CHR_ROM);
	// Auto generated test colours palletes
	BKG_PALLETES[0] = 'h0F; // black
	BKG_PALLETES[1] = 'h00; // grey
	BKG_PALLETES[2] = 'h10; // blue
	BKG_PALLETES[3] = 'h30; // red
	
	BKG_PALLETES[4] = 'h0F; // black
	BKG_PALLETES[5] = 'h01; // yellow
	BKG_PALLETES[6] = 'h21; // green
	BKG_PALLETES[7] = 'h31; // red
	
	BKG_PALLETES[8] = 'h0F; // black
	BKG_PALLETES[9] = 'h20; // teal
	BKG_PALLETES[10] = 'h36; // blue
	BKG_PALLETES[11] = 'h06; // red
	
	BKG_PALLETES[12] = 'h0F; // black
	BKG_PALLETES[13] = 'h2A; // orange
	BKG_PALLETES[14] = 'h1A; // red
	BKG_PALLETES[15] = 'h0A; // green
/*	BKG_PALLETES[0] = 'h0F; // black
	BKG_PALLETES[1] = 'h00; // grey
	BKG_PALLETES[2] = 'h01; // blue
	BKG_PALLETES[3] = 'h05; // red
	BKG_PALLETES[4] = 'h0F; // black
	BKG_PALLETES[5] = 'h28; // yellow
	BKG_PALLETES[6] = 'h2A; // green
	BKG_PALLETES[7] = 'h16; // red
	BKG_PALLETES[8] = 'h0F; // black
	BKG_PALLETES[9] = 'h2C; // teal
	BKG_PALLETES[10] = 'h12; // blue
	BKG_PALLETES[11] = 'h16; // red
	BKG_PALLETES[12] = 'h0F; // black
	BKG_PALLETES[13] = 'h27; // orange
	BKG_PALLETES[14] = 'h06; // red
	BKG_PALLETES[15] = 'h1A; // green 
	
	

		
	BKG_PALLETES[0] = 'h0F; // black
	BKG_PALLETES[1] = 'h00; // grey
	BKG_PALLETES[2] = 'h01; // blue
	BKG_PALLETES[3] = 'h05; // red
	BKG_PALLETES[4] = 'h0F; // black
	BKG_PALLETES[5] = 'h28; // yellow
	BKG_PALLETES[6] = 'h2A; // green
	BKG_PALLETES[7] = 'h16; // red
	BKG_PALLETES[8] = 'h0F; // black
	BKG_PALLETES[9] = 'h2C; // teal
	BKG_PALLETES[10] = 'h12; // blue
	BKG_PALLETES[11] = 'h16; // red
	BKG_PALLETES[12] = 'h0F; // black
	BKG_PALLETES[13] = 'h27; // orange
	BKG_PALLETES[14] = 'h06; // red
	BKG_PALLETES[15] = 'h1A; // green */


	//$readmemh("OAM_TEST.dat", OAM); Currently testing Background and Name table rendering so
	$readmemh("NT_0.dat", NAME_TABLE_0);
	$readmemh("AT_0.dat", ATTR_TABLE_0);
end 


// ========= BKG DRAW FSM =========
/*
	note: the original nintendo PPU doesnt work like this because of limitations at the time. but this will produce an identical interface for the programmer and the games used.
	
	
	0: FETCHING (happens once per tile, and 32 tiles per scanline)
	background drawing statemachine
	on the reset or on pixel_xs where last 3 bits = 0 clock fetch the 2 byte tile slice
	referenced by the NT at this value and loads it into the 
	output SR, and outputs the 7th pixel 
	
	1: PIPING happens on every pixel that is not a fetch or HALT, shifts out the next pixel to the cdat mux (note MSB actually comes out first ) Happens at the end of each tile (whenever pixel is a multiple of 8)
	
	2: HALT NOT fetching or piping data, 
	
*/
parameter FETCHING = 0;
parameter PIPING = 1;
parameter HALT = 2;
parameter BUFF_SLICE_1 = 0;
parameter BUFF_SLICE_2 = 1;
parameter IDLE = 2;
logic [2:0] bkg_draw_state = FETCHING;
logic [2:0] bkg_draw_state2 = IDLE;

logic [4:0] tile_x;		// tile x coordinate
logic [4:0] tile_y;		// tile y coordinate 
logic [2:0] tile_col;	// column within a tile
logic [2:0] tile_row;	// row within a tile
logic [9:0] nt_ptr;		// name table pointer
logic [9:0] nt_ptr_next;// name table pointer for next tile
logic [5:0] attr_ptr;	// attribute table pointer
logic [15:0] bg_slice;	// two-bite background slice
logic [15:0] bg_slice_next;	// two-bite background slice
logic [3:0] pallete_ptr='0;// choose colour
logic [15:0] chr_ptr_0;	// chr rom pointer
logic [15:0] chr_ptr_1;	// chr rom pointer



//===============================================
//============ COMBINATIONAL BLOCK===============
//===============================================
always_comb begin 
// ----------- PIXELS COUNT INCREMENT -----------
/*	pixel_x_next = pixel_x + 1;
	pixel_y_next = (pixel_x_next == X_PIXELS)? 
		(pixel_y == Y_PIXELS) ? 
		0	:  pixel_y + 1
		: pixel_y;
*/	
	if (pixel_x == X_PIXELS-1) begin
		pixel_y_next = (pixel_y == Y_PIXELS-1) ? 0 : pixel_y + 1;
		pixel_x_next = 0;
	end
	else begin
			pixel_x_next = pixel_x + 1;
	end
// ----------- background draw state control ----
	bkg_draw_state = (pixel_y < Y_BPORCH)
		? ('{pixel_x[2:0]} == 3'b0) ? 
		FETCHING : PIPING  
	: HALT;
	
// ------------ Tile coordinates ----------------
	if (pixel_x < X_BPORCH && pixel_y < Y_BPORCH) begin
		tile_x = pixel_x >> 3;
		tile_y = pixel_y >> 3;
		tile_col = pixel_x % 8;
		tile_row = pixel_y % 8;
		nt_ptr = tile_x + tile_y * 6'd32;
		attr_ptr = (tile_x >> 2) + (tile_y >> 2) * 8;
	end
	
// ------------ Output Colour -------------------
	cdat_out = BKG_PALLETES[pallete_ptr];
	pallete_ptr[1:0] = {bg_slice[15-tile_col],bg_slice[7-tile_col]};
	
// ------------ Attribute decode ----------------
	if (tile_x % 4 < 2) begin 					// left side
		if (tile_y % 4 < 2) begin 				//top-left
		pallete_ptr[3:2] = ATTR_TABLE_0[attr_ptr][1:0];
		end
		else begin 								// bottom-left
		pallete_ptr[3:2] = ATTR_TABLE_0[attr_ptr][5:4];
		end
	end
	else begin									// right side
		if (tile_y % 4 < 2) begin 				//top-right
		pallete_ptr[3:2] = ATTR_TABLE_0[attr_ptr][3:2];
		end
		else begin 								// bottom-right
		pallete_ptr[3:2] = ATTR_TABLE_0[attr_ptr][7:6];
		end
	
	end
	
// -------- Next tile pointer -------------------
	nt_ptr_next = (nt_ptr == 10'd959) ? 0 : nt_ptr + 1;

end 



//===============================================
//================ PER CLK BLOCK  ===============
//===============================================

always_ff@(posedge PPU_SLOW_CLOCK)begin 
	if(RST)begin
	pixel_x = 0;
	pixel_y = 0;
	end else begin
		pixel_x <= pixel_x_next;
		pixel_y <= pixel_y_next;
	end
// NAMETABLE RENDER AND DRAW STATE 
	case(bkg_draw_state)
		FETCHING:begin 
			bg_slice = bg_slice_next;
			bkg_draw_state2 <= BUFF_SLICE_1;
		end 
						
		PIPING: begin 
		
		end 
		HALT: begin 
		end 
	endcase
	

end


always_ff@(posedge PPU_SLOW_CLOCK) begin

	case(bkg_draw_state2)
	BUFF_SLICE_1: begin
		///////////////////////////////////// change when chr rom chopped in two
			chr_ptr_0 = {4'b0001,NAME_TABLE_0[nt_ptr_next],1'b0,tile_row};
			bg_slice_next[15:8] = CHR_ROM[chr_ptr_0];
			bkg_draw_state2 <= BUFF_SLICE_2;
		end
		
		BUFF_SLICE_2: begin
			chr_ptr_1 = {4'b0001,NAME_TABLE_0[nt_ptr_next],1'b1,tile_row};
			bg_slice_next[7:0] = CHR_ROM[chr_ptr_1];
			bkg_draw_state2 <= IDLE;
		end
		
		IDLE: begin
		end
	endcase
end
endmodule