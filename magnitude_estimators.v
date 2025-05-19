module magnitude_estimators(
    input clk,
    input rst_n,
    
    input en,
    input [9*32-1:0] number_flat,

    output reg next_en,
    output [9*19-1:0] magnitude_flat
);

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        next_en <= 0;
    end else begin
        next_en <= en;
    end
end

genvar i;
generate for(i = 0; i < 9; i = i + 1) begin : Estimator
    wire [31:0] number = number_flat[i*32+31:i*32];

    wire [13:0] im = number[31:18];
    wire [13:0] re = number[17:4];

    wire [13:0] im_abs = im[13] ? (~im + 1'b1) : im;
    wire [13:0] re_abs = re[13] ? (~re + 1'b1) : re;

    wire [4:0] exp = {1'b0, ~number[3], number[2:0]} + 1'b1;            //补码转移码，加一放置过小下溢
    wire [13:0] max = (im_abs > re_abs) ? im_abs : re_abs;
    wire [13:0] min = (im_abs > re_abs) ? re_abs : im_abs;

    wire [13:0] sum = max + {2'b00, min[13:2]};

    reg [18:0] magnitude;
    assign magnitude_flat[i*19+18:i*19] = magnitude;
    wire [4:0] exp_minus = exp - 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            magnitude <= 0;
        end else if(~en) begin
        end else if(sum[13]) begin
            magnitude <= {exp, sum};
        end else begin
            magnitude <= {exp_minus, sum[12:0], 1'b0};
        end
    end
end endgenerate
endmodule