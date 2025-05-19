`include "conf.v"
`include "magnitude_estimators.v"
`include "magnitude_accumulators.v" 
`include "os_sorters.v"
`include "ca_summers.v"
`include "cfar_detectors.v"
`include "buffers.v"
module hydra(
    input clk,
    input rst_n,

    input [1:0] command,
    input [5:0] param,
    
    input data_in_vld,
    input [9*32-1:0] data_in,

    output target_vld,
    output [11:0] target_range,
    output [11:0] target_velocity,
    output [18:0] target_energy,
    output [18:0] target_noise,
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
wire [9*19-1:0] magnitude_flat;

magnitude_estimators magnitude_estimators(
    .clk(clk),
    .rst_n(rst_n),
    .en(data_in_vld),
    .number_flat(data_in),
    .next_en(magnitude_accumulators_en),
    .magnitude_flat(magnitude_flat)
);

wire os_sorters_en;
wire window_type;
wire [9*19-1:0] accumulation_flat;
wire [6*19-1:0] accumulation_flat_os = {accumulation_flat[170:152], accumulation_flat[151:133], accumulation_flat[113:95], 
                                        accumulation_flat[75:57],   accumulation_flat[37:19],   accumulation_flat[18:0]};
wire [7*19-1:0] accumulation_flat_choose = {accumulation_flat[151:133], accumulation_flat[132:114], accumulation_flat[113:95],
                                            accumulation_flat[94:76],   accumulation_flat[75:57],   accumulation_flat[56:38],
                                            accumulation_flat[37:19]};
wire [6*19-1:0] accumulation_flat_dt = window_type ? accumulation_flat_choose[7*19-1:19] : accumulation_flat_choose[6*19-1:0];

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

wire ca_summers_clear;
wire ca_summers_en;
wire [6*19-1:0] rank_3_flat;

wire [11:0] range_cnt;
wire [11:0] velocity_cnt;
reg [11:0] range_cnt_d1;
reg [11:0] range_cnt_d2;
reg [11:0] range_cnt_d3;
reg [11:0] range_cnt_d4;
reg [11:0] velocity_cnt_d1;
reg [11:0] velocity_cnt_d2;
reg [11:0] velocity_cnt_d3;
reg [11:0] velocity_cnt_d4;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        range_cnt_d1 <= 0;
        range_cnt_d2 <= 0;
        range_cnt_d3 <= 0;
        range_cnt_d4 <= 0;
        velocity_cnt_d1 <= 0;
        velocity_cnt_d2 <= 0;
        velocity_cnt_d3 <= 0;
        velocity_cnt_d4 <= 0;
    end else begin
        range_cnt_d1 <= range_cnt;
        range_cnt_d2 <= range_cnt_d1;
        range_cnt_d3 <= range_cnt_d2;
        range_cnt_d4 <= range_cnt_d3;
        velocity_cnt_d1 <= velocity_cnt;
        velocity_cnt_d2 <= velocity_cnt_d1;
        velocity_cnt_d3 <= velocity_cnt_d2;
        velocity_cnt_d4 <= velocity_cnt_d3;
    end
end

os_sorters os_sorters(
    .clk(clk),
    .rst_n(rst_n),
    .range(range),
    .forced_clear(command == 2'b10),
    .en_external(os_sorters_en),
    .accumulation_flat(accumulation_flat_os),
    .next_clear(ca_summers_clear),
    .next_en(ca_summers_en),
    .rank_3_flat(rank_3_flat),
    .range_cnt(range_cnt),
    .velocity_cnt(velocity_cnt),
    .window_type(window_type)
);

wire cfar_detectors_clear;
wire cfar_detectors_en;
wire [3*19-1:0] summation_flat;

ca_summers ca_summers(
    .clk(clk),
    .rst_n(rst_n),
    .clear(ca_summers_clear),
    .en(ca_summers_en),
    .rank_3_flat(rank_3_flat),
    .next_clear(cfar_detectors_clear),
    .next_en(cfar_detectors_en),
    .summation_flat(summation_flat)
);

wire buffer_en;
wire [5:0] detection_flat;
wire [6*19-1:0] energy_flat;
wire [3*19-1:0] noise_flat;

cfar_detectors cfar_detectors(
    .clk(clk),
    .rst_n(rst_n),
    .clear(cfar_detectors_clear),
    .en_external(cfar_detectors_en),
    .range_cnt(range_cnt_d3),
    .os_sorters_en(os_sorters_en),
    .summation_flat(summation_flat),
    .accumulation_flat(accumulation_flat_dt),
    .next_en(buffer_en),
    .detection_flat(detection_flat),
    .energy_flat(energy_flat),
    .noise_flat(noise_flat)
);

buffers buffers(
    .clk(clk),
    .rst_n(rst_n),
    .clear(command == 2'b10),
    .en(buffer_en),
    .range(range),
    .velocity(velocity),
    .range_cnt(range_cnt_d4),
    .velocity_cnt(velocity_cnt_d4),
    .detection_flat(detection_flat),
    .energy_flat(energy_flat),
    .noise_flat(noise_flat),
    .target_vld(target_vld),
    .target_range(target_range),
    .target_velocity(target_velocity),
    .target_energy(target_energy),
    .target_noise(target_noise),
    .target_cnt(target_cnt)
);
endmodule