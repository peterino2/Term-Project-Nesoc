// module ppu vga_fb_stream 

// Frame buffer fifo stream, writes to frame buffer during Hblanking routine

module vga_fb_stream (input logic [5:0] ppu_DI,
	output logic [5:0] ppu_DO,
	input logic fast_clk,
	input logic hsync,
	input logic ppu_clk
);
	// Fifo state machine
	
endmodule