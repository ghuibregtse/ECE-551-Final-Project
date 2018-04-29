/* Exercise 07 ECE 551
 * File:  mac_tb.sv
 * Names: Garret Huibregtse
 *	  Sean Cohen
*/

module mac_tb();

reg signed[8:0] a,b;
reg clr_n,clk,rst_n;
reg [25:0] acc;

mac iDUT(.a(a),.b(b),.clk(clk),.rst_n(rst_n),.clr_n(clr_n),.acc(acc));

// clk
initial begin
	clk = 0;
	forever begin
	#5 clk = ~clk;
	end
end

initial begin

	rst_n = 1'b0;
	clr_n = 1'b0;
	a = 8'h7f;
	b = 8'he8;
	#10 rst_n = 1'b1;
	clr_n = 1'b1;

	// 2*5 + (-2)*5 + (-3)*8
	// no overflow/underflow
	@(posedge clk) begin 
	a = 8'hFE;
	end

	@(posedge clk) begin 
	a = 8'hFD;
	b = 8'h08;
	end

	@(posedge clk) begin
	clr_n = 0;
	rst_n = 0;
	end

	// 126*126*3
	// results in overflow
	@(posedge clk) begin
	clr_n = 1;
	rst_n = 1;
	a = 126;
	b = 126;
	end
	@(posedge clk)
	@(posedge clk)



	@(posedge clk) begin
	clr_n = 0;
	rst_n = 0;
	end

	// 126*(126)*3
	// results in underflow
	@(posedge clk) begin
	clr_n = 1;
	rst_n = 1;
	a = 126;
	b = -126;
	end
	@(posedge clk)
	@(posedge clk)
	@(posedge clk)


	$stop;



end 
endmodule