module hydra(
    input clk,
    input rst_n,
    
    input data_vld,
    input [6*32-1:0] data_in
);

wire accumulator_en;
wire [6*18-1:0] magnitudes;

magnitude_estimators magnitude_estimators(
    .clk(clk),
    .rst_n(rst_n),
    
    .data_vld(data_vld),
    .data_in(data_in),

    .accumulator_en(accumulator_en),
    .magnitudes(magnitudes)
);

endmodule