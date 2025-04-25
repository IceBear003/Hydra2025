`include "ufp18_comp.v"
module ufp18_add 
#(
    parameter A_BITS = 18,
    parameter B_BITS = 18,
    parameter SUM_BITS = 18
)(
    input clk,
    input rst_n,
    input enable,

    input [17:0] a,
    input [17:0] b,
    output reg [17:0] sum
);

reg enable_d1;
reg enable_d2;
always @(posedge clk) begin
    if(~rst_n) begin
        enable_d1 <= 0;
        enable_d2 <= 0; 
    end else begin
        enable_d1 <= enable;
        enable_d2 <= enable_d1; 
    end   
end

wire comp;
ufp18_comp ufp18_comp(
    .a(a),
    .b(b),
    .comp(comp) 
);

reg [13:0] max_man;
reg [13:0] min_man;
reg [3:0] max_exp;
reg [3:0] min_exp;

always @(*) begin
    if(~rst_n) begin
        {max_exp, max_man} <= 0;
        {min_exp, min_man} <= 0;
    end else if(comp) begin
        {max_exp, max_man} <= a;
        {min_exp, min_man} <= b;
    end else begin
        {max_exp, max_man} <= b;
        {min_exp, min_man} <= a;
    end
end

reg [3:0] diff_exp;

always @(posedge clk) begin
    if(~rst_n) begin
        diff_exp <= 0;
    end else if(~enable) begin
        diff_exp <= max_exp - min_exp;
    end
end

reg [13:0] shift_max_man;
reg [13:0] shift_min_man;
reg [3:0] shift_exp;

always @(posedge clk) begin
    if(enable_d1) begin
        shift_max_man <= max_man;
        shift_min_man <= min_man >> diff_exp;
        shift_exp <= max_exp;
    end
end

wire [14:0] sum_man = shift_max_man + shift_min_man;

always @(posedge clk) begin
    if(~rst_n) begin
        sum <= 0;
    end else if(~enable_d2) begin
    end else if(sum_man[14]) begin
        sum <= {shift_exp + 1'b1, sum_man[14:1]}; 
    end else begin
        sum <= {shift_exp, sum_man[13:0]};
    end
end

endmodule