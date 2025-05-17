`include "conf.v"
`include "magnitude_estimators.v"
`include "magnitude_accumulators.v"
`include "os_sorters.v"
`include "ca_subtractors.v"
`include "ca_summers.v"
`include "cfar_detectors.v"
`include "buffers.v"
module hydra(
    input clk,
    input rst_n,

    input [1:0] command,  //00 - IDLE //01 - configuring //10 - new frame //11 - new data
    input [5:0] param,
    
    input data_in_vld,
    input [6*32-1:0] data_in,
    input data_detecting_vld,
    input [6*32-1:0] data_detecting,

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

wire magnitude_accumulators_en;
wire [6*18-1:0] magnitude_flat;

magnitude_estimators magnitude_estimators_1(
    .clk(clk),
    .rst_n(rst_n),
    .en(data_in_vld),
    .number_flat(data_in),
    .next_en(magnitude_accumulators_en),
    .magnitude_flat(magnitude_flat)
);

wire os_sorters_en;
wire [6*18-1:0] accumulation_flat;

magnitude_accumulators magnitude_accumulators(
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .tx(tx),
    .en(magnitude_accumulators_en),
    .magnitude_flat(magnitude_flat),
    .next_en(os_sorters_en),
    .accumulation_flat(accumulation_flat)
);

wire ca_subtractors_clear;
wire ca_subtractors_en;
wire [6*18-1:0] rank_3_flat;

wire [11:0] range_cnt;
wire [11:0] velocity_cnt;

os_sorters os_sorters(
    .clk(clk),
    .rst_n(rst_n),
    .range(range),
    .forced_clear(command == 2'b10),
    .en_external(os_sorters_en),
    .accumulation_flat(accumulation_flat),
    .next_clear(ca_subtractors_clear),
    .next_en(ca_subtractors_en),
    .rank_3_flat(rank_3_flat),
    .range_cnt(range_cnt),
    .velocity_cnt(velocity_cnt)
);

wire ca_summers_clear;
wire ca_summers_en;
wire [3*19-1:0] subtraction_flat;

ca_subtractors ca_subtractors(
    .clk(clk),
    .rst_n(rst_n),
    .clear(ca_subtractors_clear),
    .en(ca_subtractors_en),
    .rank_3_flat(rank_3_flat),
    .next_clear(ca_summers_clear),
    .next_en(ca_summers_en),
    .subtraction_flat(subtraction_flat)
);

wire cfar_detectors_clear;
wire cfar_detectors_en;
wire [3*18-1:0] summation_flat;

ca_summers ca_summers(
    .clk(clk),
    .rst_n(rst_n),
    .clear(ca_summers_clear),
    .en(ca_summers_en),
    .subtraction_flat(subtraction_flat),
    .next_clear(cfar_detectors_clear),
    .next_en(cfar_detectors_en),
    .summation_flat(summation_flat)
);

wire [6*18-1:0] detecting_magnitude_flat;
wire buffer_en;
wire [5:0] detection_flat;
wire [6*18-1:0] energy_flat;

magnitude_estimators magnitude_estimators_2(
    .clk(clk),
    .rst_n(rst_n),
    .en(data_detecting_vld),
    .number_flat(data_detecting),
    .magnitude_flat(detecting_magnitude_flat)
);

cfar_detectors cfar_detectors(
    .clk(clk),
    .rst_n(rst_n),
    .clear(cfar_detectors_clear),
    .en(cfar_detectors_en),
    .summation_flat(summation_flat),
    .magnitude_flat(detecting_magnitude_flat),
    .next_clear(buffer_clear),
    .next_en(buffer_en),
    .detection_flat(detection_flat),
    .energy_flat(energy_flat)
);

buffer buffer(
    .clk(clk),
    .rst_n(rst_n),
    .clear(buffer_clear),
    .en(buffer_en),
    .range(range),
    .velocity(velocity),
    .range_cnt(range_cnt),
    .velocity_cnt(velocity_cnt),
    .detection_flat(detection_flat),
    .energy_flat(energy_flat),
    .target_vld(target_vld),
    .target_range(target_range),
    .target_velocity(target_velocity),
    .target_energy(target_energy),
    //.target_noise(),
    .target_cnt(target_cnt)
);
endmodule