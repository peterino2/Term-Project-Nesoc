// chr_rom.sv

module ppu_memory(
	input logic[13:0]ppu_ab,
	input logic ppu_clk,
	output logic [7:0]DO
);

logic [7:0] CHR_ROM ['h1FFF:0]; // CHR ROM location
logic [11:0] chr_rom_ptr;
assign chr_rom_ptr = {}

initial begin // We dont have time to test all programming we are only gonna use preloaded data for this test.
	$readmemh("CHR_ROM.dat", CHR_ROM);
end 


// -------------PPU Access and decode-------------
always_comb begin 
	// 8kBits =  xxxa aaaa aaaa aaaa 
	if(ppu_ab < 'h8000)	// no check for lower bound due to roll-over :3
		ppu_ptr = {ppu_ab[11:0]};
	else ppu_ptr = 0;
end

always_ff@(posedge ppu_clk) begin
	DO = CHR_ROM[ppu_ptr];
end

endmodule
