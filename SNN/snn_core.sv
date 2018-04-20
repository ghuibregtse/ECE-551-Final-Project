/* ECE 551 Spring 2018 Final Project
 *
 * File:	snn_core.sv
 * Authors:	Garret Huibregtse, Sean Cohen, Austin Wirtz
 *		Hello Sean
 */

module snn_core(
	input clk,rst_n,
	input start, q_input, 
	output reg [9:0] addr_input_unit, // address of each bit
	output reg [3:0] digit, // output of the digit
	output done); // asseted when finished
	logic sel; // select for the muxes into the mac
	wire q_input_extend;
	// if q_input = 1 make it 127, else make it 0
	assign q_input_extend = (q_input) ? {1'b0, {6{q_input}}, q_input} 
									  : {{7{q_input}}, q_input};

	/******************************************************
	* Mac module instantiation, wires, and logic
	******************************************************/
	logic clr_n; // clear the mac if low
	wire [25:0] acc; // result of mac
	wire [10:0] acc_rect; // rectified mac result
	wire [7:0] a, b; // inputs to mac
	wire of, uf; // detect overflow/underflow when rectifiying mac result
	
	mac mac(a,b,clr_n,clk,rst_n,acc);
	
	/******************************************************
	* Rom/Ram module instantiations and wires
	******************************************************/
	reg [14:0] addr_hidden_weight;
	reg [8:0] addr_output_weight;
	reg [4:0] addr_hidden_unit;
	reg [3:0] addr_output_unit;
	wire [7:0] q_weight_hidden, q_weight_output, q_hidden_unit, q_output_unit;
	wire [7:0] k_out;
	logic we_hidden, we_output;
	
	rom_hidden_weight rom_hidden_weight(addr_hidden_weight,clk,q_weight_hidden);
	rom_output_weight rom_output_weight(addr_output_weight,clk,q_weight_output);
	
	// TODO STEP 3 idk if you need to do anything other than instantiate the rom here Yk and Zk are set to k_out currently
	rom_act_func_lut rom_act_func_lut(acc_rect,clk,k_out);
	
	// TODO implmement we
	ram_hidden_unit ram_hidden_unit(k_out,addr_hidden_unit,we_hidden,clk,q_hidden_unit);
	ram_output_unit ram_output_unit(k_out,addr_output_unit,we_output,clk,q_output_unit);



	/******************************************************
	* MAC result caclulation and rectification
	******************************************************/
	// 2:1 muxes for mac inputs
	assign a = (sel) ? q_input_extend : q_hidden_unit;
	assign b = (sel) ? q_weight_hidden : q_weight_output;

	assign of = ((acc[25] == 0) && ^acc[24:17]);
	assign uf = ((acc[25] == 1) && ~&acc[24:17]);
	assign acc_rect = (of) ? 11'h3ff : ((uf) ? 11'h400 : (acc[17:7] + 11'h400));

	/******************************************************
	* Increment the bit address for each rom_output_weight/ram_hidden_unit each read cycle
	******************************************************/
	always@(posedge clk, negedge rst_n) begin
		if(!sel) begin
			addr_output_weight <= addr_output_weight + 1;
			addr_hidden_unit <= addr_hidden_unit + 1;
		end
	end
	/******************************************************
	* Increment the bit address for rom_hidden_weight/ram_input_unit when read
	******************************************************/
	always@(posedge clk, negedge rst_n) begin
		if(sel) begin
			addr_hidden_weight <= addr_hidden_weight + 1;
			addr_input_unit <= addr_input_unit + 1;
		end
	
	end

	/******************************************************
	* Increment the bit address for each ram_output_unit each write cycle
	******************************************************/
	always@(posedge clk, negedge rst_n) begin
		if(??) begin
			addr_output_unit <= addr_output_unit + 1;
		end
	end
	
	/******************************************************
	* State Machine Transition/Combinational Logic for the snn_core design
	******************************************************/
	typedef enum {IDLE,MAC} State;
	State state,nxt_state;
	
	always_comb begin
		sel = 0;
		clr_n = 1;
		nxt_state = IDLE;
		case (state)
			IDLE : begin
				if(start) begin
					sel = 1;
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


