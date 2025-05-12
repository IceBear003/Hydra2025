`timescale 1ns/1ns
`include "usu_fp18_add.v"
module tb_usu_fp18_add;

reg clk = 1;
reg rst_n;
reg enable;

reg [17:0] a;
reg [18:0] b;

wire [17:0] sum;

initial begin
    forever #(1) clk = ~clk;
end

usu_fp18_add inst(
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    $dumpfile("tb_usu_fp18_add.vcd");
    $dumpvars();
    rst_n <= 0;
    enable <= 0;
    a <= 0;
    b <= 0;
    #2;
    rst_n <= 1;
    #2 
    enable <= 1;
    a <= {4'b0010, 14'b10000000000000};
    b <= {1'b1, 4'b0001, 14'b01000000000000};
    #2 
    enable <= 1;
    a <= {4'b0010, 14'b10000000000000};
    b <= {1'b0, 4'b0001, 14'b11000000000000};
    #2 
    enable <= 0;
    #2 
    #10;
    $finish();
end
endmodule