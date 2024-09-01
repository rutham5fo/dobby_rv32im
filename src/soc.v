// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   soc.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Wed Feb 14 18:46:26 2024 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module soc #(parameter MAX_MEM_ADDR = 32'h3fff, parameter DATA_WIDTH = 32,
			 parameter EXT_ADDR_WIDTH = 16, parameter INT_ADDR_WIDTH = 32)
	(
	input							clk,
	input							reset_n,
	input							bus_rdy,
	input	[1:0]					intr_h,
	input	[DATA_WIDTH-1:0]		data_bus_recv,
	
	output							core_sleep,
	output	[1:0]		 			intr_ack,
	output							data_bus_o_en,
	output							data_bus_i_en,
	output							bus_en,
	output							bus_we,
	output	[1:0]					bus_size,
	output	[EXT_ADDR_WIDTH-1:0]	bus_addr,
	output	[DATA_WIDTH-1:0]		data_bus_drv
);
	
	//reg								reset_sync_0;
	//reg								reset_sync_1;
	wire							sync_reset;
	wire							intr0_ack_core;
	wire							intr0_ack_mem;
	wire							intr0_ack_out;
	
	wire							mmu_stall;
	wire							core_stall;
	wire	[1:0]					core_data_opType;
	wire	[2:0]					core_data_byteSel;
	wire	[DATA_WIDTH-1:0]		core_inst_in;
	wire	[DATA_WIDTH-1:0]		core_data_in;
	wire	[DATA_WIDTH-1:0]		core_data_out;
	wire	[INT_ADDR_WIDTH-1:0]	core_inst_addr;
	wire	[INT_ADDR_WIDTH-1:0]	core_data_addr;
	
	assign intr0_ack_out = intr0_ack_core || intr0_ack_mem;
	assign intr_ack[0] = intr0_ack_out;
	//assign sync_reset = reset_sync_1;
	assign sync_reset = reset_n;
	
	// Reset sync
	/*
	reset_synchronizer reset_sync_i (
		.clk(clk),
		.a_reset_n(reset_n),
		.reset_sync_o(sync_reset)
	);
	*/
	core_v6 core_v6_i (
		.clk(clk),
		.a_reset_n(sync_reset),
		.int0_ext(intr_h[0]),
		.int1_ext(intr_h[1]),
		.mem_stall(core_stall),
    	.inst_in(core_inst_in),
		.data_in(core_data_in),
		.inst_addr(core_inst_addr),
		.data_out(core_data_out),
		.data_addr(core_data_addr),
    	.opType(core_data_opType),
		.width(core_data_byteSel),
		.int0_ack(intr0_ack_core),
		.int1_ack(intr_ack[1]),
		.stall_mmu(mmu_stall),
		.sleep(core_sleep)
  	);
  
	init_mmu_extbus #(.MAX_ADDR_INIT(MAX_MEM_ADDR)) init_mmu_bus_i (
		.clk(clk),
		.reset_n(sync_reset),
		.stall_mmu(mmu_stall),
		.i_bus_rdy(bus_rdy),
		.i_intr_0(intr_h[0]),
		.core_data_addr_i(core_data_addr),
		.core_inst_addr_i(core_inst_addr),
		.core_data_out_i(core_data_out),
		.core_data_opType_i(core_data_opType),
		.core_data_byte_sel_i(core_data_byteSel),
		
		.b_bus_data_recv(data_bus_recv),
		.b_bus_data_drv(data_bus_drv),
		
		.o_intr_0(intr0_ack_mem),
		.core_stall_o(core_stall),
		.core_data_in_o(core_data_in),
		.core_inst_in_o(core_inst_in),
		.o_bus_en(bus_en),
		.o_bus_we(bus_we),
		.o_bus_size(bus_size),
		.o_bus_addr(bus_addr),
		.bus_data_o_en(data_bus_o_en),
		.bus_data_i_en(data_bus_i_en)
	);
	
endmodule
