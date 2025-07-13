module ufp18_comp(
    input [17:0] a,
    input [17:0] b,
    output comp
);

assign comp = a > b;

endmodule