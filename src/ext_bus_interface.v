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

module ext_bus_int #(parameter ADDR_WIDTH = 16, parameter DATA_WIDTH = 32) (
        input                           clk,
        input                           reset_n,
        input                           ext_active,
        input                           slv_rdy_i,
        input                           mst_we_i,
        input   [1:0]                   mst_size_i,
        input   [ADDR_WIDTH-1:0]        mst_addr_i,
        input   [DATA_WIDTH-1:0]        mst_data_i,
        
        input   [DATA_WIDTH-1:0]        bus_data_recv,
		output  [DATA_WIDTH-1:0]        bus_data_drv,
        
        output  reg [DATA_WIDTH-1:0]    mst_data_o,
        output  reg [ADDR_WIDTH-1:0]    bus_addr_o,
        output  reg [1:0]               bus_size_o,
        output  reg                     bus_we_o,
        output  reg                     bus_en_o,
        output  reg                     transfer_ok,
		
		output	reg						bus_data_o_en,
		output	reg						bus_data_i_en
    );
    
    localparam BUS_IDLE     = 3'b000;
    localparam BUS_IO       = 3'b001;
    localparam BUS_WAIT     = 3'b010;
    localparam BUS_DONE     = 3'b011;
    localparam BUS_EXTEND   = 3'b100;
    
    reg                         assert_req;
    reg                         mst_en;
    reg                         mst_out_en;
	reg							transfer_ok_drv;
	reg							bus_o_en_drv;
	reg							bus_o_en_latch;
	reg							transfer_ok_latch;
	reg     [2:0]               cur_state;
    reg     [2:0]               next_state;
    wire    [DATA_WIDTH-1:0]    bus_io_recv;
    
    assign bus_data_drv = mst_data_i;
	assign bus_io_recv = bus_data_recv;
    
	always @(posedge clk, negedge reset_n) begin
        if (!reset_n) begin
            cur_state <= BUS_IDLE;
            bus_en_o <= 0;
            transfer_ok <= 0;
        end
        else begin
            cur_state <= next_state;
            bus_en_o <= mst_en;
			transfer_ok <= transfer_ok_latch;
        end
    end
	
	always @(posedge clk, negedge reset_n) begin
        if (!reset_n) begin
            bus_addr_o <= 0;
            bus_size_o <= 0;
            bus_we_o <= 0;	
        end
        else if (assert_req) begin
            bus_addr_o <= mst_addr_i;
            bus_size_o <= mst_size_i;
            bus_we_o <= mst_we_i;
		end
    end
	
	always @(posedge clk) begin
		bus_data_o_en <= bus_o_en_latch;
		bus_data_i_en <= ~bus_o_en_latch;
	end
    
    always @(posedge clk, negedge reset_n) begin
        if (!reset_n) mst_data_o <= 1'b0;
        else if (mst_out_en) mst_data_o <= bus_io_recv;
    end
    
    always @* begin
        next_state = cur_state;
        assert_req = 1'b0;
        mst_en = 1'b0;
        mst_out_en = 1'b0;
		transfer_ok_drv = 1'b0;
		bus_o_en_drv = 1'b0;
		// Request Phase
        if (cur_state == BUS_IDLE && ext_active) begin
            assert_req = 1'b1;
            mst_en = 1'b1;
            next_state = BUS_IO;
        end
        // Data Phase
        else if (cur_state == BUS_IO) begin
            if (slv_rdy_i) begin
                if (mst_we_i) begin
					bus_o_en_drv = 1'b1;
					//tri_state_dis = 1'b1;
					//bus_io_drive = mst_data_i;
					//data_bus_en = 1'b1;
				end
                next_state = BUS_WAIT;
            end
            else mst_en = 1'b1;
        end
        else if (cur_state == BUS_WAIT) begin
            if (slv_rdy_i) begin
                if (!mst_we_i) mst_out_en = 1'b1;
				transfer_ok_drv = 1'b1;
                next_state = BUS_DONE;
            end
            else if (!slv_rdy_i && mst_we_i) bus_o_en_drv = 1'b1; //bus_io_drive = mst_data_i;
        end
        else if (cur_state == BUS_EXTEND) begin
            // Do nothing and wait an extra cycle
            next_state = BUS_DONE;
        end
        else if (cur_state == BUS_DONE) begin
            // TODO: Empty state to fix timing, for now. Improve design later
            next_state = BUS_IDLE;
        end
    end
    
    // Clock gating meta latches
	always @(clk, bus_o_en_drv) begin
		if (!clk) bus_o_en_latch <= bus_o_en_drv;
	end
	
	always @(clk, transfer_ok_drv) begin
		if (!clk) transfer_ok_latch <= transfer_ok_drv;
	end
	
endmodule
