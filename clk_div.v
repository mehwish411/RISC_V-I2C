module clk_div(clk_d, clk);
input clk;
output reg clk_d;
reg [31:0] count;
initial
count = 32'h00000000;
//reg count;
always@(posedge (clk))
begin
if (count >= 32'd50000000)
count <= 32'h00000000;
else
begin
if (count<=32'd25000000)
clk_d <= 1;
else
clk_d <= 0;
count <= count + 1;
end
end
endmodule