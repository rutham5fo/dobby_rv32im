`timescale 1ns/10ps
module pads_east (
		input					I_CLK,
		input					I_A_RESET_L,
		input					I_BUS_RDY,
		input	[1:0]			I_INTR_H,
		input					core_sleep_o,
		input					bus_en_o,
		input					bus_we_o,
		input	[1:0]			bus_size_o,
		input	[1:0]			intr_ack_o,
		input					oe18_tie,
		
		output					O_CORE_SLEEP,
		output					O_BUS_EN,
		output					O_BUS_WE,
		output	[1:0]			O_BUS_SIZE,
		output	[1:0]			O_INTR_ACK,
		output					clk_i,
		output					a_reset_l_i,
		output					bus_rdy_i,
		output	[1:0]			intr_h_i
	);
	
	//wire			OE18;
	
	genvar i;

	HIO18_GF28SLP_IOPAD clk_pad_i (
		.PAD(I_CLK),
		.DATA_IN(clk_i),
		.DATA_OUT(),
		.IE(1'b1),
		.OE(1'b0),
		.OE18(oe18_tie)
	);
	
	HIO18_GF28SLP_IOPAD a_reset_l_pad_i (
		.PAD(I_A_RESET_L),
		.DATA_IN(a_reset_l_i),
		.DATA_OUT(),
		.IE(1'b1),
		.OE(1'b0),
		.OE18(oe18_tie)
	);
	
	HIO18_GF28SLP_IOPAD bus_rdy_pad_i (
		.PAD(I_BUS_RDY),
		.DATA_IN(bus_rdy_i),
		.DATA_OUT(),
		.IE(1'b1),
		.OE(1'b0),
		.OE18(oe18_tie)
	);
	
	generate
		for (i = 0; i < 2; i = i+1) begin	: intr_h_pad
			HIO18_GF28SLP_IOPAD intr_h_pad_i (
			.PAD(I_INTR_H[i]),
			.DATA_IN(intr_h_i[i]),
			.DATA_OUT(),
			.IE(1'b1),
			.OE(1'b0),
			.OE18(oe18_tie)
			);
		end
	endgenerate
	
	HIO18_GF28SLP_IOPAD core_sleep_pad_i (
		.PAD(O_CORE_SLEEP),
		.DATA_IN(),
		.DATA_OUT(core_sleep_o),
		.IE(1'b0),
		.OE(1'b1),
		.OE18(oe18_tie)
	);
	
	HIO18_GF28SLP_IOPAD bus_en_pad_i (
		.PAD(O_BUS_EN),
		.DATA_IN(),
		.DATA_OUT(bus_en_o),
		.IE(1'b0),
		.OE(1'b1),
		.OE18(oe18_tie)
	);
	
	HIO18_GF28SLP_IOPAD bus_we_pad_i (
		.PAD(O_BUS_WE),
		.DATA_IN(),
		.DATA_OUT(bus_we_o),
		.IE(1'b0),
		.OE(1'b1),
		.OE18(oe18_tie)
	);
	
	generate
		for (i = 0; i < 2; i = i+1) begin	: bus_size_pad
			HIO18_GF28SLP_IOPAD bus_size_pad_i (
				.PAD(O_BUS_SIZE[i]),
				.DATA_IN(),
				.DATA_OUT(bus_size_o[i]),
				.IE(1'b0),
				.OE(1'b1),
				.OE18(oe18_tie)
			);
		end
	endgenerate
	
	generate
		for (i = 0; i < 2; i = i+1) begin	: intr_ack_pad
			HIO18_GF28SLP_IOPAD intr_ack_pad_i (
				.PAD(O_INTR_ACK[i]),
				.DATA_IN(),
				.DATA_OUT(intr_ack_o[i]),
				.IE(1'b0),
				.OE(1'b1),
				.OE18(oe18_tie)
			);
		end
	endgenerate
	
	//HIO18_GF28SLP_OETIE i_HIO18_GF28SLP_OETIE( .OE18(OE18) );
	
endmodule
