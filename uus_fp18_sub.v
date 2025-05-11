module uus_fp18_adder (      //unsigned - unsigned = signed
    input clk,
    input rst_n,
    input enable,

    input [17:0] a,         //无符号 被减数
    input [17:0] b,         //无符号 减数
    output reg [18:0] diff   //有符号 diff=a-b
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
reg is_max_minuend;

reg [13:0] max_man;
reg [3:0] max_exp;

always @(posedge clk) begin
    if(~rst_n) begin
        {max_exp, max_man} <= 0;
        is_max_minuend <= 0;
    end else if(comp) begin
        {max_exp, max_man} <= a;
        is_max_minuend <= 1;
    end else begin
        {max_exp, max_man} <= b;
        is_max_minuend <= 0;
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

//Stage 2: Subtraction and Normalization

wire signed [14:0] minuend = {1'b0, is_max_minuend ? max_man : min_man};
wire signed [14:0] subtrahend = {1'b0, is_max_minuend ? min_man : max_man};

wire signed [14:0] subtraction_result = minuend - subtrahend;

wire postshift_sign;
wire [13:0] postshift_num;
reg [3:0] postshift_bit;

always @(*) begin
    case (postshift_num ^ {14{postshift_sign}})
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
end

//后移位树，共四层每层14个MUX2，可以实现0~15位的左移操作，不论是正数还是负数，逻辑移位左移总是在最低位补0
//通过这种方式，动态移位操作从14个MUX14降解到64个MUX2

wire [14:0] postshift_num_l1;
assign postshift_num_l1[0] = 1'b0;
genvar postshift_i1;
generate for(postshift_i1 = 1; postshift_i1 < 15; postshift_i1 = postshift_i1 + 1) begin
    assign postshift_num_l1[postshift_i1] = postshift_bit[0] ? postshift_num[postshift_i1-1] : postshift_num[postshift_i1];
end endgenerate

wire [15:0] postshift_num_l2;
assign postshift_num_l2[1:0] = 2'b00;
genvar postshift_i2;
generate for(postshift_i2 = 2; postshift_i2 < 16; postshift_i2 = postshift_i2 + 1) begin
    assign postshift_num_l2[postshift_i2] = postshift_bit[1] ? postshift_num_l1[postshift_i2-2] : postshift_num_l1[postshift_i2];
end endgenerate

wire [17:0] postshift_num_l3;
assign postshift_num_l3[3:0] = 4'b0000;
genvar postshift_i3;
generate for(postshift_i3 = 4; postshift_i3 < 18; postshift_i3 = postshift_i3 + 1) begin
    assign postshift_num_l3[postshift_i3] = postshift_bit[2] ? postshift_num_l2[postshift_i3-4] : postshift_num_l2[postshift_i3];
end endgenerate

wire [21:0] postshift_num_l4;
assign postshift_num_l4[7:0] = 8'b00000000;
genvar postshift_i4;
generate for(postshift_i4 = 8; postshift_i4 < 22; postshift_i4 = postshift_i4 + 1) begin
    assign postshift_num_l4[postshift_i4] = postshift_bit[3] ? postshift_num_l3[postshift_i4-8] : postshift_num_l3[postshift_i4];
end endgenerate

always @(*) begin
    if(~rst_n) begin
        diff <= 19'b0;
    end else if(enable_d) begin
        diff <= {postshift_sign, max_exp - postshift_bit, postshift_num_l4[21:8]};
    end
end

endmodule