module summers(
    input clk,
    input rst_n,

    input en,
    input rst,

    input [3*19-1:0] differences,

    output reg detector_en,
    output [3*18-1:0] summations
);

always @(posedge clk) begin
    if(~rst_n) begin
        detector_en <= 0;
    end else begin
        detector_en <= en;
    end
end

genvar index;
generate for(index = 0; index < 3; index = index + 1) begin: Summer

wire [18:0] difference = differences[index*19+18:index*19];
wire [17:0] summation;
assign summations[index*18+17:index*18] = summation;
    
usu_fp18_acc summer(
    .clk(clk),
    .rst_n(rst_n),

    .en(en),
    .rst(rst),

    .a(summation),
    .b(difference),

    .sum(summation)
);

end endgenerate

endmodule