/*
	PPU.sv
*/

// This version of the module tests the PPU's ability to draw images without external input
// OAM and NT will be initialized to known values
// Test image: draw the mario sprite as a background and we are gonna use NT_1 for 
// 

module ppu_tb();

	logic [2:0] CPUA;	// PPU register select Selects ppu register 0-7 (mapped to $2000-$2007 by PPUMMC)
	logic [7:0] CPUDI; 	// CPU data input
	logic[7:0] CPUDO;  	// CPU data read 
	logic CPUCLK;		// Cpu clock for read/write 
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


logic PPU_SLOW_CLOCK=0; 
always begin
	#8ns;
	PPU_SLOW_CLOCK = ~PPU_SLOW_CLOCK;
end

initial begin 
	#800us;
	$stop;
end 
ppu_core ppu(.*);

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

logic [7:0] PPUCTL = 'b0101_0000;		// 2000 - PPUCTL
logic [7:0] PPUMASK;		// 2001
logic [7:0] PPUSTATUS;	// 2002 
logic [7:0] OAMADDR;		// 2003
logic [7:0] OAMDATA;		// 2004
logic [7:0] PPUSCROLL;	// 2005
logic [7:0] PPUADDR;		// 2006
logic [7:0] PPUDATA;		// 2007


// ======== NES register wire assignments =====
logic spr_base_rom;
logic bkg_base_rom;
assign spr_base_rom = PPUCTL[3];
assign bkg_base_rom = PPUCTL[4];

logic [9:0]pixel_x=0;  // x pixel for fsm
logic [9:0]pixel_x_next =0;  // x pixel for fsm
logic [7:0]pixel_y=0;  // y pixel for fsm
logic [7:0]pixel_y_next=0;  // y pixel for fsm

logic [5:0]bkg_cdat=0; // output pixel data
integer i; // general integer for loops

// ===========NT_0 ==========
logic [7:0] NAMETABLE_0[959:0];
logic [7:0] ATTRTABLE_0[63:0];
// ============ OAM ==========
logic [7:0]OAM[255:0];

// ============ sprite render logic ==========
logic [5:0] spr_cdat;
/*
	The sprite render logic consists of two finite state machines that operate in parallel,
	
	1: spr_scan which fetches data for the next scanline, chr_rom and loads it into the 8 spr_rend_buf buffers
	
*/

/*
	spr_rend_buf structure map
	
	 |-X|ML| in hex 
	 bit
	 0 - 7  LSB of sprite bitmap (spr_bmp_ls) 
	 8 - 15 MSB of sprite bitmap (spr_bmp_ms)
	 16 - 23 X position of sprite bitmap (spr_bmp_xpos)
	 24 - 32 Attribute byte contains extra rendering info
*/
logic [7:0]spr_rend_draw_flags = 0; // Draw flags for the next scanline
logic [3:0]spr_rend_pallete_colour [7:0];
logic [7:0]spr_rend_valid;
 
logic spr_scan_rend_now=1;
logic [31:0]spr_rend_buf[7:0]; // Sprite draw data for this scanline
logic [31:0]spr_draw_buf[7:0]; 
logic [7:0]spr_scan_ypos; 	// Y position of the current sprite

/* 
== CHR rom tile mappings for per slice bitmap fetching
		+-spr_base_rom
		| 
		| +-------+- Sprite index
		| |       |    
		| |       | +------ msb/lsb select for bitmap
		| |       | |+--+---Sprite slice offset
		| |       | ||  |
	|000R|SSSS|SSSS|BYYY|
	slice_base = '{3'h0,spr_base_rom,OAM[spr_scan_iter << 2],1'b0, y_offset[2:0]};
*/

logic [7:0]spr_tile_index; 
logic [2:0]spr_tile_slice;
logic [15:0]spr_tile_slice_ptr;

	
// ========== spr_scan fsm =================
parameter SPR_SCAN_SCAN = 0;
parameter SPR_SCAN_HALT = 1;
parameter SPR_REND_FETCH_TILE_LSB=2;
parameter SPR_REND_FETCH_ATTR =3;
parameter SPR_REND_FETCH_DRAW_MSB=4;
logic [2:0] spr_scan_state = SPR_SCAN_SCAN;
logic [2:0] spr_scan_state_next;
logic [7:0] spr_scan_iter = 0;
logic [2:0] spr_scan_rend_iter = 0;
logic spr_vflip;

// ========== CHR ROM =========
logic [7:0] CHR_ROM_0 ['hFFF:0]; // CHR ROM location
logic [7:0] CHR_ROM_1['hfff:0];	// background CHR

// ========= BKG RENDERING ROM =================
// Consists of name and attribute tables 
logic [7:0]NAME_TABLE_0[959:0];
logic [7:0]ATTR_TABLE_0[63:0];

logic [7:0]NAME_TABLE_1[959:0];
logic [7:0]ATTR_TABLE_1[63:0];

// ============= PALLETES ================
// 0-3 is pallete 0 
// 4-7 is pallete 1
// 8-B is pallete 2
// C-F is pallete 3

logic [5:0]BKG_PALLETES[15:0]; 
logic [5:0]SPR_PALLETES[15:0];

// We dont have time to test all programming we are only gonna use preloaded data for this test.
initial begin 
	$readmemh("CHR_ROM0.dat", CHR_ROM_0);
	$readmemh("CHR_ROM1.dat", CHR_ROM_1);
	// Auto generated test colours palletes
	BKG_PALLETES[0] = 'h0F; // black
	BKG_PALLETES[1] = 'h30; // white
	BKG_PALLETES[2] = 'h36; // pink
	BKG_PALLETES[3] = 'h06; // brown
	
	BKG_PALLETES[4] = 'h0F; // black
	BKG_PALLETES[5] = 'h30; // white
	BKG_PALLETES[6] = 'h2c; // turquoise?
	BKG_PALLETES[7] = 'h24; // pinkier pink
	
	BKG_PALLETES[8] = 'h0F; // black
	BKG_PALLETES[9] = 'h16; // light brown
	BKG_PALLETES[10] = 'h30; // white
	BKG_PALLETES[11] = 'h37; // white people
	
	BKG_PALLETES[12] = 'h0F; // black
	BKG_PALLETES[13] = 'h06; // brown
	BKG_PALLETES[14] = 'h27; // orange
	BKG_PALLETES[15] = 'h02; // blue
	
	SPR_PALLETES[0] = 'h0F; // black
	SPR_PALLETES[1] = 'h00; // grey
	SPR_PALLETES[2] = 'h01; // blue
	SPR_PALLETES[3] = 'h05; // red
	
	SPR_PALLETES[4] = 'h0F; // black
	SPR_PALLETES[5] = 'h28; // yellow
	SPR_PALLETES[6] = 'h2A; // green
	SPR_PALLETES[7] = 'h16; // red
	
	SPR_PALLETES[8] = 'h0F; // black
	SPR_PALLETES[9] = 'h2C; // teal
	SPR_PALLETES[10] = 'h12; // blue
	SPR_PALLETES[11] = 'h16; // red
	
	SPR_PALLETES[12] = 'h0F; // black
	SPR_PALLETES[13] = 'h27; // orange
	SPR_PALLETES[14] = 'h06; // red
	SPR_PALLETES[15] = 'h1A; // green


	$readmemh("oam_test.dat", OAM);
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
logic [11:0] chr_ptr_0;	// chr rom pointer
logic [11:0] chr_ptr_1;	// chr rom pointer
logic [2:0] bkg_offset;



//===============================================
//============ COMBINATIONAL BLOCK===============
//===============================================


assign PPU_PTR_X = (pixel_x < 256) ? pixel_x : 255;
assign PPU_PTR_Y = (pixel_y < 240) ? pixel_y : 239;
assign VGA_STREAM_DATA = spr_cdat;


always_comb begin 
// ----------- PIXELS COUNT INCREMENT -----------
	if (pixel_x == X_PIXELS-1) begin
		pixel_y_next = (pixel_y == Y_PIXELS-1) ? 0 : pixel_y + 1;
		pixel_x_next = 0;
	end
	else begin
			pixel_x_next = pixel_x + 1;
			pixel_y_next = pixel_y;
	end
// ----------- background draw state control ----
	bkg_draw_state = (pixel_y < Y_BPORCH)
		? (pixel_x[2:0] == 3'b0) ? 
		FETCHING : PIPING  
	: HALT;

// ------------ spr_draw_mux --------- 
// Multi plexer for drawing the combined output of the sprites
	spr_cdat = 'h0f;
	for ( i = 0; i < 8; i ++) begin
		if(spr_rend_valid[i]) begin
			spr_cdat = SPR_PALLETES[spr_rend_pallete_colour[i]];
		end
	end 	 
	tile_x = 0;
	tile_y = 0;
	tile_col = 0;
	tile_row = 0;
	nt_ptr = 0;
	attr_ptr = 0;
// ------------ Tile coordinates ----------------
	if (pixel_x < X_BPORCH && pixel_y < Y_BPORCH) begin
		tile_x = (pixel_x == 0) ? 0 : (pixel_x-1) >> 3; /////////////////////////////changed
		tile_y = pixel_y >> 3;
		tile_col = pixel_x % 8;
		tile_row = pixel_y % 8;
		nt_ptr = tile_x + tile_y * 6'd32;
		attr_ptr = (tile_x >> 2) + (tile_y >> 2) * 8;
	end
	
// ------------ Output Colour -------------------
	bkg_cdat = BKG_PALLETES[pallete_ptr];
	pallete_ptr[1:0] = {bg_slice[7-bkg_offset],bg_slice[15-bkg_offset]};
	
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
	pixel_x <= pixel_x_next;
	pixel_y <= pixel_y_next;
// NAMETABLE RENDER AND DRAW STATE 
	case(bkg_draw_state)
		FETCHING:begin
			bg_slice = bg_slice_next;
			bkg_offset = '0;
		end 
						
		PIPING: begin 
			bkg_offset = bkg_offset + 1'b1;
		end 
		HALT: begin 
			bkg_offset = '0;
		end 
	endcase 
// Sprite spr_scan  Evaluates sprites and loads them into the sprite renderer
	case(spr_scan_state)
		SPR_SCAN_SCAN: begin 
			spr_scan_rend_now <= 1;
			if(spr_scan_rend_iter == 0)
			// Scan for sprites that we can draw
			spr_rend_draw_flags = 0;
			spr_scan_ypos = OAM[spr_scan_iter << 2];
			
			if( (pixel_y < 8||(spr_scan_ypos > (pixel_y - 7))) && (spr_scan_ypos <= (pixel_y + 1)) && spr_scan_ypos < 'hEF) begin
				spr_scan_state <= SPR_REND_FETCH_ATTR;
			end else begin
				spr_scan_iter = (spr_scan_iter + 1);
			end
			
			if(spr_scan_iter == 63) begin 
				spr_scan_state <= SPR_SCAN_HALT;
			end
		end
		SPR_REND_FETCH_ATTR: begin // grab attributes
			spr_rend_buf[spr_scan_rend_iter][31:24] = OAM[(spr_scan_iter << 2) + OAM_SPR_ATTR];
			spr_tile_slice_ptr[12] = spr_base_rom;
			spr_vflip = spr_rend_buf[spr_scan_rend_iter][30];
			spr_scan_state <= SPR_REND_FETCH_TILE_LSB;
		end 
		SPR_REND_FETCH_TILE_LSB: begin // grab tile index and tile lsb
			spr_tile_index = OAM[(spr_scan_iter << 2) + OAM_SPR_INDX];
			spr_tile_slice = pixel_y + 1 - spr_scan_ypos;
			spr_tile_slice_ptr[15:13] = 0;
			spr_tile_slice_ptr[11:4] = spr_tile_index;
			spr_tile_slice_ptr[3] = 0;
			spr_tile_slice_ptr[2:0] = (spr_vflip) ? 7 - spr_tile_slice : spr_tile_slice ;
			spr_rend_buf[spr_scan_rend_iter][7:0] = CHR_ROM_0[spr_tile_slice_ptr];
			spr_scan_state <= SPR_REND_FETCH_DRAW_MSB;
		end 
		SPR_REND_FETCH_DRAW_MSB: begin // grab x position and lsb and consolidate and send to sprite renderer
			spr_rend_buf[spr_scan_rend_iter][23:16] = OAM[(spr_scan_iter << 2) + OAM_SPR_XPOS];
			spr_rend_buf[spr_scan_rend_iter][15:8] = CHR_ROM_0[spr_tile_slice_ptr+8];
			spr_rend_draw_flags[spr_scan_rend_iter] = 1;
			spr_scan_rend_iter = (spr_scan_rend_iter + 1 < 8) ? spr_scan_rend_iter + 1 : 8;
			spr_scan_iter = spr_scan_iter + 1;
			if(spr_scan_iter == 63) begin 
				spr_scan_state <= SPR_SCAN_HALT;
			end else begin 
				spr_scan_state <= SPR_SCAN_SCAN;
			end
		end 
		SPR_SCAN_HALT: begin
			spr_scan_iter = 0;
			spr_scan_rend_iter = 0;
			spr_scan_rend_now = 0;
			if(pixel_x_next == 0) spr_scan_state <= SPR_SCAN_SCAN;
		end 
	endcase 
end

// ================ SPRITE RENDER MODULES ==============

spr_rend spr_rend_0( PPU_SLOW_CLOCK, spr_rend_buf[0], pixel_x, spr_rend_draw_flags[0]&spr_scan_rend_now, spr_rend_draw_flags[0], spr_rend_pallete_colour[0], spr_rend_valid[0] );
spr_rend spr_rend_1( PPU_SLOW_CLOCK, spr_rend_buf[1], pixel_x, spr_rend_draw_flags[1]&spr_scan_rend_now, spr_rend_draw_flags[1], spr_rend_pallete_colour[1], spr_rend_valid[1] );
spr_rend spr_rend_2( PPU_SLOW_CLOCK, spr_rend_buf[2], pixel_x, spr_rend_draw_flags[2]&spr_scan_rend_now, spr_rend_draw_flags[2], spr_rend_pallete_colour[2], spr_rend_valid[2] );
spr_rend spr_rend_3( PPU_SLOW_CLOCK, spr_rend_buf[3], pixel_x, spr_rend_draw_flags[3]&spr_scan_rend_now, spr_rend_draw_flags[3], spr_rend_pallete_colour[3], spr_rend_valid[3] );
spr_rend spr_rend_4( PPU_SLOW_CLOCK, spr_rend_buf[4], pixel_x, spr_rend_draw_flags[4]&spr_scan_rend_now, spr_rend_draw_flags[4], spr_rend_pallete_colour[4], spr_rend_valid[4] );
spr_rend spr_rend_5( PPU_SLOW_CLOCK, spr_rend_buf[5], pixel_x, spr_rend_draw_flags[5]&spr_scan_rend_now, spr_rend_draw_flags[5], spr_rend_pallete_colour[5], spr_rend_valid[5] );
spr_rend spr_rend_6( PPU_SLOW_CLOCK, spr_rend_buf[6], pixel_x, spr_rend_draw_flags[6]&spr_scan_rend_now, spr_rend_draw_flags[6], spr_rend_pallete_colour[6], spr_rend_valid[6] );
spr_rend spr_rend_7( PPU_SLOW_CLOCK, spr_rend_buf[7], pixel_x, spr_rend_draw_flags[7]&spr_scan_rend_now, spr_rend_draw_flags[7], spr_rend_pallete_colour[7], spr_rend_valid[7] );
/*
always_ff@(posedge PPU_SLOW_CLOCK) begin

	case(bkg_draw_state2)
		BUFF_SLICE_1: begin
		///////////////////////////////////// change when chr rom chopped in two
			chr_ptr_0 = {NAME_TABLE_0[nt_ptr_next],1'b0,tile_row};
			bg_slice_next[15:8] = CHR_ROM_1[chr_ptr_0];
			bkg_draw_state2 <= BUFF_SLICE_2;
		end
		
		BUFF_SLICE_2: begin
			chr_ptr_1 = {NAME_TABLE_0[nt_ptr_next],1'b1,tile_row};
			bg_slice_next[7:0] = CHR_ROM_1[chr_ptr_1];
			bkg_draw_state2 <= IDLE;
		end
		
		IDLE: begin
			if(bkg_draw_state == FETCHING)
			bkg_draw_state2 <= BUFF_SLICE_1;
			
		end
	endcase
end*/
endmodule