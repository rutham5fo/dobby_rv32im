// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   fetch_top.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Mon Mar  7 14:02:55 2022 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps
module fetch_top #( parameter W = 32 ) (
						input	[W-1:0]	nextPC_fe,
						input	[W-1:0]	nextPC_ex,
						input			pc_sel,
						
						output	[W-1:0]	nextPC,
						output	[W-1:0]	PC
					);
	
	// DEC opcodes
	localparam	LUI			= 7'b0110111;
	localparam	AUIPC		= 7'b0010111;
	localparam	JAL			= 7'b1101111;
	localparam	JALR		= 7'b1100111;
	localparam	BRANCH		= 7'b1100011;
	localparam	MEM_LOAD	= 7'b0000011;
	localparam	MEM_STORE	= 7'b0100011;
	localparam	OP_IMM		= 7'b0010011;
	localparam	OP			= 7'b0110011;
	localparam	SYSTEM		= 7'b1110011;
		
	//SYSTEM codes
	localparam	CSRRW	= 3'b001;
	localparam	CSRRS	= 3'b010;
	localparam	CSRRC	= 3'b011;
	localparam	CSRRWI	= 3'b101;
	localparam	CSRRSI	= 3'b110;
	localparam	CSRRCI	= 3'b111;
	
	// FSM states
	localparam	INST			= 3'b000;			// Default state
	localparam	MULDIV			= 3'b001;
	localparam	RESULT			= 3'b010;
	localparam	TRAP_MSTATUS	= 3'b011;
	localparam	TRAP_MEPC_SET	= 3'b100;
	localparam	TRAP_MTVEC		= 3'b101;
	localparam	TRAP_MEPC_RET	= 3'b110;
	localparam	SLEEP			= 3'b111;
	
	// CSR addresses
	localparam	MSTATUS	= 12'h300;
	localparam	MISA	= 12'h301;
	localparam	MTVEC	= 12'h305;
	localparam	MEPC	= 12'h341;
	localparam	MCAUSE	= 12'h342;
	
	// Priviliged Instruction codes
	localparam	MRET	= 12'h302;
	localparam	WFI		= 12'h105;
	
	// Exception Codes
	localparam	ILLEGAL_INST	= 32'h00000002;
	localparam	EXT_INTERRUPT	= 32'h4000000b;
	localparam	SET_MIE				= 32'h00001808;
	localparam	CLR_MIE				= 32'h00001880;
	
	assign nextPC = PC + 4;
	
	// PC sel mux
	assign PC = (pc_sel) ? nextPC_ex : nextPC_fe;
	
endmodule
