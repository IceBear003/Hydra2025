module magnitude_estimator(
    input clk,
    input rst_n,

    input [31:0] data_in,
    output reg [17:0] magnitude
);

wire [13:0] im = data_in[31:18];
wire [13:0] re = data_in[17:4];
wire [3:0] exp = data_in[3:0];

wire [12:0] im_abs = im[13] ? ~im + 1'b1 : im;
wire [12:0] re_abs = re[13] ? ~re + 1'b1 : re;

wire [12:0] max = im_abs > re_abs ? im_abs : re_abs;
wire [12:0] min = im_abs > re_abs ? re_abs : im_abs;

wire [13:0] sum = max + min[12:2];

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        magnitude <= 18'b0;
    end else begin
        magnitude <= {exp, sum};
    end
end

endmodule