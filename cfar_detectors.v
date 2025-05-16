module cfar_detectors(
    input clk,
    input rst_n,

    input en,

    input [3*18-1:0] summation_flat,
    input [6*18-1:0] magnitude_flat,

    output reg next_en,
    output [5:0] detection_flat,
    output [6*18-1:0] energy_flat
);

always @(posedge clk) begin
    if(~rst_n) begin
        next_en <= 0;
    end else begin
        next_en <= en;
    end
end

genvar i;
generate for(i = 0; i < 3; i = i + 1) begin: Detector
    reg detection_result_0;
    reg detection_result_1;
    assign detection_flat[2*i] = detection_result_0;
    assign detection_flat[2*i+1] = detection_result_1;

    wire [18:0] magnitude_0 = {1'b0, magnitude_flat[i*36+35:i*36+18]};
    wire [18:0] magnitude_1 = {1'b0, magnitude_flat[i*36+17:i*36]};

    wire [17:0] summation = summation_flat[i*18+17:i*18];
    wire [4:0] threshold_exp = summation[17:14] + 2;
    wire [13:0] threshold_man = summation[13:0];
    wire [18:0] threshold = {threshold_exp, threshold_man};

    always @(posedge clk) begin
        if(~rst_n) begin
            detection_result_0 <= 0;
            detection_result_1 <= 0;
        end else begin
            detection_result_0 <= en & (magnitude_0 > threshold);
            detection_result_1 <= en & (magnitude_1 > threshold);
        end
    end

    reg [17:0] energy_0;
    reg [17:0] energy_1;
    assign energy_flat[36*i+17:36*i+0] = energy_0;
    assign energy_flat[36*i+35:36*i+18] = energy_1;

    wire [13:0] square_man_0 = {magnitude_0[13:0] * magnitude_0[13:0]};
    wire [13:0] square_man_1 = {magnitude_1[13:0] * magnitude_1[13:0]};
    wire [4:0] square_exp_0 = magnitude_0[17:14] << 1;
    wire [4:0] square_exp_1 = magnitude_0[17:14] << 1;

    always @(posedge clk) begin
        if(~rst_n) begin
            energy_0 <= 0;
            energy_1 <= 0;
        end else if(en) begin
            energy_0 <= {18{square_exp_0[4]}} | {square_exp_0, square_man_0};
            energy_1 <= {18{square_exp_1[4]}} | {square_exp_1, square_man_1};
        end
    end
end endgenerate
endmodule