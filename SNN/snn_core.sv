/* ECE 551 Spring 2018 Final Project
 *
 * File:	snn_core.sv
 * Authors:	Garret Huibregtse, Sean Cohen, Austin Wirtz
 */

module snn_core(clk, rst_n, start, q_input, addr_input_unit, digit, done);
	input clk, rst_n, start, q_input;
	output reg [9:0] addr_input_unit; // address of each bit
	output reg [3:0] digit; // output of the digit
	output logic done; // asseted when finished
	
	logic sel; // select for the muxes into the mac
	logic inc_hidden,inc_input,inc_output; // increment respective counter if asserted
	wire q_input_extend; // saturated q 
	
	reg [4:0] cnt_hidden; // counter for hidden addresses
	reg [9:0] cnt_input; // counter for input addresses
	reg [3:0] cnt_output; // counter for output addresses
	wire cnt_input_full, cnt_hidden_full, cnt_output_full; // asserted if counter is full
	
	// if q_input = 1 make it 127, else make it 0
	assign q_input_extend = (q_input) ? {1'b0, {6{q_input}}, q_input} : {{7{q_input}}, q_input};

	/******************************************************
	* Mac module instantiation, wires, and logic
	******************************************************/
	logic clr_n; // clear the mac if low
	wire [25:0] acc; // result of mac
	wire [10:0] acc_rect,acc_rect_add; // rectified mac result
	wire [7:0] a, b; // inputs to mac
	wire of, uf; // detect overflow/underflow when rectifiying mac result
	
	mac mac(a,b,clr_n,clk,rst_n,acc);
	
	/******************************************************
	* Rom/Ram module instantiations and wires
	******************************************************/
	// address inputs for each rom/ram module
	reg [14:0] addr_hidden_weight;
	reg [8:0] addr_output_weight;
	reg [4:0] addr_hidden_unit;
	reg [3:0] addr_output_unit; 
	wire [7:0] q_weight_hidden, q_weight_output, q_hidden_unit, q_output_unit; // outputs of ram/rom modules
	wire [7:0] k_out; // output of act_func_lut
	logic we_h, we_o; // write enable hidden/output

	
	rom_hidden_weight rom_hidden_weight(addr_hidden_weight,clk,q_weight_hidden);
	rom_output_weight rom_output_weight(addr_output_weight,clk,q_weight_output);
	rom_act_func_lut rom_act_func_lut(acc_rect_add,clk,k_out);
	ram_hidden_unit ram_hidden_unit(k_out,addr_hidden_unit,we_h,clk,q_hidden_unit);
	ram_output_unit ram_output_unit(k_out,addr_output_unit,we_o,clk,q_output_unit);

	assign addr_hidden_weight = {cnt_hidden,cnt_output}; // logic for hidden weight address
	assign addr_output_weight = {cnt_output,cnt_hidden}; // logic for output weight address


	/******************************************************
	* MAC result caclulation and rectification
	******************************************************/
	// 2:1 muxes for mac inputs
	assign a = (sel) ? q_input_extend : q_hidden_unit;
	assign b = (sel) ? q_weight_hidden : q_weight_output;

	assign of = ((acc[25] == 0) && ^acc[24:17]); // overflow occurs
	assign uf = ((acc[25] == 1) && ~&acc[24:17]); // underflow occurs
	// rectify mac result based on of/uf and the original result and add 1024
	assign acc_rect = (of) ? 11'h3ff : ((uf) ? 11'h400 : acc[17:7]);
	assign acc_rect_add = acc_rect + 1024;
	
	/******************************************************
	* cnt_input counter
	******************************************************/
	assign cnt_input_full = (cnt_input == 10'h310) ? 1 : 0;
	always@(posedge clk, negedge rst_n) begin
		if (!rst_n)
			cnt_input <= 10'h0;
		else
			if (cnt_input_full)
				cnt_input <= 10'h0;
			else if (inc_input)
				cnt_input <= cnt_input + 1;
			else
				cnt_input <= cnt_input;
	end
	/******************************************************
	* cnt_hidden counter
	******************************************************/
	assign cnt_hidden_full = (cnt_hidden == 5'h20) ? 1 : 0;
	always@(posedge clk, negedge rst_n) begin
		if (!rst_n)
			cnt_hidden <= 5'h0;
		else
			if (cnt_hidden_full)
				cnt_hidden <= 5'h0;
			else if (inc_hidden)
				cnt_hidden <= cnt_hidden + 1;
			else
				cnt_hidden <= cnt_hidden;
	end
	/******************************************************
	* cnt_output counter
	******************************************************/
	assign cnt_output_full = (cnt_output == 4'hA) ? 1 : 0;
	always@(posedge clk, negedge rst_n) begin
		if (!rst_n)
			cnt_output <= 4'h0;
		else
			if (cnt_output_full)
				cnt_output <= 4'h0;
			else if (inc_output)
				cnt_output <= cnt_output + 1;
			else
				cnt_output <= cnt_output;
	end
	
	/******************************************************
	* Find Maximum in the output reg and assign to digit
	******************************************************/
	// TODO
	
	/******************************************************
	* State Machine Transition/Combinational Logic for the snn_core design
	******************************************************/
	typedef enum {IDLE,MAC_HIDDEN,MAC_HIDDEN_BP1,MAC_HIDDEN_BP2,MAC_HIDDEN_WRITE,
				  MAC_OUTPUT,MAC_OUTPUT_BP1,MAC_OUTPUT_BP2,MAC_OUTPUT_WRITE,DONE} State;
	State state,nxt_state;
	
	
	/*
		Determine where in which states we need to increment which counters and 
		which counters when they are full do we need to set the nxt_state with.
	*/
	always_comb begin
		sel = 1;
		clr_n = 1;
		we_h = 0;
		we_o = 0;
		done = 0;
		nxt_state = IDLE;
		inc_hidden = 0;
		inc_output = 0;
		inc_input = 0;
		case (state)
			IDLE : begin
				if (start) begin
					nxt_state = MAC_HIDDEN;
					clr_n = 0;
				end
			end
			MAC_HIDDEN : begin
				if (?? full counter)
					nxt_state = MAC_HIDDEN_BP1;
				else
					nxt_state = MAC_HIDDEN;
			end
			MAC_HIDDEN_BP1 : begin
				nxt_state = MAC_HIDDEN_BP2;
			end
			MAC_HIDDEN_BP2 : begin
				we_h = 1;
				nxt_state = MAC_HIDDEN_WRITE;
			end
			MAC_HIDDEN_WRITE : begin
				if (?? full counter) begin
					clr_n = 0;
					sel = 0;
					nxt_state = MAC_OUTPUT;
				end else begin
					clr_n = 0;
					nxt_state = MAC_HIDDEN;
				end
			end
			MAC_OUTPUT : begin
				sel = 0;
				if(?? full counter)
					nxt_state = MAC_OUTPUT_BP1;
				else
					nxt_state = MAC_OUTPUT;
			end
			MAC_OUTPUT_BP1 : begin
				sel = 0;
				nxt_state = MAC_OUTPUT_BP2;
			end
			MAC_OUTPUT_BP2 : begin
				sel = 0;
				we_o = 1;
				nxt_state = MAC_OUTPUT_WRITE;
			end
			MAC_OUTPUT_WRITE : begin
				sel = 0;
				if (?? full counter)
					nxt_state = DONE;
				else begin
					clr_n = 0;
					nxt_state = MAC_OUTPUT;
				end
			end
			DONE : begin
				nxt_state = IDLE;
				done = 1;
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


