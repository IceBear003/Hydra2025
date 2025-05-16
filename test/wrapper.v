module wrapper(
    input clk,
    input rst_n_i,

    input reset_i,
    input enable_i,

    input [17:0] a_i,
    input [17:0] b_i,
    output reg [17:0] sum_o
);

reg rst_n;

reg reset;
reg enable;

reg [17:0] a;
reg [17:0] b;
wire [17:0] sum;

always @(posedge clk) begin
    rst_n <= rst_n_i;
    reset <= reset_i;
    enable <= enable_i;
    a <= a_i;
    b <= b_i;
    sum_o <= sum;
end

uuu_fp18_add uuu_fp18_add(
    .clk(clk),
    .rst_n(rst_n),

    .reset(reset),
    .enable(enable),

    .a(a),
    .b(b),
    .sum(sum)
);

endmodule