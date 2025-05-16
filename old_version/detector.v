module detector(
    input clk,
    input rst_n,

    input enable,
    input highest_among_neighbors,
    input [17:0] element,
    input [17:0] threshold,

    output reg object_detected
);

wire comp;

ufp18_comp ufp18_comp(
    .a(element),
    .b(threshold),
    .comp(comp)
);

always @(posedge clk) begin
    if(~rst_n) begin
        object_detected <= 0;
    end else if(~enable) begin
        object_detected <= 0;
    end else begin
        object_detected <= highest_among_neighbors && comp;
    end
end

endmodule