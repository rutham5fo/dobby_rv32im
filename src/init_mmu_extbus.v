// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   init_mmu_extbus.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Wed Sep 13 13:41:36 2023 
// Last Change       :   $Date: 2023-09-13 15:43:13 +0200 (Wed, 13 Sep 2023) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module init_mmu_extbus #(parameter MAX_ADDR_INIT = 32'h3fff, parameter DATA_WIDTH = 32,
						 parameter INT_ADDR_WIDTH = 32, parameter EXT_ADDR_WIDTH = 16)
	(
        input                       	clk,
        input                       	reset_n,
        input                       	i_bus_rdy,
        input   		               	i_intr_0,
		input							stall_mmu,
		input   [DATA_WIDTH-1:0]    	core_data_addr_i,
        input   [DATA_WIDTH-1:0]    	core_inst_addr_i,
        input   [DATA_WIDTH-1:0]    	core_data_out_i,
        input   [1:0]               	core_data_opType_i,
        input   [2:0]               	core_data_byte_sel_i,
        
        input   [DATA_WIDTH-1:0]    	b_bus_data_recv,
        output  [DATA_WIDTH-1:0]    	b_bus_data_drv,
		
		output							o_intr_0,
        output                      	core_stall_o,
		output  [DATA_WIDTH-1:0]        core_data_in_o,
        output  [DATA_WIDTH-1:0]        core_inst_in_o,
        output                      	o_bus_en,
        output                      	o_bus_we,
        output  [1:0]               	o_bus_size,
        output  [EXT_ADDR_WIDTH-1:0]    o_bus_addr,
		
		output							bus_data_o_en,
		output							bus_data_i_en
    );
    
    localparam MEM_1       = "none";
    localparam MEM_2       = "none";
    localparam MEM_3       = "none";
    localparam MEM_4       = "none";
    
    wire                        fwd_done;
    wire                        init_done;
    wire                        ext_bus_done;
    wire                        ext_bus_we;
    wire                        ext_bus_active;
    wire                        core_stall;
    wire    [1:0]               ext_bus_size;
    wire    [1:0]               data_op_type;
    wire    [2:0]               data_byte_sel;
    wire    [15:0]              ext_bus_addr;
    wire    [31:0]              inst_addr_ext;
    wire    [31:0]              inst_addr_core;
    wire    [31:0]              data_addr_core;
    wire    [31:0]              ext_bus_out;
    wire    [31:0]              instruction;
    wire    [31:0]              data_out;
    wire    [31:0]              data_in;
    wire    [31:0]              ext_bus_in;
    
    
    assign core_inst_in_o = instruction;
    assign inst_addr_core = core_inst_addr_i;
    assign data_addr_core = core_data_addr_i;
    assign data_op_type = core_data_opType_i;
    assign core_data_in_o = data_out;
    assign core_stall_o = core_stall;
    assign data_in = core_data_out_i;
    assign data_byte_sel = core_data_byte_sel_i;
	
    memory_manager #(.MAX_INIT_ADDR(MAX_ADDR_INIT), .MEM_FILE_1(MEM_1), .MEM_FILE_2(MEM_2), .MEM_FILE_3(MEM_3)
		) memory_manager_i (
        .clk(clk),
        .reset_n(reset_n),
		.ext_stall(stall_mmu),
        .data_op_type(data_op_type),
        .data_byte_sel(data_byte_sel),
        .inst_addr_core(inst_addr_core),
        .data_addr_core(data_addr_core),
        .data_from_core(data_in),
        .ext_val_in(ext_bus_out),
        .transfer_ok(ext_bus_done),
		.intr0_ext(i_intr_0),
        
		.intr0_ack(o_intr_0),
        .inst_out(instruction),
        .data_to_core(data_out),
        .ext_val_out(ext_bus_in),
        .ext_addr_out(ext_bus_addr),
        .ext_size(ext_bus_size),
        .ext_we(ext_bus_we),
        .ext_active(ext_bus_active),
        .core_stall(core_stall)
    );
    
    ext_bus_int bus_interface_i (
        .clk(clk),
        .reset_n(reset_n),
        .ext_active(ext_bus_active),
        .slv_rdy_i(i_bus_rdy),
        .mst_we_i(ext_bus_we),
        .mst_size_i(ext_bus_size),
        .mst_addr_i(ext_bus_addr),
        .mst_data_i(ext_bus_in),
        
        .bus_data_recv(b_bus_data_recv),
		.bus_data_drv(b_bus_data_drv),
        
        .mst_data_o(ext_bus_out),
        .bus_addr_o(o_bus_addr),
        .bus_size_o(o_bus_size),
        .bus_we_o(o_bus_we),
        .bus_en_o(o_bus_en),
        .transfer_ok(ext_bus_done),
		.bus_data_o_en(bus_data_o_en),
		.bus_data_i_en(bus_data_i_en)
    );
    
endmodule
