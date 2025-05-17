module uus_fp18_sub (
    input clk,
    input rst_n,

    input en,

    input [17:0] a,          //无符号 被减数
    input [17:0] b,          //无符号 减数
    output reg [18:0] diff   //有符号 diff=a-b
);

//Comparison and Preshift

wire [14:0] a_man = {1'b0, a[13:0]};
wire [3:0] a_exp = a[17:14];
wire [14:0] b_man = ~{1'b0, b[13:0]} + 1'b1;       //取补码
wire [3:0] b_exp = b[17:14];

wire comp = a_exp > b_exp;

reg signed [14:0] max_man;
reg [3:0] max_exp;

always @(*) begin
    if(comp) begin
        {max_exp, max_man} = {a_exp, a_man};
    end else begin
        {max_exp, max_man} = {b_exp, b_man};
    end
end

reg preshift_sign;
reg [13:0] preshift_num;
reg [3:0] preshift_bit;

always @(*) begin
    if(comp) begin
        {preshift_sign, preshift_num} = b_man;
        preshift_bit = a_exp - b_exp;
    end else begin
        {preshift_sign, preshift_num} = a_man;
        preshift_bit = b_exp - a_exp;
    end
end

//预移位树，共四层每层14个MUX2，可以实现0~15位的右移操作
//通过这种方式，动态移位操作从14个MUX14降解到64个MUX2

wire [13:0] preshift_num_l1;
genvar preshift_i1;
generate for(preshift_i1 = 0; preshift_i1 < 14; preshift_i1 = preshift_i1 + 1) begin
    wire left_bit = preshift_i1 + 1 > 13 ? preshift_sign : preshift_num[preshift_i1+1];
    assign preshift_num_l1[preshift_i1] = preshift_bit[0] ? left_bit : preshift_num[preshift_i1];
end endgenerate

wire [13:0] preshift_num_l2;
genvar preshift_i2;
generate for(preshift_i2 = 0; preshift_i2 < 14; preshift_i2 = preshift_i2 + 1) begin
    wire left_bit = preshift_i2 + 2 > 13 ? preshift_sign : preshift_num_l1[preshift_i2+2];
    assign preshift_num_l2[preshift_i2] = preshift_bit[1] ? left_bit : preshift_num_l1[preshift_i2];
end endgenerate

wire [13:0] preshift_num_l3;
genvar preshift_i3;
generate for(preshift_i3 = 0; preshift_i3 < 14; preshift_i3 = preshift_i3 + 1) begin
    wire left_bit = preshift_i3 + 4 > 13 ? preshift_sign : preshift_num_l2[preshift_i3+4];
    assign preshift_num_l3[preshift_i3] = preshift_bit[2] ? left_bit : preshift_num_l2[preshift_i3];
end endgenerate

wire [13:0] preshift_num_l4;
genvar preshift_i4;
generate for(preshift_i4 = 0; preshift_i4 < 14; preshift_i4 = preshift_i4 + 1) begin
    wire left_bit = preshift_i4 + 8 > 13 ? preshift_sign : preshift_num_l3[preshift_i4+8];
    assign preshift_num_l4[preshift_i4] = preshift_bit[3] ? left_bit : preshift_num_l3[preshift_i4];
end endgenerate

wire signed [14:0] min_man = {preshift_sign, preshift_num_l4};

//Subtraction and Normalization

wire signed [14:0] sum_man = max_man + min_man;

wire postshift_sign = sum_man[14];
wire [13:0] postshift_num = sum_man[13:0];
reg [3:0] postshift_bit;

always @(*) begin
    casex (postshift_num ^ {14{postshift_sign}})
        14'b1xxxxxxxxxxxxx: postshift_bit = 4'b0000;
        14'b01xxxxxxxxxxxx: postshift_bit = 4'b0001;
        14'b001xxxxxxxxxxx: postshift_bit = 4'b0010;
        14'b0001xxxxxxxxxx: postshift_bit = 4'b0011;
        14'b00001xxxxxxxxx: postshift_bit = 4'b0100;
        14'b000001xxxxxxxx: postshift_bit = 4'b0101;
        14'b0000001xxxxxxx: postshift_bit = 4'b0110;
        14'b00000001xxxxxx: postshift_bit = 4'b0111;
        14'b000000001xxxxx: postshift_bit = 4'b1000;
        14'b0000000001xxxx: postshift_bit = 4'b1001;
        14'b00000000001xxx: postshift_bit = 4'b1010;
        14'b000000000001xx: postshift_bit = 4'b1011;
        14'b0000000000001x: postshift_bit = 4'b1100;
        14'b00000000000001: postshift_bit = 4'b1101;
        14'b00000000000000: postshift_bit = 4'b1110;
    endcase
    postshift_bit = postshift_bit <= max_exp ? postshift_bit : max_exp;
end

//后移位树，共四层每层14个MUX2，可以实现0~15位的左移操作，不论是正数还是负数，逻辑移位左移总是在最低位补0
//通过这种方式，动态移位操作从14个MUX14降解到64个MUX2

wire [13:0] postshift_num_l1;
genvar postshift_i1;
generate for(postshift_i1 = 0; postshift_i1 < 14; postshift_i1 = postshift_i1 + 1) begin
    wire right_bit = postshift_i1 - 1 < 0 ? 0 : postshift_num[postshift_i1-1];
    assign postshift_num_l1[postshift_i1] = postshift_bit[0] ? right_bit : postshift_num[postshift_i1];
end endgenerate

wire [13:0] postshift_num_l2;
genvar postshift_i2;
generate for(postshift_i2 = 0; postshift_i2 < 14; postshift_i2 = postshift_i2 + 1) begin
    wire right_bit = postshift_i2 - 2 < 0 ? 0 : postshift_num_l1[postshift_i2-2];
    assign postshift_num_l2[postshift_i2] = postshift_bit[1] ? right_bit : postshift_num_l1[postshift_i2];
end endgenerate

wire [13:0] postshift_num_l3;
genvar postshift_i3;
generate for(postshift_i3 = 0; postshift_i3 < 14; postshift_i3 = postshift_i3 + 1) begin
    wire right_bit = postshift_i3 - 4 < 0 ? 0 : postshift_num_l2[postshift_i3-4];
    assign postshift_num_l3[postshift_i3] = postshift_bit[2] ? right_bit : postshift_num_l2[postshift_i3];
end endgenerate

wire [13:0] postshift_num_l4;
genvar postshift_i4;
generate for(postshift_i4 = 0; postshift_i4 < 14; postshift_i4 = postshift_i4 + 1) begin
    wire right_bit = postshift_i4 - 8 < 0 ? 0 : postshift_num_l3[postshift_i4-8];
    assign postshift_num_l4[postshift_i4] = postshift_bit[3] ? right_bit : postshift_num_l3[postshift_i4];
end endgenerate

always @(posedge clk) begin
    if(~rst_n) begin
        diff <= 19'b0;
    end else if(en) begin
        diff <= {postshift_sign, max_exp - postshift_bit, postshift_num_l4};
    end
end

endmodule