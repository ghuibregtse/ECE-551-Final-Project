module snn_core_tb();

logic clk, rst_n;
logic start;
logic q_input;
logic [9:0] addr_input_unit;
logic [3:0] digit;
logic done;

snn_core iDUT(.clk(clk), .rst_n(rst_n), .start(start), .q_input(q_input), .addr_input_unit(addr_input_unit), .digit(digit), .done(done));

initial 
begin
rst_n = 0; //initialize reset as on
clk = 0;
start = 0; //initialize start
@(negedge clk) rst_n = 1; //release reset



end

always begin
  #5 clk = ~clk; // clock of period 10 ns, toggling every 5 ns
end

