module snn_core(clk,rst_n,start,q_input,addr_input_unit,digit,done);


input start, q_input, clk, rst_n;
output reg [9:0] addr_input_unit;
output [3:0] digit;
output done;

wire [7:0] a, b;
wire q_input_extend;

typedef enum {IDLE,MAC} State;
State state,nxt_state;

mac mac(a,b,clr_n,clk,rst_n,acc);

assign q_input_extend = {{7{q_input}}, q_input};
assign a = (something) ? q_input_extend : ram_hidden_unit;
assign b = (something) ? rom_hidden_weight : rom_output_weight;


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

