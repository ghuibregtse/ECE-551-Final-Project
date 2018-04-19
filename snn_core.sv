/* ECE 551 Spring 2018 Final Project
 *
 * File:	snn_core.sv
 * Authors:	Garret Huibregtse, Sean Cohen, Austin Wirtz
 *
 */

module snn_core(
	input clk,rst_n,
	input start, q_input, 
	output reg [9:0] addr_input_unit, // address of each bit
	output reg [3:0] digit, // output of the digit
	output done); // asseted when finished
	



wire q_input_extend;
// if q_input = 1 make it 127, else make it 0
assign q_input_extend = (q_input) ? {1'b0, {6{q_input}}, q_input} : {{7{q_input}}, q_input};

/******************************************************
* Mac module wires and logic
******************************************************/
logic clr_n; // clear the mac if low
wire [25:0] acc; // result of mac
wire [10:0] acc_rect; // rectified mac result
wire [7:0] a, b; // inputs to mac
wire of, uf; // detect overflow/underflow when rectifiying mac result

/******************************************************
* Module Instantiation: mac, rom, ram
******************************************************/
mac mac(a,b,clr_n,clk,rst_n,acc);
rom rom(addr_input_unit, clk, q);

typedef enum {IDLE,MAC} State;
State state,nxt_state;

/******************************************************
* MAC result caclulation and rectification
******************************************************/
// 2:1 muxes for mac inputs
assign a = (start) ? q_input_extend : ram_hidden_unit;
assign b = (start) ? rom_hidden_weight : rom_output_weight;

assign of = ((acc[25] == 0) && ^acc[24:17]);
assign uf = ((acc[25] == 1) && ~&acc[24:17]);
assign acc_rect = (of) ? 11'h3ff : ((uf) ? 11'h400 : acc[17:7]);

/******************************************************
* Increment the bit address each clock cycle
******************************************************/
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		addr_input_unit <= 10'h0;
	else
		addr_input_unit <= addr_input_unit + 1;
end

/******************************************************
* State Machine Transition/Combinational Logic for the snn_core design
******************************************************/
always_comb begin

	clr_n = 1;
	nxt_state = IDLE;
	case (state)
		IDLE : begin
			if(start) begin
				clr_n = 0;
				nxt_state = MAC;
			end else 
				clr_n = 0;
		end
		MAC : begin
			if(done)
				// add logic
				nxt_state = IDLE;
			else begin
				nxt_state = MAC;
			end
		end
		default : nxt_state = IDLE;
	endcase
end

/******************************************************
* State Machine Sequential Logic for the snn_core design
******************************************************/	
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) 
		state <= IDLE;
	else 
		state <= nxt_state;
end

endmodule

