module snn_core_tb();

reg clk, rst_n;
reg start;
reg q_input;
reg [9:0] addr_input_unit,addr;
reg [3:0] digit;
reg done;
reg data, we;

ram_input_unit ram(.data(data),.addr(addr_input_unit),.we(we),.clk(clk),.q(q_input));
snn_core iDUT(.clk(clk), .rst_n(rst_n), .start(start), .q_input(q_input), .addr_input_unit(addr), .digit(digit), .done(done));

always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		addr_input_unit <= 10'h0;
	else
		addr_input_unit <= addr;
end

initial begin
	clk = 0;
	forever 
		#5 clk = ~clk;
end

initial begin
	addr = 0;
	rst_n = 0;
	start = 0;
	done = 0;
	data = 0;
	we = 0;
	digit = 0;
	@(posedge clk);
	rst_n = 1;
	@(posedge clk);
	@(posedge clk);
	start = 1;
	@(posedge clk);
	start = 1;
	repeat (1000) @(posedge clk);
	$stop;
	

end


endmodule
