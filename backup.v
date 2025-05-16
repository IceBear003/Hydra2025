module magnitude_estimators(
    input clk,
    input rst_n,
    
    input data_vld,
    input [6*32-1:0] data_in,

    output accumulator_en,
    output [6*18-1:0] magnitudes
);

reg data_vld_d1;
reg data_vld_d2;
assign accumulator_en = data_vld_d2;

always @(posedge clk) begin
    if(~rst_n) begin
        data_vld_d1 <= 0;
        data_vld_d2 <= 0;
    end else begin
        data_vld_d1 <= data_vld;
        data_vld_d2 <= data_vld_d1;
    end
end

genvar index;
generate for(index = 0; index < 6; index = index + 1) begin : ME

wire [31:0] datum = data_in[index*32+31:index*32];

wire [13:0] im = datum[27:14];
wire [13:0] re = datum[13:0];

wire [12:0] im_abs = im[13] ? (~im[12:0] + 1'b1) : im[12:0];
wire [12:0] re_abs = re[13] ? (~re[12:0] + 1'b1) : re[12:0];

reg [3:0] exp;
reg [12:0] max;
reg [12:0] min;

always @(posedge clk) begin
    if(~rst_n) begin
        data_vld_d1 <= 0;
        exp <= 0;
        max <= 0;
        min <= 0;
    end else if(data_vld) begin
        data_vld_d1 <= 1;
        exp <= {~datum[31], datum[30:28]};          //补码转移码，最高位取反
        max = (im_abs > re_abs) ? im_abs : re_abs;
        min = (im_abs > re_abs) ? im_abs : re_abs;
    end
end

wire [13:0] sum = max + min;
reg [17:0] magnitude;
assign magnitudes[index*18+17:index*18] = magnitude;

always @(posedge clk) begin
    if(~rst_n) begin
        magnitude <= 0;
    end else if(~data_vld_d1) begin
    end else if(sum[13]) begin
        magnitude <= {exp, sum};
    end else begin
        magnitude <= {exp - 1, sum[12:0], 1'b0};
    end
end

end endgenerate
endmodule