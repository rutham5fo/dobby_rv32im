// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   regfile.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Sat Mar  5 18:08:53 2022 
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps
/*
module regfile #(parameter W = 32, parameter R = 5, NUM_REGS = 32)
			(
				input			clk,
				input			a_reset_n,
				input	[W-1:0]	result,
				input	[R-1:0]	rd,
				input			useRd_slv,
				input	[R-1:0]	addr1,
				input	[R-1:0]	addr2,
				
				output	[W-1:0]	rs1,
				output	[W-1:0]	rs2
			);
	
	integer				i;
	
	reg		[W-1:0]		regs	[0:NUM_REGS-1];
	
	assign rs1 = regs[addr1];
	assign rs2 = regs[addr2];
	
	always @(negedge clk, negedge a_reset_n) begin
		if (!a_reset_n) begin
			for (i = 0; i < NUM_REGS; i = i+1) regs[i] <= 0;
		end
		else if (useRd_slv) regs[rd] <= result;
	end
	
endmodule
*/
/*
// ----------------- BEGIN >> Master-Slave Latch Regfile with multiple Masters [No Datapath Gating] --------------------
module regfile #( parameter W = 32, parameter R = 5, parameter NUM_REGS = 32 )
			(	input			clk,
				input			a_reset_n,
				input	[W-1:0]	result,
				input	[R-1:0]	rd,
				//input			useRd_mst,
				input			useRd_slv,
				input	[R-1:0]	addr1,
				input	[R-1:0]	addr2,
				
				output	[W-1:0]	rs1,
				output	[W-1:0]	rs2
			);
	
	localparam SLV_BANKS		= 8;
	localparam MST_BANKS		= NUM_REGS/SLV_BANKS;
	
	wire						reset_cond;
	wire						reset_dly;
	wire	[MST_BANKS-1:0]		mst_clk_en;
	wire	[MST_BANKS-1:0]		mst_gclk;
	wire	[MST_BANKS-1:0]		mst_gen_o;
	wire	[NUM_REGS-1:0]		slv_clk_en;
	wire	[NUM_REGS-1:0]		slv_gclk;
	wire	[NUM_REGS-1:0]		slv_gen_o;									// Slave latch gate_en out
	wire	[MST_BANKS*W-1:0]	mst_out;
	wire	[NUM_REGS*W-1:0]	slv_out;
	
	// Async reset reaches the latch_in mux, earlier than slv_gclk 1 -> 0.
	// Hence the slave latches are transparent for a brief moment
	// during which the reset val is replaced with data val.
	// To avoid this, delay the a_reset_n signal by combinational circuit.
	assign reset_cond = |slv_gen_o & ~useRd_slv;
	assign reset_dly = (~a_reset_n || reset_cond) ? 1'b0 : 1'b1;
	
	//assign mst_clk_en = useRd_slv & ~|slv_gen_o;
	//assign mst_gclk = mst_clk_en & clk;
	assign slv_clk_en = (useRd_slv) ? 32'h1 << rd : 1'b0;
	assign slv_gclk = slv_clk_en & { NUM_REGS{~clk} };
	
	assign rs1 = slv_out[W*addr1 +: W];
	assign rs2 = slv_out[W*addr2 +: W];
	
	genvar i;
	
	generate
		for (i = 0; i < MST_BANKS; i = i+1) begin
			assign mst_clk_en[i] = useRd_slv & ~|slv_gen_o[i*SLV_BANKS +: SLV_BANKS];
			assign mst_gclk[i] = mst_clk_en[i] & clk;
		end
	endgenerate
	
	generate
		for (i = 0; i < NUM_REGS; i = i+1) begin	: regfile_slave_latch
			latch #( .W(W), .V(0) ) slave_reg_i (
										.en(slv_gclk[i]),
										.a_reset_n(a_reset_n),
										.reset_dly(reset_dly),
										.data(mst_out[(i/SLV_BANKS)*W +: W]),
									
										.G_EN(slv_gen_o[i]),
										.Q(slv_out[W*i +: W])
									);
		end
	endgenerate
	
	generate
		for (i = 0; i < MST_BANKS; i = i+1) begin	: regfile_master_latch
			latch #( .W(W), .V(0) ) master_reg_i (
				.en(mst_gclk[i]),
				.a_reset_n(a_reset_n),
				.reset_dly(reset_dly),
				.data(result),
				
				.G_EN(mst_gen_o[i]),
				.Q(mst_out[i*W +: W])
			);
		end
	endgenerate
	
endmodule
*/

// ---------------- BEGIN >> Master-Slave Latch Regfile with single Master [No Datapath Gating] ----------------
module regfile #( parameter W = 32, parameter R = 5, parameter NUM_REGS = 32 )
			(	input			clk,
				input			a_reset_n,
				input	[W-1:0]	result,
				input	[R-1:0]	rd,
				//input			useRd_mst,
				input			useRd_slv,
				input	[R-1:0]	addr1,
				input	[R-1:0]	addr2,
				
				output	[W-1:0]	rs1,
				output	[W-1:0]	rs2
			);
	wire						reset_cond;
	wire						reset_dly;
	wire						mst_gclk;
	wire						mst_clk_en;
	wire	[NUM_REGS-1:0]		slv_clk_en;
	wire	[NUM_REGS-1:0]		slv_gclk;
	wire	[NUM_REGS*W-1:0]	slv_out;
	wire	[W-1:0]				mst_out;
	wire	[W-1:0]				latch_data;
	
	// Async reset reaches the latch_in mux, earlier than slv_gclk 1 -> 0.
	// Hence the slave latches are transparent for a brief moment
	// during which the reset val is replaced with data val.
	// To avoid this, delay the a_reset_n signal by combinational circuit.
	assign reset_cond = |slv_gclk & ~useRd_slv;
	assign reset_dly = (~a_reset_n || reset_cond) ? 1'b0 : 1'b1;
	
	assign slv_clk_en = (32'h1 << rd) & { NUM_REGS{useRd_slv} };
	assign slv_gclk = (slv_clk_en & { NUM_REGS{~clk} }) | { NUM_REGS{~a_reset_n} };
	assign mst_gclk = mst_clk_en & useRd_slv | ~a_reset_n;
	
	assign latch_data = (!reset_dly) ? 1'b0 : result;
	
	assign rs1 = slv_out[W*addr1 +: W];
	assign rs2 = slv_out[W*addr2 +: W];
	
	genvar i;
	
	generate
		for (i = 0; i < NUM_REGS; i = i+1) begin	: regfile_slave_latch
			latch #( .W(W) ) slave_reg_i (
										.en(slv_gclk[i]),
										.data(mst_out),
										
										.Q(slv_out[W*i +: W])
									);
		end
	endgenerate
	
	clk_ctrl #( .NUM_REGS(NUM_REGS) ) mst_clk_ctrl (
		.in_gclk(slv_gclk),
		.out_clk_ctrl(mst_clk_en)
	);
	
	latch #( .W(W) ) master_reg_i (
			.en(mst_gclk),
			.data(latch_data),
			
			.Q(mst_out)
	);
	
endmodule

/*
// ------------- BEGIN >> Sequential Datapath Reads (rs1 and rs2) using latch --------------
module regfile #( parameter W = 32, parameter R = 5, parameter NUM_REGS = 32 )
			(	input			clk,
				input			a_reset_n,
				input	[W-1:0]	result,
				input	[R-1:0]	rd,
				//input			useRd_mst,
				input			useRd_slv,
				input	[R-1:0]	addr1,
				input	[R-1:0]	addr2,
				//input			readRs1,
				//input			readRs2,
				
				output	[W-1:0]	rs1,
				output	[W-1:0]	rs2
			);
	
	//reg		[R-1:0]				rs1_addr;
	//reg		[R-1:0]				rs2_addr;
	reg		[W-1:0]				rs2_drv;
	
	wire						reset_cond;
	wire						reset_dly;
	wire						mst_clk_en;
	wire						mst_gclk;
	wire						mst_gen_o;
	wire	[NUM_REGS-1:0]		slv_clk_en;
	wire	[NUM_REGS-1:0]		slv_gclk;
	wire	[NUM_REGS-1:0]		slv_gen_o;									// Slave latch gate_en out
	wire	[W-1:0]				mst_out;
	//wire	[W-1:0]				slv_out [0:NUM_REGS-1];						// note index of unpacked dimension is reversed : slv_out[0] = {slv_out[1023], [1022], ...., [992]}
	wire	[NUM_REGS*W-1:0]	slv_out;
	//wire	[R-1:0]				rs1_gaddr;
	//wire	[R-1:0]				rs2_gaddr;
	wire	[R-1:0]				rs_addr;
	wire	[W-1:0]				rs_out;
	
	// Async reset reaches the latch_in mux, earlier than slv_gclk 1 -> 0.
	// Hence the slave latches are transparent for a brief moment
	// during which the reset val is replaced with data val.
	// To avoid this, delay the a_reset_n signal by combinational circuit.
	assign reset_cond = |slv_gen_o & ~useRd_slv;
	assign reset_dly = (~a_reset_n || reset_cond) ? 1'b0 : 1'b1;
	
	assign mst_clk_en = useRd_slv & ~|slv_gen_o;
	assign mst_gclk = mst_clk_en & clk;
	assign slv_clk_en = (useRd_slv) ? 32'h1 << rd : 1'b0;
	assign slv_gclk = slv_clk_en & { NUM_REGS{~clk} };
	
	// Perform datapath gating on addr1 and 2 using useRs1,2
	//assign rs1_gaddr = addr1 & { R{readRs1} };
	//assign rs2_gaddr = addr2 & { R{readRs2} };
	//assign rs1 = slv_out[W*rs1_addr +: W];
	//assign rs2 = slv_out[W*rs2_addr +: W];
	assign rs_addr = (clk) ? addr2 : addr1;
	assign rs_out = slv_out[W*rs_addr +: W];
	assign rs1 = rs_out;
	assign rs2 = rs2_drv;
	
	genvar i;
	
	generate
		for (i = 0; i < NUM_REGS; i = i+1) begin	: regfile_slave_latch
			latch #( .W(W), .V(0) ) slave_reg_i (
										.en(slv_gclk[i]),
										.a_reset_n(a_reset_n),
										.reset_dly(reset_dly),
										.data(mst_out),
									
										.G_EN(slv_gen_o[i]),
										.Q(slv_out[W*i +: W])
									);
		end
	endgenerate
	
	latch #( .W(W), .V(0) ) master_reg_i (
		.en(mst_gclk),
		.a_reset_n(a_reset_n),
		.reset_dly(reset_dly),
		.data(result),
		
		.G_EN(mst_gen_o),
		.Q(mst_out)
	);
	
	always @(clk, rs_out) begin
		if (clk) rs2_drv <= rs_out;
	end
	
	
	//always @(clk, rs1_gaddr) begin
	//	if (!clk) rs1_addr <= rs1_gaddr;
	//end
	
	//always @(clk, rs2_gaddr) begin
	//	if (!clk) rs2_addr <= rs2_gaddr;
	//end
	
endmodule
*/
/*
// ---------------- BEGIN >> Slave Latch Regfile with No Master [No Datapath Gating] ----------------
module regfile #( parameter W = 32, parameter R = 5, parameter NUM_REGS = 32 )
			(	input			clk,
				input			a_reset_n,
				input	[W-1:0]	result,
				input	[R-1:0]	rd,
				//input			useRd_mst,
				input			useRd_slv,
				input	[R-1:0]	addr1,
				input	[R-1:0]	addr2,
				
				output	[W-1:0]	rs1,
				output	[W-1:0]	rs2
			);
	
	wire	[NUM_REGS-1:0]		slv_clk_en;
	wire	[NUM_REGS-1:0]		slv_gclk;
	wire	[NUM_REGS*W-1:0]	slv_out;
	wire	[W-1:0]				latch_data;
	
	assign slv_clk_en = 32'h1 << rd;
	assign slv_gclk = (slv_clk_en & { NUM_REGS{useRd_slv} } & { NUM_REGS{clk} }) | { NUM_REGS{~a_reset_n} };
	assign latch_data = (!a_reset_n) ? 1'b0 : result;
	
	assign rs1 = slv_out[W*addr1 +: W];
	assign rs2 = slv_out[W*addr2 +: W];
	
	genvar i;
	
	generate
		for (i = 0; i < NUM_REGS; i = i+1) begin	: regfile_slave_latch
			latch #( .W(W) ) slave_reg_i (
										.en(slv_gclk[i]),
										.data(latch_data),
										
										.Q(slv_out[W*i +: W])
									);
		end
	endgenerate
	
endmodule
*/
/*
// ---------------- BEGIN >> Slave Latch Regfile with Datapath Serialization [Test Dummy]----------------
module regfile #( parameter W = 32, parameter R = 5, parameter NUM_REGS = 32 )
			(	input			clk,
				input			a_reset_n,
				input	[W-1:0]	result,
				input	[R-1:0]	rd,
				//input			useRd_mst,
				input			useRd_slv,
				input	[R-1:0]	addr1,
				input	[R-1:0]	addr2,
				
				output	[W-1:0]	rs1,
				output	[W-1:0]	rs2
			);
	
	wire	[NUM_REGS-1:0]		slv_clk_en;
	wire	[NUM_REGS-1:0]		slv_gclk;
	wire	[NUM_REGS*W-1:0]	slv_out;
	wire	[W-1:0]				latch_data;
	wire	[W-1:0]				rs2_drv;
	wire	[W-1:0]				rs_out;
	wire	[R-1:0]				rs_addr;
	
	assign slv_clk_en = 32'h1 << rd;
	assign slv_gclk = (slv_clk_en & { NUM_REGS{useRd_slv} } & { NUM_REGS{clk} }) | { NUM_REGS{~a_reset_n} };
	assign latch_data = (!a_reset_n) ? 1'b0 : result;
	
	assign rs_addr = (clk) ? addr2 : addr1;
	assign rs_out = slv_out[W*rs_addr +: W];
	assign rs1 = rs_out;
	assign rs2 = rs2_drv;
	
	genvar i;
	
	generate
		for (i = 0; i < NUM_REGS; i = i+1) begin	: regfile_slave_latch
			latch #( .W(W) ) slave_reg_i (
										.en(slv_gclk[i]),
										.data(latch_data),
										
										.Q(slv_out[W*i +: W])
									);
		end
	endgenerate
	
	latch #( .W(W) ) serial_reg_i (
							.en(clk),
							.data(rs_out),
							
							.Q(rs2_drv)
						);
	
endmodule
*/
