`timescale 1ns/1ns
`include "k_top_heap.v"
module tb_k_top_heap;

reg clk = 1;
reg rst_n;

initial begin
    forever #(1) clk = ~clk;
end

reg enable;
reg heap_type;
reg [3:0] k;

reg [19:0] number;
wire [19:0] kth_number;

k_top_heap k_top_heap(
    .clk(clk),
    .rst_n(rst_n),

    .enable(enable),
    .heap_type(heap_type),
    .k(k),

    .number(number),
    .kth_number(kth_number)
);

initial begin
    $dumpfile("tb_k_top_heap.vcd");
    $dumpvars();
    rst_n <= 0;
    heap_type <= 1;
    k <= 5;
    enable <= 0;
    #2 
    rst_n <= 1;
    #2
    number <= 20'd13;
    #2
    enable <= 1;
    #2
    enable <= 1;
    number <= 20'd9;
    #2
    enable <= 1;
    number <= 20'd10;
    #2
    enable <= 1;
    number <= 20'd1;
    #2
    enable <= 1;
    number <= 20'd7;
    #2
    enable <= 1;
    number <= 20'd6;
    #2
    enable <= 1;
    number <= 20'd22;
    #2
    enable <= 0;
    number <= 20'd12;


    
    #2 
    rst_n <= 0;
    heap_type <= 0;
    k <= 2;
    #2 
    rst_n <= 1;
    enable <= 0;
    #2
    number <= 20'd13;
    #2
    enable <= 1;
    #2
    enable <= 1;
    number <= 20'd9;
    #2
    enable <= 1;
    number <= 20'd10;
    #2
    enable <= 1;
    number <= 20'd1;
    #2
    enable <= 1;
    number <= 20'd7;
    #2
    enable <= 1;
    number <= 20'd6;
    #2
    enable <= 1;
    number <= 20'd22;
    #2
    enable <= 0;
    number <= 20'd12;

    $finish();
end
endmodule

