/* ECE 551 Spring 2018 Final Project
 *
 * File:	snn_core.sv
 * Authors:	Garret Huibregtse, Sean Cohen, Austin Wirtz
 */

module snn_core(clk, rst_n, start, q_input, addr_input_unit, digit, done);
	input clk, rst_n, start, q_input;
	output reg [9:0] addr_input_unit; // address of each bit
	output reg [3:0] digit; // output of the digit, cooresponds to index of max_val
	output logic done; // asseted when finished
	
	logic sel; // select for the muxes into the mac
	logic inc_hidden,inc_input,inc_output; // increment respective counter if asserted
	wire [7:0] q_input_extend; // saturated q 
	reg [4:0] cnt_hidden; // counter for hidden addresses
	reg [3:0] cnt_output; // counter for output addresses
	reg cnt_input_full, cnt_hidden_full, cnt_output_full; // asserted if counter is full
	logic clr_input, clr_hidden, clr_output;
	reg [7:0] max_val; // the value max value in ram output unit

	
	// if q_input = 1 make it 127, else make it 0
	assign q_input_extend = (q_input) ? {1'b0, {6{q_input}}, q_input} : {{7{q_input}}, q_input};

	/******************************************************
	* Mac module instantiation, wires, and logic
	******************************************************/
	logic clr_n; // clear the mac if low
	wire signed [25:0] acc; // result of mac
	wire signed [10:0] acc_rect,acc_rect_add; // rectified mac result
	wire signed [7:0] a, b; // inputs to mac
	wire of, uf; // detect overflow/underflow when rectifiying mac result
	
	mac mac(a,b,clr_n,clk,rst_n,acc);
	
	/******************************************************
	* Rom/Ram module instantiations and wires
	******************************************************/
	wire [7:0] q_weight_hidden, q_weight_output, q_hidden_unit; // outputs of ram/rom modules
	wire [7:0] k_out; // output of act_func_lut
	logic we_h; // write enable hidden/output
	
	rom_hidden_weight rom_hidden_weight({cnt_hidden,addr_input_unit},clk,q_weight_hidden);
	rom_output_weight rom_output_weight({cnt_output,cnt_hidden},clk,q_weight_output);
	rom_act_func_lut rom_act_func_lut(acc_rect_add,clk,k_out);
	ram_hidden_unit ram_hidden_unit(k_out,cnt_hidden,we_h,clk,q_hidden_unit);

	/******************************************************
	* MAC result caclulation and rectification
	******************************************************/
	// 2:1 muxes for mac inputs
	assign a = (sel) ? q_input_extend : q_hidden_unit;
	assign b = (sel) ? q_weight_hidden : q_weight_output;

	assign of = ((acc[25] == 0) && |acc[24:17]); // overflow occurs
	assign uf = ((acc[25] == 1) && ~&acc[24:17]); // underflow occurs
	// rectify mac result based on of/uf and the original result and add 1024
	assign acc_rect = (of) ? 11'h3ff : ((uf) ? 11'h400 : acc[17:7]);
	assign acc_rect_add = acc_rect + 1024;
	
	/******************************************************
	* addr_input_unit counter
	******************************************************/
	
	assign cnt_input_full = (addr_input_unit == 10'h30F) ? 1 : 0;
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			addr_input_unit <= 10'h0;
		else
			if (clr_input)
				addr_input_unit <= 10'h0;
			else if (inc_input)
				addr_input_unit <= addr_input_unit + 1;
			else
				addr_input_unit <= addr_input_unit;
	end
	/******************************************************
	* cnt_hidden counter
	******************************************************/
	assign cnt_hidden_full = (cnt_hidden == 10'h1F) ? 1 : 0;
	
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			cnt_hidden <= 5'h0;
		else
			if (clr_hidden)
				cnt_hidden <= 5'h0;
			else if (inc_hidden)
				cnt_hidden <= cnt_hidden + 1;
			else
				cnt_hidden <= cnt_hidden;
	end
	/******************************************************
	* cnt_output counter
	******************************************************/
	assign cnt_output_full = (cnt_output == 4'h9) ? 1 : 0;
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			cnt_output <= 4'h0;
		end else
			if (clr_output) begin
				cnt_output <= 4'h0;
			end else if (inc_output) begin
				cnt_output <= cnt_output + 1;
			end else begin
				cnt_output <= cnt_output;
			end
	end 
	typedef enum {IDLE,MAC_HIDDEN,MAC_HIDDEN_BP1,MAC_HIDDEN_BP2,MAC_HIDDEN_WRITE,
				  MAC_OUTPUT,MAC_OUTPUT_BP1,MAC_OUTPUT_BP2,MAC_OUTPUT_WRITE,DONE} State;
	State state,nxt_state;
	
	
	/******************************************************
	* Find Maximum in the output reg and assign to digit
	******************************************************/
	logic clr_max_val;
	always_ff @(posedge clk, negedge rst_n) begin
	
		if (!rst_n) begin
			max_val <= 8'h0;
			digit <= 4'h0;
		end else if (clr_max_val) begin
			max_val <= 8'h0;
			digit <= 4'h0;
		end else if(state == MAC_OUTPUT_WRITE) begin
			if (max_val < k_out) begin
				max_val <= k_out;
				digit <= cnt_output;
			end
		end else begin
				max_val <= max_val;
				digit <= digit;
			end
	end
	
	/******************************************************
	* State Machine Transition/Combinational Logic for the snn_core design
	******************************************************/
	
	/*
		TODO
		Determine where in which states we need to increment which counters and 
		which counters when they are full do we need to set the nxt_state with.
	*/
	always_comb begin
		sel = 1;
		clr_n = 1;
		we_h = 0;
		done = 0;
		nxt_state = IDLE;
		inc_hidden = 0;
		inc_output = 0;
		inc_input = 0;
		clr_hidden = 0;
		clr_input = 0;
		clr_output = 0;
		clr_max_val = 0;
		case (state)
			IDLE : begin
				if (start) begin
					nxt_state = MAC_HIDDEN;
					clr_n = 0;
				end
			end
			MAC_HIDDEN : begin
				if (cnt_input_full) begin
					clr_input = 1;
					nxt_state = MAC_HIDDEN_BP1;
				end else begin
					inc_input = 1;
					nxt_state = MAC_HIDDEN;
				end
			end
			MAC_HIDDEN_BP1 : begin
				nxt_state = MAC_HIDDEN_BP2;
			end
			MAC_HIDDEN_BP2 : begin
				nxt_state = MAC_HIDDEN_WRITE;
			end
			MAC_HIDDEN_WRITE : begin
				we_h = 1;
				if (cnt_hidden_full) begin
					clr_hidden = 1;
					clr_n = 0;
					nxt_state = MAC_OUTPUT;
				end else begin
					inc_hidden = 1;
					clr_n = 0;
					nxt_state = MAC_HIDDEN;
				end
			end
			MAC_OUTPUT : begin
				sel = 0;
				if (cnt_hidden_full) begin
					clr_hidden = 1;
					nxt_state = MAC_OUTPUT_BP1;
				end else begin
					inc_hidden = 1;
					nxt_state = MAC_OUTPUT;
				end
			end
			MAC_OUTPUT_BP1 : begin
				sel = 0;
				nxt_state = MAC_OUTPUT_BP2;
			end
			MAC_OUTPUT_BP2 : begin
				sel = 0;
				nxt_state = MAC_OUTPUT_WRITE;
			end
			MAC_OUTPUT_WRITE : begin
				sel = 0;
				if (cnt_output_full) begin
					clr_output = 1;
					nxt_state = DONE;
				end else begin
					inc_output = 1;
					clr_n = 0;
					nxt_state = MAC_OUTPUT;
				end
			end
			DONE : begin
				nxt_state = IDLE;
				done = 1;
				clr_max_val = 1;
				clr_hidden = 1;
				clr_input = 1;
				clr_output = 1;
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



