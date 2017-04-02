
	input logic [31:0] din,
	input logic clk_write,
	input logic read,
	input logic write,
	input logic clk_read,
	output logic [5:0]dout,
	input logic reset,
	output logic done
);

logic [5:0] vid_fifo[512:0]; // size be a bit overkill
logic ptr_read = 0;
logic ptr_write = 0;

assign done = (ptr_write == ptr_read);

always_ff@(posedge clk_write) begin 
	if(reset) begin 
		ptr_write = 0;
	end else begin 
		if(write)begin 
			vid_fifo[ptr_write] = {din[5:0]};
			ptr_write = ptr_write + 1;
		end
	end 
end 

always_ff@(posedge clk_read) begin 
	if(reset) begin 
		ptr_read = 0;
	end else begin 
		if(read)begin
			dout = vid_fifo[ptr_read];
			if(!done)
				ptr_read = ptr_read + 1;
		end
	end 
end 

endmodule


module vga_stream(
	input logic cpu_clk,		   // .clk 
	input logic reset,		   // .reset 
	input logic [5:0]c_code_cpu,    // .data_stream_in
	output vsync,				//
	output hsync,				// 
	output vga_read				// On reading = high, req next pixel 
); // VGA avalon interface,


logic [5:0]scanline[255:0];
logic [8:0]coloursDecode[63:0];
logic [8:0]rgb_buf;

logic [7:0]pix_ptr_x;
logic [7:0]pix_ptr_y;

always_ff@(posedge(vga_clk)) begin
	if(vga_read)
		scanline[pix_ptr_x] = c_code_vga;
	rgb_buf = coloursDecode[scanline[pix_ptr_x]];
end

initial begin
	$readmemh("vga_colours_rgb.txt",coloursDecode);
end 

vga_out vga_0(
	.pix_clk(clk), .pix_ptr_x, .pix_ptr_y,.rgb(rgb_coe), .vsync, .hsync, .reading(vga_read), .rgb_buf
);


nes_video_dc_fifo dc_fifo(
	.din(), .clk_write(cpu_clk), 
	, .read(vga_read),
	, .write(cpu_write),
	, .clk_read(vga_clk),
	, .dout(),
	, .reset
);

endmodule 