module ufp18_comp(
    input [17:0] a,
    input [17:0] b,
    output reg comp
);

wire [13:0] a_man = a[13:0];
wire [13:0] b_man = b[13:0];
wire [3:0] a_exp = a[17:14];
wire [3:0] b_exp = b[17:14];

always @(*) begin
    if(a_exp == b_exp) begin
        comp = a_man > b_man;
    end else begin
        comp = a_exp > b_exp;
    end
end

endmodule