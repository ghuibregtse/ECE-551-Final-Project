module snn_core_tb();

reg clk, rst_n;
reg start;
reg q_input;
reg [9:0] addr_input_unit;
reg [3:0] digit;
reg done;
reg data, we;

ram_input_unit ram(.data(data),.addr(addr_input_unit),.we(we),.clk(clk),.q(q_input));
snn_core iDUT(.clk(clk), .rst_n(rst_n), .start(start), .q_input(q_input), .addr_input_unit(addr_input_unit), .digit(digit), .done(done));


initial begin
	clk = 0;
	forever 
		#5 clk = ~clk;
end

initial begin
	rst_n = 0;
	start = 0;
	data = 0;
	we = 0;
	@(posedge clk);
	rst_n = 1;
	@(posedge clk);
	@(posedge clk);
	start = 1;
	@(posedge clk);
	start = 0;
	repeat (32) repeat (800) @(posedge clk);
	$stop;
	
	//if (done)
	//	$stop;
	//else
	//	@(posedge clk);
	

end


endmodule
