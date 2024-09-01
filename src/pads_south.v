`timescale 1ns/10ps
module pads_south (
		input	[15:0]			bus_addr_o,
		input					oe18_tie,
		
		output	[15:0]			O_BUS_ADDR
	);
	
	//wire			OE18;

	genvar i;
	
	generate
		for (i = 0; i < 16; i = i+1) begin	: bus_addr_pad
			HIO18_GF28SLP_IOPAD bus_addr_pad_i (
				.PAD(O_BUS_ADDR[i]),
				.DATA_IN(),
				.DATA_OUT(bus_addr_o[i]),
				.IE(1'b0),
				.OE(1'b1),
				.OE18(oe18_tie)
			);
		end
	endgenerate
	
	//HIO18_GF28SLP_OETIE i_HIO18_GF28SLP_OETIE( .OE18(OE18) );
	
endmodule
