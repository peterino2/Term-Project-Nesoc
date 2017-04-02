	nes_nios u0 (
		.clk_50_clk            (<connected-to-clk_50_clk>),            //         clk_50.clk
		.led_export            (<connected-to-led_export>),            //            led.export
		.nes_cpu_clk           (<connected-to-nes_cpu_clk>),           //        nes_cpu.clk
		.ppu_clk               (<connected-to-ppu_clk>),               //            ppu.clk
		.ppu_slow_clk          (<connected-to-ppu_slow_clk>),          //       ppu_slow.clk
		.sdram_addr            (<connected-to-sdram_addr>),            //          sdram.addr
		.sdram_ba              (<connected-to-sdram_ba>),              //               .ba
		.sdram_cas_n           (<connected-to-sdram_cas_n>),           //               .cas_n
		.sdram_cke             (<connected-to-sdram_cke>),             //               .cke
		.sdram_cs_n            (<connected-to-sdram_cs_n>),            //               .cs_n
		.sdram_dq              (<connected-to-sdram_dq>),              //               .dq
		.sdram_dqm             (<connected-to-sdram_dqm>),             //               .dqm
		.sdram_ras_n           (<connected-to-sdram_ras_n>),           //               .ras_n
		.sdram_we_n            (<connected-to-sdram_we_n>),            //               .we_n
		.shift_clk             (<connected-to-shift_clk>),             //          shift.clk
		.vga_clk               (<connected-to-vga_clk>),               //            vga.clk
		.vga_stream_out_export (<connected-to-vga_stream_out_export>), // vga_stream_out.export
		.ppu_stream_in_export  (<connected-to-ppu_stream_in_export>)   //  ppu_stream_in.export
	);

