module cfar_detectors(
    input clk,
    input rst_n,

    input clear,
    input en_external,

    input [11:0] range_cnt,
    input os_sorters_en,

    input [3*19-1:0] summation_flat,
    input [6*19-1:0] accumulation_flat,

    output reg next_clear,
    output reg next_en,
    output [5:0] detection_flat,
    output [6*19-1:0] energy_sqrt_flat
);

wire en_internal = range_cnt > 3;
wire en = en_external && en_internal;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        next_clear <= 0;
        next_en <= 0;
    end else begin
        next_clear <= clear;
        next_en <= en;
    end
end

reg [6*19-1:0] accumulation_flat_queue [2:0];
reg [5:0] comp_queue [2:0];

wire [5:0] comp = {
    accumulation_flat[113:95] > accumulation_flat_queue[2][113:95],
    accumulation_flat[94:76] > accumulation_flat_queue[2][94:76],
    accumulation_flat[75:57] > accumulation_flat_queue[2][75:57],
    accumulation_flat[56:38] > accumulation_flat_queue[2][56:38],
    accumulation_flat[37:19] > accumulation_flat_queue[2][37:19],
    accumulation_flat[18:0] > accumulation_flat_queue[2][18:0]
};

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        accumulation_flat_queue[0] <= 0;
        accumulation_flat_queue[1] <= 0;
        accumulation_flat_queue[2] <= 0;
        comp_queue[0] <= 0;
        comp_queue[1] <= 0;
        comp_queue[2] <= 0;
    end else if(os_sorters_en) begin
        accumulation_flat_queue[0] <= accumulation_flat_queue[1];
        accumulation_flat_queue[1] <= accumulation_flat_queue[2];
        accumulation_flat_queue[2] <= accumulation_flat;
        comp_queue[0] <= comp_queue[1];
        comp_queue[1] <= comp_queue[2];
        comp_queue[2] <= comp;
    end
end

wire [5:0] higher_than_neighbors = comp_queue[0] & (~comp_queue[1]);
wire [6*19-1:0] magnitude_flat = accumulation_flat_queue[0];

genvar i;
generate for(i = 0; i < 3; i = i + 1) begin: Detector
    reg detection_result_0;
    reg detection_result_1;
    assign detection_flat[2*i] = detection_result_0;
    assign detection_flat[2*i+1] = detection_result_1;

    wire [18:0] magnitude_0 = magnitude_flat[i*38+37:i*36+19];
    wire [18:0] magnitude_1 = magnitude_flat[i*38+18:i*36];

    wire [18:0] summation = summation_flat[i*19+18:i*19];
    wire [4:0] threshold_exp = summation[18:14] + 2;
    wire [13:0] threshold_man = summation[13:0];
    wire [18:0] threshold = {threshold_exp, threshold_man};

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            detection_result_0 <= 0;
            detection_result_1 <= 0;
        end else begin
            detection_result_0 <= en && (magnitude_0 > threshold) && higher_than_neighbors[2*i];
            detection_result_1 <= en && (magnitude_1 > threshold) && higher_than_neighbors[2*i+1];
        end
    end

    reg [18:0] energy_sqrt_0;
    reg [18:0] energy_sqrt_1;
    assign energy_sqrt_flat[38*i+18:38*i] = energy_sqrt_0;
    assign energy_sqrt_flat[38*i+37:38*i+19] = energy_sqrt_1;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            energy_sqrt_0 <= 0;
            energy_sqrt_1 <= 0;
        end else if(en) begin
            energy_sqrt_0 <= magnitude_0;
            energy_sqrt_1 <= magnitude_1;
        end
    end
end endgenerate
endmodule