module usu_fp18_add (       //unsigned + signed = unsigned
    input clk,
    input rst_n,
    input enable,

    input [17:0] a,         //无符号，正数
    input [18:0] b,         //有符号，可正可负，绝对值一定比a小

    output reg [17:0] sum   //无符号，正数
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

reg signed [14:0] max_man;
reg [4:0] max_exp;

always @(posedge clk) begin
    if(~rst_n) begin
        {max_exp, max_man} <= 0;
    end else if(comp) begin
        max_exp <= a[17:14] + 1;    //多加一位，在最后的后移位部分中减回去
        {max_man[14], max_exp, max_man[13:0]} <= {1'b0, a};
    end else begin
        max_exp <= b[17:14] + 1;    //多加一位，在最后的后移位部分中减回去
        {max_man[14], max_exp, max_man[13:0]} <= b;
    end
end

reg preshift_sign;
reg [13:0] preshift_num;
reg [3:0] preshift_bit;

always @(*) begin
    if(comp) begin
        preshift_sign = b[18];
        preshift_num = b[13:0];
        preshift_bit = a[17:14] - b[17:14];
    end else begin
        preshift_sign = 1'b0;
        preshift_num = a[13:0];
        preshift_bit = b[17:14] - a[17:14];
    end
end

//预移位树，共四层每层16个MUX2，可以实现0~15位的右移操作
//负数的算术右移要补1，因此补的数字由preshift_sign决定

wire [14:0] preshift_num_l1;
assign preshift_num_l1[14] = {1{preshift_sign}};
genvar preshift_i1;
generate for(preshift_i1 = 0; preshift_i1 < 14; preshift_i1 = preshift_i1 + 1) begin
    assign preshift_num_l1[preshift_i1] = preshift_bit[0] ? preshift_num[preshift_i1+1] : preshift_num[preshift_i1];
end endgenerate

wire [15:0] preshift_num_l2;
assign preshift_num_l2[15:14] = {2{preshift_sign}};
genvar preshift_i2;
generate for(preshift_i2 = 0; preshift_i2 < 14; preshift_i2 = preshift_i2 + 1) begin
    assign preshift_num_l2[preshift_i2] = preshift_bit[1] ? preshift_num_l1[preshift_i2+2] : preshift_num_l1[preshift_i2];
end endgenerate

wire [17:0] preshift_num_l3;
assign preshift_num_l3[17:14] = {4{preshift_sign}};
genvar preshift_i3;
generate for(preshift_i3 = 0; preshift_i3 < 14; preshift_i3 = preshift_i3 + 1) begin
    assign preshift_num_l3[preshift_i3] = preshift_bit[2] ? preshift_num_l2[preshift_i3+4] : preshift_num_l2[preshift_i3];
end endgenerate

wire [21:0] preshift_num_l4;
assign preshift_num_l4[21:14] = {8{preshift_sign}};
genvar preshift_i4;
generate for(preshift_i4 = 0; preshift_i4 < 14; preshift_i4 = preshift_i4 + 1) begin
    assign preshift_num_l4[preshift_i4] = preshift_bit[3] ? preshift_num_l3[preshift_i4+8] : preshift_num_l3[preshift_i4];
end endgenerate

reg signed [14:0] min_man;
always @(posedge clk) begin
    if(~rst_n) begin
        min_man <= 15'b0;
    end else if(enable) begin
        min_man <= {preshift_sign, preshift_num_l4[21:8]};
    end
end

//Stage 2: Addition and Normalization

wire signed [15:0] sum_man = min_man + max_man; //一定是正数

wire [14:0] postshift_num = sum_man[14:0];      //注意这里是15位，比加数多一位，因为可能两个正数相加进一位，也可能一正一负，退0~14位
reg [3:0] postshift_bit;

always @(*) begin
    case (sum_man[14:0])
        15'b1xxxxxxxxxxxxxx: postshift_bit = 4'b0000;
        15'b01xxxxxxxxxxxxx: postshift_bit = 4'b0001;
        15'b001xxxxxxxxxxxx: postshift_bit = 4'b0010;
        15'b0001xxxxxxxxxxx: postshift_bit = 4'b0011;
        15'b00001xxxxxxxxxx: postshift_bit = 4'b0100;
        15'b000001xxxxxxxxx: postshift_bit = 4'b0101;
        15'b0000001xxxxxxxx: postshift_bit = 4'b0110;
        15'b00000001xxxxxxx: postshift_bit = 4'b0111;
        15'b000000001xxxxxx: postshift_bit = 4'b1000;
        15'b0000000001xxxxx: postshift_bit = 4'b1001;
        15'b00000000001xxxx: postshift_bit = 4'b1010;
        15'b000000000001xxx: postshift_bit = 4'b1011;
        15'b0000000000001xx: postshift_bit = 4'b1100;
        15'b00000000000001x: postshift_bit = 4'b1101;
        15'b000000000000001: postshift_bit = 4'b1110;
        15'b000000000000000: postshift_bit = 4'b1111;
    endcase
end

//后移位树，共四层每层14个MUX2，可以实现0~15位的左移操作
//通过这种方式，动态移位操作从14个MUX14降解到64个MUX2

wire [15:0] postshift_num_l1;
assign postshift_num_l1[0] = 1'b0;
genvar postshift_i1;
generate for(postshift_i1 = 1; postshift_i1 < 16; postshift_i1 = postshift_i1 + 1) begin
    assign postshift_num_l1[postshift_i1] = postshift_bit[0] ? postshift_num[postshift_i1-1] : postshift_num[postshift_i1];
end endgenerate

wire [16:0] postshift_num_l2;
assign postshift_num_l2[1:0] = 2'b00;
genvar postshift_i2;
generate for(postshift_i2 = 2; postshift_i2 < 17; postshift_i2 = postshift_i2 + 1) begin
    assign postshift_num_l2[postshift_i2] = postshift_bit[1] ? postshift_num_l1[postshift_i2-2] : postshift_num_l1[postshift_i2];
end endgenerate

wire [18:0] postshift_num_l3;
assign postshift_num_l3[3:0] = 4'b0000;
genvar postshift_i3;
generate for(postshift_i3 = 4; postshift_i3 < 19; postshift_i3 = postshift_i3 + 1) begin
    assign postshift_num_l3[postshift_i3] = postshift_bit[2] ? postshift_num_l2[postshift_i3-4] : postshift_num_l2[postshift_i3];
end endgenerate

wire [22:0] postshift_num_l4;
assign postshift_num_l4[7:0] = 8'b00000000;
genvar postshift_i4;
generate for(postshift_i4 = 8; postshift_i4 < 23; postshift_i4 = postshift_i4 + 1) begin
    assign postshift_num_l4[postshift_i4] = postshift_bit[3] ? postshift_num_l3[postshift_i4-8] : postshift_num_l3[postshift_i4];
end endgenerate

always @(*) begin
    if(~rst_n) begin
        sum <= 18'b0;
    end else if(enable_d) begin
        sum <= {max_exp - postshift_bit, postshift_num_l4[21:8]};
    end
end

endmodule