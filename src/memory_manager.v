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

module memory_manager #(parameter MAX_INIT_ADDR = 32'h3fff, parameter ADDR_WIDTH = 32,
			 parameter DATA_WIDTH = 32, parameter EXT_ADDR_WIDTH = 16,
             parameter MEM_FILE_1 = "none", parameter MEM_FILE_2 = "none",
             parameter MEM_FILE_3 = "none", parameter MEM_FILE_4 = "none")
    (
        input                           	clk,
        input                           	reset_n,
		input								ext_stall,
        input   [1:0]                   	data_op_type,
        input   [2:0]                   	data_byte_sel,
        input   [ADDR_WIDTH-1:0]        	inst_addr_core,
        input   [ADDR_WIDTH-1:0]        	data_addr_core,
        input   [DATA_WIDTH-1:0]        	data_from_core,
        input   [DATA_WIDTH-1:0]       		ext_val_in,
        input                           	transfer_ok,
		input								intr0_ext,
        
		output								intr0_ack,
        output		[DATA_WIDTH-1:0]    	inst_out,
        output		[DATA_WIDTH-1:0]    	data_to_core,
        output  reg [DATA_WIDTH-1:0]    	ext_val_out,
        output  reg [EXT_ADDR_WIDTH-1:0]  	ext_addr_out,
        output  reg [1:0]               	ext_size,
        output  reg                     	ext_we,
        output  reg                    		ext_active,
        output  reg                     	core_stall
    );
    
	reg     [1:0]                   ext_size_val;
    reg     [EXT_ADDR_WIDTH-1:0]    ext_addr_bm;
	
	wire							mem_en;
    wire                            mem_we;
	wire							mem_re;
	wire							mem_stall;
	wire							mem_ext;
	wire	[2:0]					mem_byte_sel;
	wire	[DATA_WIDTH-1:0]		mem_write;
	wire	[ADDR_WIDTH-1:0]		mem_addr;
    wire	[DATA_WIDTH-1:0]		data_out;
	wire							data_out_en;
	
	wire                            data_ext;
	wire							stall_drv;
	wire							ext_active_drv;
    
    assign data_ext = data_addr_core[16] || data_addr_core[15] || data_addr_core[14];
	assign stall_drv = mem_stall;
	assign ext_active_drv = mem_ext;
	assign data_to_core = (data_ext) ? ext_val_in : data_out;
	
	mem_sram mem_i (
		.clk(clk),
		.reset_n(reset_n),
		.mem_en(mem_en),
		.mem_re(mem_re),
		.mem_we(mem_we),
		.mem_byte_sel(mem_byte_sel),
		.mem_addr(mem_addr),
		.mem_write(mem_write),
		.data_out_en(data_out_en),
		
		.inst_out(inst_out),
		.data_out(data_out)
	);
    
	mem_ctrl #(.MAX_INIT_ADDR(MAX_INIT_ADDR)) mem_fsm_i(
		.clk(clk),
		.reset_n(reset_n),
		.ext_stall(ext_stall),
		.transfer_ok(transfer_ok),
		.inst_addr_core(inst_addr_core),
		.data_addr_core(data_addr_core),
		.data_from_core(data_from_core),
		.ext_val_in(ext_val_in),
		.data_ext(data_ext),
		.data_op_type(data_op_type),
		.data_byte_sel(data_byte_sel),
		.intr0_ext(intr0_ext),
		
		.intr0_ack(intr0_ack),
		.mem_ext_drv(mem_ext),
		.mem_stall(mem_stall),
		.mem_we(mem_we),
		.mem_re(mem_re),
		.mem_en(mem_en),
		.mem_write(mem_write),
		.mem_addr(mem_addr),
		.mem_byte_sel(mem_byte_sel),
		.data_out_en(data_out_en)
	);
	
    always @(posedge clk) begin
        ext_active <= ext_active_drv;
		core_stall <= stall_drv;
    end
	
    always @(posedge clk, negedge reset_n) begin
        if (!reset_n) begin
            ext_val_out <= 0;
            ext_addr_out <= 0;
            ext_we <= 0;
            ext_size <= 0;
        end
        else if (ext_active_drv) begin
            ext_val_out <= data_from_core;
            ext_addr_out <= mem_addr & ext_addr_bm;
            ext_we <= data_op_type[0];
            ext_size <= ext_size_val;
        end
    end
    
	always @* begin
    	case ({data_ext, data_byte_sel})
        	4'b1001, 4'b1101: begin
            	ext_size_val = 2'b01;
                ext_addr_bm = 16'hfffe;
            end
            4'b1010: begin
                ext_size_val = 2'b10;
                ext_addr_bm = 16'hfffc;
            end
			4'b1000, 4'b1011, 4'b1100, 4'b1110, 4'b1111: begin
				ext_size_val = 2'b00;
                ext_addr_bm = 16'hffff;
			end
            default: begin
            	ext_size_val = 2'b10;
        		ext_addr_bm = 16'hfffc;
            end
        endcase
    end
    
endmodule
