module magnitude_estimators(
    input clk,
    input rst_n,
    
    input data_vld,
    input [6*32-1:0] data_in,

    output reg accumulator_en,
    output [6*18-1:0] magnitudes
);

always @(posedge clk) begin
    if(~rst_n) begin
        accumulator_en <= 0;
    end else begin
        accumulator_en <= data_vld;
    end
end

genvar index;
generate for(index = 0; index < 6; index = index + 1) begin : ME

wire [31:0] datum = data_in[index*32+31:index*32];

wire [13:0] im = datum[27:14];
wire [13:0] re = datum[13:0];

wire [13:0] im_abs = im[13] ? (~im[12:0] + 1'b1) : im[12:0];
wire [13:0] re_abs = re[13] ? (~re[12:0] + 1'b1) : re[12:0];

wire [3:0] exp = {~datum[31], datum[30:28]};            //补码转移码，最高位取反
wire [13:0] max = (im_abs > re_abs) ? im_abs : re_abs;
wire [13:0] min = (im_abs > re_abs) ? re_abs : im_abs;

wire [13:0] sum = max + {2'b00, min[13:2]};

reg [17:0] magnitude;
assign magnitudes[index*18+17:index*18] = magnitude;

always @(posedge clk) begin
    if(~rst_n) begin
        magnitude <= 0;
    end else if(~data_vld) begin
    end else if(sum[13]) begin
        magnitude <= {exp, sum};
    end else begin
        magnitude <= {exp - 1, sum[12:0], 1'b0};
    end
end

end endgenerate
endmodule