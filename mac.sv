/* ECE 551
 * File:  mac.sv
 * Names: Garret Huibregtse
 *	      Sean Cohen
 *        Austin Wirtz
*/

module mac(a,b,clr_n,clk,rst_n,acc);

input signed [7:0] a,b;
input clr_n,clk,rst_n;
output reg signed [25:0] acc;

wire signed [25:0] mult_extend;
wire signed [15:0] mult;
wire signed [25:0] add;
wire signed [25:0] acc_nxt;


// If rst_n is asserted reset, else accumulate
always@(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		acc <= 26'h0000;
	end
	else begin
		acc <= acc_nxt;
	end

end


assign mult = a * b; 
// sign extend mult
assign mult_extend = {{10{mult[15]}} , mult[15:0]};
assign add = mult_extend + acc;

// if clr_n is not asserted, accumulate
assign acc_nxt = (clr_n) ? add : 26'h0000;

endmodule
