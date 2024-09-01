`timescale 1ns/10ps

module imm_gen #( parameter W = 32 )(	input	[W-8:0]	inst,			// instruction[31:0] - opcode -> inst[31:7] = inst[24:0]
										input	[6:0]	opcode,
										
										output	[W-1:0]	imm_out
									);
									
	// DEC opcodes
	localparam	LUI		= 7'b0110111;
	localparam	AUIPC	= 7'b0010111;
	localparam	JAL		= 7'b1101111;
	localparam	JALR	= 7'b1100111;
	localparam	BRANCH	= 7'b1100011;
	localparam	LOAD	= 7'b0000011;
	localparam	STORE	= 7'b0100011;
	localparam	OP_IMM	= 7'b0010011;
	localparam	OP		= 7'b0110011;
	localparam	SYSTEM	= 7'b1110011;
	
	reg	[W-1:0]	imm_out;
	
	wire	[W-1:0]	u_imm;
	wire	[W-1:0]	j_imm;
	wire	[W-1:0]	b_imm;
	wire	[W-1:0]	s_imm;
	wire	[W-1:0]	i_imm;
	
	assign i_imm = { {21{inst[24]}}, inst[23:18], inst[17:14], inst[13] };							// {-- inst[31] --, inst[30:25], inst[24:21], inst[20]} = "I-Imm"
	assign s_imm = { {21{inst[24]}}, inst[23:18], inst[4:1], inst[0] };								// {-- inst[31] --, inst[30:25], inst[11:8], inst[7]} = "S-Imm"
	assign b_imm = { {20{inst[24]}}, inst[0], inst[23:18], inst[4:1], 1'b0 };						// {-- inst[31] --, inst[7], inst[30:25], inst[11:8], 0 } = "B-Imm"
	assign j_imm = { {12{inst[24]}}, inst[12:5], inst[13], inst[23:18], inst[17:14], 1'b0 };		// {-- inst[31] --, inst[19:12], inst[20], inst[30:25], inst[24:21], 0} = "J-Imm"
	assign u_imm = { inst[24], inst[23:13], inst[12:5], {12{1'b0}} };											// {-- 0 --, inst[19:15]} = uimm (csr immediate)
	
	always @* begin : Imm_gen_block
		case (opcode)
			LUI, AUIPC				: imm_out = u_imm;
			JAL						: imm_out = j_imm; 
			BRANCH   				: imm_out = b_imm;
			STORE    				: imm_out = s_imm;
			OP_IMM, JALR, LOAD		: imm_out = i_imm;
			default					: imm_out = 1'b0;
		endcase
	end
	
endmodule
