// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   imem_control.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Mon Sep 18 15:58:20 2023 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps
module mem_ctrl #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 32,
				   parameter EXTADDR_WIDTH = 16, parameter MAX_INIT_ADDR = 32'h3fff, parameter EXT_ADDR = 32'h00010000 )
	(
		input							clk,
		input							reset_n,
		input							ext_stall,
		input							transfer_ok,
		input   	[ADDR_WIDTH-1:0]   	inst_addr_core,
        input   	[ADDR_WIDTH-1:0]   	data_addr_core,
		input   	[DATA_WIDTH-1:0]    data_from_core,
        input   	[DATA_WIDTH-1:0]    ext_val_in,
		input							data_ext,
		input		[1:0]               data_op_type,
		input		[2:0]				data_byte_sel,
		input							intr0_ext,
		
		output							data_out_en,
		output	reg						intr0_ack,
		//output	reg						data_out_en,
		output	reg						mem_ext_drv,
		output	reg						mem_stall,
		output	reg						mem_we,
		output	reg						mem_re,
		output	reg						mem_en,
		output	reg	[2:0]				mem_byte_sel,
		output	reg	[ADDR_WIDTH-1:0]	mem_addr,
		output	reg	[DATA_WIDTH-1:0]	mem_write
		
	);
	
	localparam INIT_ADDR_MASK = EXT_ADDR | MAX_INIT_ADDR;
	
    localparam MEM_IDLE				= 3'b000;
	localparam MEM_EXT_WAIT			= 3'b001;
	localparam MEM_SYS_START		= 3'b010;
	localparam MEM_CPY				= 3'b011;
	localparam MEM_EXTEND			= 3'b100;
	localparam MEM_DONE				= 3'b101;
	localparam MEM_CPY_WAIT			= 3'b111;
	
	localparam BM_FULL_SEL	        = 3'b010;
	
	reg     [2:0]                   cur_state_mem;
    reg     [2:0]                   next_state_mem;
	reg								intr0_ack_drv;
	
	reg		[ADDR_WIDTH-1:0]		inst_addr_ext;
	
	reg								init_counter_en;
	reg								data_out_en_drv;
	reg								mem_write_sel;
	reg		[1:0]					mem_addr_sel;
	
	wire							init_done;
    
	assign init_done = (inst_addr_ext > INIT_ADDR_MASK) || intr0_ext;
	assign data_out_en = data_out_en_drv;
	
	always @(posedge clk, negedge reset_n) begin
        if (!reset_n) begin
            cur_state_mem <= MEM_SYS_START;
			intr0_ack <= 1'b0;
        end
        else begin
            cur_state_mem <= next_state_mem;
			intr0_ack <= intr0_ack_drv;
        end
    end
	
	always @(posedge clk, negedge reset_n) begin
        if (!reset_n) inst_addr_ext <= EXT_ADDR;
        else if (init_counter_en) inst_addr_ext <= inst_addr_ext + 4;
    end
	
	// PRAM FSM logic
    always @* begin
        next_state_mem = cur_state_mem;
		mem_en = ~ext_stall;
        mem_we = 1'b0;
		mem_re = 1'b1;
		mem_addr_sel = 2'b00;
		mem_write_sel = 1'b0;
        mem_stall = 1'b0;
		mem_ext_drv = 1'b0;
		mem_byte_sel = data_byte_sel;
		data_out_en_drv = 1'b0;
		init_counter_en = 1'b0;
		intr0_ack_drv = 1'b0;
		if (cur_state_mem == MEM_SYS_START) begin
			mem_addr_sel = 2'b01;
			mem_write_sel = 1'b1;
			next_state_mem = MEM_CPY;
			mem_stall = 1'b1;
		end
        else if (cur_state_mem == MEM_CPY) begin
            mem_stall = 1'b1;
			if (init_done) begin
				if (intr0_ext) intr0_ack_drv = 1'b1;
				next_state_mem = MEM_IDLE;
			end
			else begin
				mem_ext_drv = 1'b1;
				mem_addr_sel = 2'b01;
				mem_write_sel = 1'b1;
				next_state_mem = MEM_CPY_WAIT;
			end
        end
		else if (cur_state_mem == MEM_CPY_WAIT) begin
			mem_stall = 1'b1;
			mem_addr_sel = 2'b01;
			mem_write_sel = 1'b1;
			if (transfer_ok) begin
				mem_we = 1'b1;
				mem_re = 1'b0;
				mem_byte_sel = BM_FULL_SEL;
				init_counter_en = 1'b1;
				next_state_mem = MEM_CPY;
			end
		end
		else if (cur_state_mem == MEM_EXT_WAIT) begin
			mem_stall = 1'b1;
			mem_re = 1'b0;
			mem_addr_sel = 2'b10;
			if(transfer_ok) next_state_mem = MEM_EXTEND;
		end
		else if (cur_state_mem == MEM_IDLE) begin
			if (data_op_type != 2'b00) begin
				mem_addr_sel = 2'b10;
				mem_stall = 1'b1;
				if (!data_ext) begin
					next_state_mem = MEM_EXTEND;
                	if (data_op_type == 2'b01) begin
                    	mem_we = 1'b1;
						mem_re = 1'b0;
                    end
                	else begin
                    	data_out_en_drv = 1'b1;
                	end
            	end
            	else begin
					mem_re = 1'b0;
					mem_ext_drv = 1'b1;
					next_state_mem = MEM_EXT_WAIT;
            	end
			end
		end
		else if (cur_state_mem == MEM_EXTEND) begin
			mem_re = 1'b0;
			mem_addr_sel = 2'b10;
			next_state_mem = MEM_DONE;
		end
		else if (cur_state_mem == MEM_DONE) begin
			next_state_mem = MEM_IDLE;
		end
    end
	
	always @* begin
		case (mem_addr_sel)
			2'b01		: mem_addr = inst_addr_ext;
			2'b10		: mem_addr = data_addr_core;
			default		: mem_addr = inst_addr_core;
		endcase
	end
	
	always @* begin
		case (mem_write_sel)
			1'b1		: mem_write = ext_val_in;
			default		: mem_write = data_from_core;
		endcase
	end
	/*
	always @(clk, data_out_en_drv) begin
		if (!clk) data_out_en <= data_out_en_drv;
	end
	*/
endmodule
