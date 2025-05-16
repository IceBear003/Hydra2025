module hydra(
    input clk,
    input rst_n,
    
    input data_vld,
    input [6*32-1:0] data_in,
    input [6*32-1:0] 

    output ready
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

wire sorter_en;
wire [6*18-1:0] accumulations;

accumulators accumulators(
    .clk(clk),
    .rst_n(rst_n),
    .rx(),
    .tx(),
    .accumulator_en(accumulator_en),
    .magnitudes(magnitudes),
    .sorter_en(sorter_en),
    .accumulations(accumulations)
);

wire diff_en;
wire [6*18-1:0] rank_3s;

sorter sorter(
    .clk(clk),
    .rst_n(rst_n),
    .en(sorter_en),
    .rst(),
    .accumulation(accumulations),
    .diff_en(diff_en),
    .rank_3(rank_3s)
);

wire summation_en;
wire [3*19-1:0] differences;

diff diff(
    .clk(clk),
    .rst_n(rst_n),
    .en(diff_en),
    .rst(),
    .rank_3s(rank_3s),
    .summation_en(summation_en),
    .differences(differences)
);

wire detector_en;
wire [3*18-1:0] summations;

summers summers(
    .clk(clk),
    .rst_n(rst_n),
    .en(summation_en),
    .rst(),
    .differences(differences),
    .detector_en(detector_en),
    .summations(summations)
);

wire [6*18-1:0] elements;
wire [5:0] target_detected;

detectors detectors(
    .clk(clk),
    .rst_n(rst_n),
    .en(detector_en),
    .summations(summations),
    .elements(elements),
    .target_detected(target_detected)
);

endmodule