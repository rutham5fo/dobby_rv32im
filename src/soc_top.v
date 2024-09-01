// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   soc_top.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Sat Sep  2 14:34:51 2023 
// Last Change       :   $Date: 2023-09-14 02:57:46 +0200 (Thu, 14 Sep 2023) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps
module soc_top #(parameter MAX_MEM_ADDR = 32'h3fff, parameter DATA_WIDTH = 32,
				 parameter EXT_ADDR_WIDTH = 16, parameter INT_ADDR_WIDTH = 32)
	(
		input							I_CLK,
		input							I_A_RESET_L,
		input							I_BUS_RDY,
		input	[1:0]					I_INTR_H,
		
		inout	[DATA_WIDTH-1:0]		B_BUS_DATA,
		
		output							O_CORE_SLEEP,
		output							O_BUS_EN,
		output							O_BUS_WE,
		output	[1:0]					O_BUS_SIZE,
		output	[1:0]					O_INTR_ACK,
		output	[EXT_ADDR_WIDTH-1:0]	O_BUS_ADDR
    );
	
	wire							clk;
	wire							reset_n;
	wire							bus_rdy;
	wire	[1:0]					intr_h;
	wire	[31:0]					data_bus_drv;
	wire	[31:0]					data_bus_recv;
	wire							core_sleep;
	wire							bus_en;
	wire							bus_we;
	wire	[1:0]					bus_size;
	wire	[1:0]					intr_ack;
	wire	[15:0]					bus_addr;
	wire							data_bus_o_en;
	wire							data_bus_i_en;

	/* For Testing
	always @(posedge I_CLK, negedge I_A_RESET_L) begin
		if (!I_A_RESET_L) $display("%t: CORE | Reset", $time);
		else if (!O_CORE_SLEEP) $display("%t: CORE | stall = %d, inst_addr = %h, inst_in = %h, data_addr = %h, data_in = %d, data_out = %d, data_opType = %d",
				 $time, core_stall, core_inst_addr, core_inst_in, core_data_addr, core_data_in, core_data_out, core_data_opType);
	end
	*/
	
	//assign clk = I_CLK;
	//assign reset_n = I_A_RESET_L;
	//assign bus_rdy = I_BUS_RDY;
	//assign intr_h = I_INTR_H;
	//assign B_BUS_DATA = (data_bus_o_en) ? data_bus_drv : 32'hzzzzzzzz;
	//assign data_bus_recv = B_BUS_DATA;
	//assign O_CORE_SLEEP = core_sleep;
	//assign O_BUS_EN = bus_en;
	//assign O_BUS_WE = bus_we;
	//assign O_BUS_SIZE = bus_size;
	//assign O_INTR_ACK = intr_ack;
	//assign O_BUS_ADDR = bus_addr;
	
	soc soc_i (
		.clk(clk),
		.reset_n(reset_n),
		.bus_rdy(bus_rdy),
		.intr_h(intr_h),
		.data_bus_recv(data_bus_recv),
		
		.core_sleep(core_sleep),
		.intr_ack(intr_ack),
		.data_bus_o_en(data_bus_o_en),
		.data_bus_i_en(data_bus_i_en),
		.bus_en(bus_en),
		.bus_we(bus_we),
		.bus_size(bus_size),
		.bus_addr(bus_addr),
		.data_bus_drv(data_bus_drv)
	);
	
	pads pads_i (
		.I_CLK(I_CLK),
		.I_A_RESET_L(I_A_RESET_L),
		.I_BUS_RDY(I_BUS_RDY),
		.I_INTR_H(I_INTR_H),
		.core_sleep_o(core_sleep),
		.bus_en_o(bus_en),
		.bus_we_o(bus_we),
		.bus_size_o(bus_size),
		.intr_ack_o(intr_ack),
		.bus_addr_o(bus_addr),
		.bus_data_drv_b(data_bus_drv),
		.dbus_o_en_b(data_bus_o_en),
		.dbus_i_en_b(data_bus_i_en),
		
		.B_BUS_DATA(B_BUS_DATA),
		
		.O_CORE_SLEEP(O_CORE_SLEEP),
		.O_BUS_EN(O_BUS_EN),
		.O_BUS_WE(O_BUS_WE),
		.O_BUS_SIZE(O_BUS_SIZE),
		.O_INTR_ACK(O_INTR_ACK),
		.clk_i(clk),
		.a_reset_l_i(reset_n),
		.bus_rdy_i(bus_rdy),
		.intr_h_i(intr_h),
		.O_BUS_ADDR(O_BUS_ADDR),
		.bus_data_recv_b(data_bus_recv)
	);
 	
endmodule
