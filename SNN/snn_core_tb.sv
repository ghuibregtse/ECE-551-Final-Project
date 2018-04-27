module snn_core_tb();

reg clk, rst_n;
reg start;
reg q_input;
reg [9:0] addr_input_unit;
reg [3:0] digit;
reg done;

ram_input_unit iDUT2(.data(data),.addr(addr_input_unit),.we(we),.clk(clk),.q(q_input));
snn_core iDUT(.clk(clk), .rst_n(rst_n), .start(start), .q_input(q_input), .addr_input_unit(addr_input_unit), .digit(digit), .done(done));

initial 
begin
addr_input_unit = 0;
rst_n = 0; //initialize reset as on
clk = 0;
start = 0; //initialize start
@(negedge clk) rst_n = 1; //release reset
@(negedge clk) start = 1; //start
while (!done) begin
@(posedge clk);
end
$stop;
end

always begin
  #5 clk = ~clk; // clock of period 10 ns, toggling every 5 ns
end
endmodule
