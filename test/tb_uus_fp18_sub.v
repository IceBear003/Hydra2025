`timescale 1ns/1ns
`include "uus_fp18_sub.v"
module tb_uus_fp18_sub;

reg clk = 1;
reg rst_n;
reg enable;

reg [17:0] a;
reg [17:0] b;

wire [18:0] diff;

initial begin
    forever #(1) clk = ~clk;
end

uus_fp18_sub inst(
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable),
    .a(a),
    .b(b),
    .diff(diff)
);

initial begin
    $dumpfile("tb_uus_fp18_sub.vcd");
    $dumpvars();
    rst_n <= 0;
    enable <= 0;
    a <= 0;
    b <= 0;
    #2;
    rst_n <= 1;
    #2 
    enable <= 1;
    a <= {4'b0100, 14'b10000000000000};
    b <= {4'b0000, 14'b10000000000000};
    #2 
    enable <= 1;
    a <= {4'b0100, 14'b10000000000000};
    b <= {4'b0011, 14'b11111100000000};
    #2 
    enable <= 1;
    a <= {4'b0100, 14'b10000000000000};
    b <= {4'b0101, 14'b11000000000000};
    #2 
    enable <= 0;
    #2 
    #10;
    $finish();
end
endmodule