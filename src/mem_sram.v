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

module mem_sram #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 32) (
		input						clk,
		input						reset_n,
		input						mem_en,
		input						mem_we,
		input						mem_re,
		input						data_out_en,
		input   [2:0]               mem_byte_sel,
		input	[ADDR_WIDTH-1:0]	mem_addr,
		input	[DATA_WIDTH-1:0]	mem_write,
		
		output	[DATA_WIDTH-1:0]	inst_out,
		output	[DATA_WIDTH-1:0]	data_out
	);
	
	localparam BM_FULL              = 32'hffffffff;
    localparam BM_HALF_UP           = 32'hffff0000;
    localparam BM_HALF_DOWN         = 32'h0000ffff;
    localparam BM_BYTE_1            = 32'h000000ff;
    localparam BM_BYTE_2            = 32'h0000ff00;
    localparam BM_BYTE_3            = 32'h00ff0000;
    localparam BM_BYTE_4            = 32'hff000000;
	
	reg								mem_cs_1;
	reg								mem_cs_2;
	reg								mem_cs_3;
	reg								mem_cs_4;
	reg		[1:0]					data_addr;
	reg     [DATA_WIDTH-1:0]        mem_bm_sel;
	reg		[DATA_WIDTH-1:0]		inst_out_val;
	reg		[DATA_WIDTH-1:0]		data_out_val;
	wire	[DATA_WIDTH-1:0]		mem_out_1;
	wire	[DATA_WIDTH-1:0]		mem_out_2;
	wire	[DATA_WIDTH-1:0]		mem_out_3;
	wire	[DATA_WIDTH-1:0]		mem_out_4;
	//wire							data_out_gclk;
	
	assign inst_out = inst_out_val;
	assign data_out = data_out_val;
	
	//assign data_out_gclk = clk & data_out_en;
	
	HM_1P_GF28SLP_1024x32_1cr mem_1 (
        .CLK_I  (clk),
        .ADDR_I (mem_addr[11:2]),
        .DW_I   (mem_write),
        .BM_I   (mem_bm_sel),
        .WE_I   (mem_we),
        .RE_I   (mem_re),
        .CS_I   (mem_cs_1 & mem_en),
        .DR_O   (mem_out_1),
        .DLYL   (2'h0),
        .DLYH   (2'h0),
        .DLYCLK (2'h0)
    );
    
    HM_1P_GF28SLP_1024x32_1cr mem_2 (
        .CLK_I  (clk),
        .ADDR_I (mem_addr[11:2]),
        .DW_I   (mem_write),
        .BM_I   (mem_bm_sel),
        .WE_I   (mem_we),
        .RE_I   (mem_re),
        .CS_I   (mem_cs_2 & mem_en),
        .DR_O   (mem_out_2),
        .DLYL   (2'h0),
        .DLYH   (2'h0),
        .DLYCLK (2'h0)
    );
    
    HM_1P_GF28SLP_1024x32_1cr mem_3 (
        .CLK_I  (clk),
        .ADDR_I (mem_addr[11:2]),
        .DW_I   (mem_write),
        .BM_I   (mem_bm_sel),
        .WE_I   (mem_we),
        .RE_I   (mem_re),
        .CS_I   (mem_cs_3 & mem_en),
        .DR_O   (mem_out_3),
        .DLYL   (2'h0),
        .DLYH   (2'h0),
        .DLYCLK (2'h0)
    );
    
    HM_1P_GF28SLP_1024x32_1cr mem_4 (
        .CLK_I  (clk),
        .ADDR_I (mem_addr[11:2]),
        .DW_I   (mem_write),
        .BM_I   (mem_bm_sel),
        .WE_I   (mem_we),
        .RE_I   (mem_re),
        .CS_I   (mem_cs_4 & mem_en),
        .DR_O   (mem_out_4),
        .DLYL   (2'h0),
        .DLYH   (2'h0),
        .DLYCLK (2'h0)
    );
	/*
	always @(posedge data_out_gclk, negedge reset_n) begin
		if (!reset_n) data_addr <= 1'b0;
		else data_addr <= mem_addr[13:12];
	end
	*/
	always @(posedge clk, negedge reset_n) begin
		if (!reset_n) data_addr <= 1'b0;
		else if (data_out_en) data_addr <= mem_addr[13:12];
	end
	
	always @* begin
		case (mem_addr[13:12])
            2'b01: inst_out_val = mem_out_2;
            2'b10: inst_out_val = mem_out_3;
            2'b11: inst_out_val = mem_out_4;
            default: inst_out_val = mem_out_1;
        endcase
	end
	
	always @* begin
		case (data_addr)
            2'b01: data_out_val = mem_out_2;
            2'b10: data_out_val = mem_out_3;
            2'b11: data_out_val = mem_out_4;
            default: data_out_val = mem_out_1;
        endcase
	end
	
	always @* begin
        mem_cs_1 = 1'b0;
        mem_cs_2 = 1'b0;
        mem_cs_3 = 1'b0;
        mem_cs_4 = 1'b0;
        case (mem_addr[13:12])
            2'b01: mem_cs_2 = 1'b1;
            2'b10: mem_cs_3 = 1'b1;
            2'b11: mem_cs_4 = 1'b1;
            default: mem_cs_1 = 1'b1;
        endcase
    end
	
	always @* begin
        case (mem_byte_sel)
            3'b001: mem_bm_sel = BM_HALF_DOWN;
            3'b010: mem_bm_sel = BM_FULL;
            3'b100: mem_bm_sel = BM_BYTE_4;
            3'b101: mem_bm_sel = BM_HALF_UP;
            default: mem_bm_sel = BM_BYTE_1;
        endcase
    end
	
endmodule
