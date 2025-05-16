`include "magnitude_estimators.v"
`include "accumulators.v"
`include "sorter.v"
`include "diff.v"
`include "summers.v"
`include "detectors.v"
module hydra(
    input clk,
    input rst_n,

    input [1:0] command,  //00 - IDLE //01 - configuring //10 - new frame //11 - new data
    input [5:0] param,
    
    input data_vld,
    input [6*32-1:0] data_in,
    input [6*32-1:0] data_detecting,

    output ready_for_new_data,

    output target_vld,
    output [11:0] target_range,
    output [11:0] target_velocity,
    output [17:0] target_energy,
    // output [17:0] target_noise,
    output [15:0] target_cnt
);

wire [11:0] range;
wire [11:0] velocity;
wire [2:0] tx;
wire [2:0] rx;

conf conf(
    .clk(clk),
    .rst_n(rst_n),

    .command(command),
    .param(param),

    .range(range),
    .velocity(velocity),
    .tx(tx),
    .rx(rx)
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
    .rx(rx),
    .tx(tx),
    .accumulator_en(accumulator_en),
    .magnitudes(magnitudes),
    .sorter_en(sorter_en),
    .accumulations(accumulations)
);

wire diff_en;
wire diff_rst;
wire [6*18-1:0] rank_3s;

sorter sorter(
    .clk(clk),
    .rst_n(rst_n),
    .range(range),
    .forced_rst(command == 2'b10),
    .en(sorter_en),
    .accumulation(accumulations),
    .diff_en(diff_en),
    .diff_rst(diff_rst),
    .rank_3(rank_3s)
);

wire summation_en;
wire summer_rst;
wire [3*19-1:0] differences;

diff diff(
    .clk(clk),
    .rst_n(rst_n),
    .en(diff_en),
    .rst(diff_rst),
    .rank_3s(rank_3s),
    .summation_en(summation_en),
    .summer_rst(summer_rst),
    .differences(differences)
);

wire detector_en;
wire [3*18-1:0] summations;

summers summers(
    .clk(clk),
    .rst_n(rst_n),
    .en(summation_en),
    .differences(differences),
    .detector_en(detector_en),
    .summations(summations)
);

wire buffer_en;
wire [6*18-1:0] elements;
wire [5:0] target_detected;

detectors detectors(
    .clk(clk),
    .rst_n(rst_n),
    .en(detector_en),
    .summations(summations),
    .elements(elements),
    .buffer_en(buffer_en),
    .target_detected(target_detected)
);

buffer buffer(
    .clk(clk),
    .rst_n(rst_n),

    .en(buffer_en),
    .rst(new_frame),//TODO

    .range(),       //TODO
    .range_cnt(),
    .velocity_cnt(),

    .detected(target_detected),
    .energies(elements),

    .target_vld(target_vld),
    .target_range(target_range),
    .target_velocity(target_velocity),
    .target_energy(target_energy),
    //.target_noise(),
    .target_cnt(target_cnt)
);

endmodule