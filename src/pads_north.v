`timescale 1ns/10ps
module pads_north (
		input	[15:0]			bus_data_drv_b,
		input					dbus_o_en_b,
		input					dbus_i_en_b,
		input					oe18_tie,
		
		inout	[15:0]			B_BUS_DATA,
		
		output	[15:0]			bus_data_recv_b
	);
	
	//wire			OE18;

	genvar i;
	
	generate
		for (i = 0; i < 16; i = i+1) begin	: bus_data_pad
			HIO18_GF28SLP_IOPAD bus_data_pad_i (
			.PAD(B_BUS_DATA[i]),
			.DATA_IN(bus_data_recv_b[i]),
			.DATA_OUT(bus_data_drv_b[i]),
			.IE(dbus_i_en_b),
			.OE(dbus_o_en_b),
			.OE18(oe18_tie)
			);
		end
	endgenerate
	
	//HIO18_GF28SLP_OETIE i_HIO18_GF28SLP_OETIE( .OE18(OE18) );
	
endmodule
