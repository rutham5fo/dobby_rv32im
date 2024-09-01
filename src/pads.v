// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   pads.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Thu Feb 15 00:25:20 2024 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps
module pads (
		input					I_CLK,
		input					I_A_RESET_L,
		input					I_BUS_RDY,
		input	[1:0]			I_INTR_H,
		input					core_sleep_o,
		input					bus_en_o,
		input					bus_we_o,
		input	[1:0]			bus_size_o,
		input	[1:0]			intr_ack_o,
		input	[15:0]			bus_addr_o,
		input	[31:0]			bus_data_drv_b,
		input					dbus_o_en_b,
		input					dbus_i_en_b,
		
		inout	[31:0]			B_BUS_DATA,
		
		output					O_CORE_SLEEP,
		output					O_BUS_EN,
		output					O_BUS_WE,
		output	[1:0]			O_BUS_SIZE,
		output	[1:0]			O_INTR_ACK,
		output					clk_i,
		output					a_reset_l_i,
		output					bus_rdy_i,
		output	[1:0]			intr_h_i,
		output	[15:0]			O_BUS_ADDR,
		output	[31:0]			bus_data_recv_b
	);
	
	wire			oe18_tie_n;
	wire			oe18_tie_e;
	wire			oe18_tie_s;
	wire			oe18_tie_w;
	
	pads_north pads_north_i (
		.bus_data_drv_b(bus_data_drv_b[15:0]),
		.dbus_o_en_b(dbus_o_en_b),
		.dbus_i_en_b(dbus_i_en_b),
		.oe18_tie(oe18_tie_n),
		
		.B_BUS_DATA(B_BUS_DATA[15:0]),
		
		.bus_data_recv_b(bus_data_recv_b[15:0])
	);
	
	pads_east pads_east_i (
		.I_CLK(I_CLK),
		.I_A_RESET_L(I_A_RESET_L),
		.I_BUS_RDY(I_BUS_RDY),
		.I_INTR_H(I_INTR_H),
		.core_sleep_o(core_sleep_o),
		.bus_en_o(bus_en_o),
		.bus_we_o(bus_we_o),
		.bus_size_o(bus_size_o),
		.intr_ack_o(intr_ack_o),
		.oe18_tie(oe18_tie_e),
		
		.O_CORE_SLEEP(O_CORE_SLEEP),
		.O_BUS_EN(O_BUS_EN),
		.O_BUS_WE(O_BUS_WE),
		.O_BUS_SIZE(O_BUS_SIZE),
		.O_INTR_ACK(O_INTR_ACK),
		.clk_i(clk_i),
		.a_reset_l_i(a_reset_l_i),
		.bus_rdy_i(bus_rdy_i),
		.intr_h_i(intr_h_i)
	);
	
	pads_south pads_south_i (
		.bus_addr_o(bus_addr_o),
		.oe18_tie(oe18_tie_s),
		
		.O_BUS_ADDR(O_BUS_ADDR)
	);
	
	pads_west pads_west_i (
		.bus_data_drv_b(bus_data_drv_b[31:16]),
		.dbus_o_en_b(dbus_o_en_b),
		.dbus_i_en_b(dbus_i_en_b),
		.oe18_tie(oe18_tie_w),
		
		.B_BUS_DATA(B_BUS_DATA[31:16]),
		
		.bus_data_recv_b(bus_data_recv_b[31:16])
	);
	
	HIO18_GF28SLP_OETIE i_HIO18_GF28SLP_OETIE_n( .OE18(oe18_tie_n) );
	HIO18_GF28SLP_OETIE i_HIO18_GF28SLP_OETIE_e( .OE18(oe18_tie_e) );
	HIO18_GF28SLP_OETIE i_HIO18_GF28SLP_OETIE_s( .OE18(oe18_tie_s) );
	HIO18_GF28SLP_OETIE i_HIO18_GF28SLP_OETIE_w( .OE18(oe18_tie_w) );
	
endmodule
