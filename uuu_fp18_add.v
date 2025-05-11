module uuu_fp18_adder ( //unsigned + unsigned = unsigned
    input clk,
    input rst_n,
    input enable,

    input [17:0] a,
    input [17:0] b,
    output reg [17:0] sum
);

//两周期完成，需要一个打一拍的门控信号

reg enable_d;
always @(posedge clk) begin
    if(~rst_n) begin
        enable_d <= 0;
    end else begin
        enable_d <= enable;
    end   
end

//Stage 1: Comparison and Preshift

wire comp = a[17:14] > b[17:14];

reg [13:0] max_man;
reg [3:0] max_exp;

always @(posedge clk) begin
    if(~rst_n) begin
        {max_exp, max_man} <= 0;
    end else if(comp) begin
        {max_exp, max_man} <= a;
    end else begin
        {max_exp, max_man} <= b;
    end
end

reg [13:0] preshift_num;
reg [3:0] preshift_bit;

always @(*) begin
    if(comp) begin
        preshift_num = b[13:0];
        preshift_bit = a[17:14] - b[17:14];
    end else begin
        preshift_num = a[13:0];
        preshift_bit = b[17:14] - a[17:14];
    end
end

//预移位树，共四层每层14个MUX2，可以实现0~15位的右移操作
//通过这种方式，动态移位操作从14个MUX14降解到64个MUX2

wire [14:0] preshift_num_l1;
assign preshift_num_l1[14] = 1'b0;
genvar preshift_i1;
generate for(preshift_i1 = 0; preshift_i1 < 14; preshift_i1 = preshift_i1 + 1) begin
    assign preshift_num_l1[preshift_i1] = preshift_bit[0] ? preshift_num[preshift_i1+1] : preshift_num[preshift_i1];
end endgenerate

wire [15:0] preshift_num_l2;
assign preshift_num_l2[15:14] = 2'b00;
genvar preshift_i2;
generate for(preshift_i2 = 0; preshift_i2 < 14; preshift_i2 = preshift_i2 + 1) begin
    assign preshift_num_l2[preshift_i2] = preshift_bit[1] ? preshift_num_l1[preshift_i2+2] : preshift_num_l1[preshift_i2];
end endgenerate

wire [17:0] preshift_num_l3;
assign preshift_num_l3[17:14] = 4'b0000;
genvar preshift_i3;
generate for(preshift_i3 = 0; preshift_i3 < 14; preshift_i3 = preshift_i3 + 1) begin
    assign preshift_num_l3[preshift_i3] = preshift_bit[2] ? preshift_num_l2[preshift_i3+4] : preshift_num_l2[preshift_i3];
end endgenerate

wire [21:0] preshift_num_l4;
assign preshift_num_l4[21:14] = 8'b00000000;
genvar preshift_i4;
generate for(preshift_i4 = 0; preshift_i4 < 14; preshift_i4 = preshift_i4 + 1) begin
    assign preshift_num_l4[preshift_i4] = preshift_bit[3] ? preshift_num_l3[preshift_i4+8] : preshift_num_l3[preshift_i4];
end endgenerate

reg [13:0] min_man;
always @(posedge clk) begin
    if(~rst_n) begin
        min_man <= 14'b0;
    end else if(enable) begin
        min_man <= preshift_num_l4[21:8];
    end
end

//Stage 2: Addition and Normalization

wire [14:0] sum_man = min_man + max_man;

always @(*) begin
    if(~rst_n) begin
        sum <= 18'b0;
    end else if(~enable_d) begin
    end else if(sum_man[14]) begin
        sum <= {max_exp + 1, sum_man[14:1]};
    end else begin
        sum <= {max_exp, sum_man[13:0]};
    end
end

endmodule