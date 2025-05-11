module ctrl(
    input clk,
    input rst_n,

    input [1:0] command,  //00 - IDLE //01 - configuring //10 - new frame //11 - new data
    input [5:0] param,

    output reg velocity_over,
    output reg frame_over,

    output magnitude_estimator_ctrl,
    output reg [1:0] accumulator_ctrl,  //00 - idle //01 - reset //10 - idle //11 - enable
    output reg [1:0] osca_ctrl,         //00 - idle //01 - reset //10 - idle //11 - enable

    output [11:0] r,
    output [11:0] v
);

wire configuring = command == 2'b01;
wire new_frame = command == 2'b10;
wire new_data = command == 2'b11;
reg [2:0] state;

always @(posedge clk) begin
    if(~rst_n) begin
        state <= 0;
    end else if(configuring) begin
        state <= state + 1;
    end
end

reg [11:0] range;
reg [11:0] velocity;
reg [2:0] tx;
reg [2:0] rx;

always @(posedge clk) begin
    if(~rst_n) begin
        range <= 0;
        velocity <= 0;
        tx <= 0;
        rx <= 0;
    end else if(configuring) begin
        case(state)
            3'd1: range[11:6] <= param;
            3'd2: range[5:0] <= param;
            3'd3: velocity[11:6] <= param;
            3'd4: velocity[5:0] <= param;
            3'd5: tx <= param[2:0];
            3'd6: rx <= param[2:0];
        endcase
    end
end

reg [2:0] tx_cnt;
reg [2:0] rx_cnt;

always @(posedge clk) begin
    if(~rst_n) begin
        tx_cnt <= 0;
        rx_cnt <= 0;
    end else if(new_frame) begin
        tx_cnt <= 0;
        rx_cnt <= 0;
    end else if(~new_data) begin
    end else if(rx_cnt != rx) begin
        rx_cnt <= rx_cnt + 1'b1;
    end else if(tx_cnt != tx) begin
        rx_cnt <= 0;
        tx_cnt <= tx_cnt + 1'b1;
    end else begin
        rx_cnt <= 0;
        tx_cnt <= 0;
    end
end

reg [11:0] range_cnt;
reg [11:0] velocity_cnt;
assign r = range_cnt;
assign v = velocity_cnt;

always @(posedge clk) begin
    if(~rst_n) begin
        range_cnt <= 1;
        velocity_cnt <= 3;
    end else if(osca_ctrl != 2'b11) begin
    end else if(range_cnt != range) begin
        range_cnt <= range_cnt + 1'b1;
    end else if(velocity_cnt != velocity) begin
        range_cnt <= 1;
        velocity_cnt <= velocity_cnt + 1'b1;
    end else begin
        range_cnt <= 1;
        velocity_cnt <= 1'b1;
    end
end

//数据输入时就进行模长计算
assign magnitude_estimator_ctrl = new_data;

//非相干累加需要延迟模长计算一周期，以下为打拍逻辑
reg accumulator_reset;

always @(posedge clk) begin
    if(~rst_n) begin
        accumulator_reset <= 0;
    end else begin
        accumulator_reset <= new_data && tx_cnt == tx && rx_cnt == rx;
    end 
end

always @(posedge clk) begin
    if(~rst_n) begin
        accumulator_ctrl <= 2'b00;
    end else if(accumulator_reset) begin
        accumulator_ctrl <= 2'b01;
    end else begin
        accumulator_ctrl <= {1'b1, new_data};
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        osca_ctrl <= 2'b00;
    end else if(range_cnt == range && osca_ctrl == 2'b11) begin
        osca_ctrl <= 2'b01;
    end else begin
        osca_ctrl <= {1'b1, accumulator_reset};
    end
end
endmodule