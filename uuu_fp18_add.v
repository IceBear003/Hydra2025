module uuu_fp18_add (
    input clk,
    input rst_n,

    input en,

    input [17:0] a,
    input [17:0] b,
    output reg [17:0] sum
);

//比较并确定预移位的位数

wire comp = a[17:14] > b[17:14];

reg [13:0] max_man;
reg [3:0] max_exp;

always @(*) begin
    if(comp) begin
        {max_exp, max_man} = a;
    end else begin
        {max_exp, max_man} = b;
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

wire [13:0] preshift_num_l1;
genvar preshift_i1;
generate for(preshift_i1 = 0; preshift_i1 < 14; preshift_i1 = preshift_i1 + 1) begin
    wire left_bit = preshift_i1 + 1 > 13 ? 0 : preshift_num[preshift_i1+1];
    assign preshift_num_l1[preshift_i1] = preshift_bit[0] ? left_bit : preshift_num[preshift_i1];
end endgenerate

wire [13:0] preshift_num_l2;
genvar preshift_i2;
generate for(preshift_i2 = 0; preshift_i2 < 14; preshift_i2 = preshift_i2 + 1) begin
    wire left_bit = preshift_i2 + 2 > 13 ? 0 : preshift_num_l1[preshift_i2+2];
    assign preshift_num_l2[preshift_i2] = preshift_bit[1] ? left_bit : preshift_num_l1[preshift_i2];
end endgenerate

wire [13:0] preshift_num_l3;
genvar preshift_i3;
generate for(preshift_i3 = 0; preshift_i3 < 14; preshift_i3 = preshift_i3 + 1) begin
    wire left_bit = preshift_i3 + 4 > 13 ? 0 : preshift_num_l2[preshift_i3+4];
    assign preshift_num_l3[preshift_i3] = preshift_bit[2] ? left_bit : preshift_num_l2[preshift_i3];
end endgenerate

wire [13:0] preshift_num_l4;
genvar preshift_i4;
generate for(preshift_i4 = 0; preshift_i4 < 14; preshift_i4 = preshift_i4 + 1) begin
    wire left_bit = preshift_i4 + 8 > 13 ? 0 : preshift_num_l3[preshift_i4+8];
    assign preshift_num_l4[preshift_i4] = preshift_bit[3] ? left_bit : preshift_num_l3[preshift_i4];
end endgenerate

wire [13:0] min_man = preshift_num_l4;

wire [14:0] sum_man = min_man + max_man;
wire [3:0] sum_exp = {3'b000, sum_man[14]} + max_exp;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        sum <= 18'b0;
    end else if(~en) begin
    end else if(sum_man[14]) begin              //后移位
        sum <= {sum_exp, sum_man[14:1]};
    end else begin
        sum <= {sum_exp, sum_man[13:0]};
    end
end

endmodule