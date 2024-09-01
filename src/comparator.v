`timescale 1ns/10ps

// Comparator rhs = rs2 | I-Imm dpepnding on operation
module comparator #(parameter W = 32)	(	input	[W-1:0]	lhs,	// rs1
											input	[W-1:0]	rhs,	// rs2
											input	[2:0]	funct3,
										
											output			br_en
										);
										
	// BRANCH codes
	localparam	BEQ		= 3'b000; 
	localparam	BNE		= 3'b001;
	localparam	BLT		= 3'b100;
	localparam	BGE		= 3'b101;
	localparam	BLTU	= 3'b110;
	localparam	BGEU	= 3'b111;
										
	reg			br_en;
	
	wire		eq;
	wire		lt;
	wire		ltu;
	wire		gte;
	wire		gteu;
	
	assign eq = (lhs == rhs) ? 1'b1 : 1'b0;
	assign lt = ($signed(lhs) < $signed(rhs)) ? 1'b1 : 1'b0;
	assign ltu = (lhs < rhs) ? 1'b1 : 1'b0;
	assign gte = ($signed(lhs) >= $signed(rhs)) ? 1'b1 : 1'b0;
	assign gteu = (lhs >= rhs) ? 1'b1 : 1'b0;
	
	always @* begin
		case (funct3)
			BEQ		: br_en = eq;
			BNE		: br_en = ~eq;
			BLT		: br_en = lt;
			BGE		: br_en = gte;
			BLTU	: br_en = ltu;
			BGEU	: br_en = gteu;
			default	: br_en = 1'b0;
		endcase
	end

endmodule
