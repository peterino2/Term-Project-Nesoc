// Sprite render buffer
/*
	decodes the input and outputs a proper 4 bit colour pixel based on the position of a single byte
module spr_rend( clk, [31:0]rend_buf, pixel_x, rend_now, draw_now,
	output logic [3:0] pallete_colour // 4 bit output to pallete
	output logic valid
);

*/

module spr_rend(
	input logic clk,
	input logic [31:0]rend_buf, 
	input logic [7:0]pixel_x, 
	input logic rend_now, 	// render the image by copying read buf 
	input logic draw, 		// connected to spr_rend_draw_flag
	output logic [3:0] pallete_colour, // 4 bit output to pallete
	output logic valid // output is only considered for drawing by the multiplexer if draw is valid
);

parameter XPOS_LSB = 16;
parameter XPOS_MSB = 23;
parameter BIT_HFLIP = 30;
parameter BIT_PRIORITY = 29;
parameter PS_LSB = 16;
parameter PS_MSB = 17;

integer i;// index for for reversing bits
logic [1:0] pallete = 0;
logic [1:0] bmp_output;
logic [15:0] bmp_data;
logic bkg_priority;
logic hflip;
logic [2:0] vslice =0; 
logic [7:0] xpos;
logic [1:0] bmp[7:0];

assign pallete_colour = {pallete, bmp_output};

always_ff@(posedge rend_now)begin
	pallete = {rend_buf[PS_MSB],rend_buf[PS_MSB]};
	if(hflip) begin 
		for (i  = 0 ; i < 8; i++ )begin 
			// LSB
			bmp_data[i] = rend_buf[7 - i];
			// MSB
			bmp_data[i+8] = rend_buf[15 - i];
		end 
	end else begin 
		bmp_data = rend_buf[15:0];
	end 	
	bkg_priority = rend_buf[BIT_PRIORITY];
	hflip = rend_buf[BIT_HFLIP];
	xpos = rend_buf[XPOS_MSB:XPOS_LSB];
end 

always_ff@(negedge clk)begin
	if((pixel_x >= xpos) && (pixel_x < xpos + 8) && draw) begin 
		valid = 1;
		vslice = pixel_x - xpos;
		bmp_output = {bmp_data[vslice+8], bmp_data[vslice]};
	end 
	else valid = 0;
	
end 

endmodule