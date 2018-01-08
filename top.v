
module top (
  INA,
  INB,
  OUT
);

input [15:0] INA;
input [15:0] INB;

output reg [31:0] OUT;

always @(*) begin
  OUT <= INA + INB;
end

endmodule
