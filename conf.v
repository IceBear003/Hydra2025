module conf(
    input clk,
    input rst_n,

    //00 - IDLE 
    //01 - configuring 
    //10 - new frame 
    //11 - new data
    input [1:0] command,
    input [5:0] param,

    output reg [11:0] range,
    output reg [11:0] velocity,
    output reg [2:0] tx,
    output reg [2:0] rx,
    output reg capacity_choice
);

wire configuring = command == 2'b01;
reg [2:0] state;

always @(posedge clk) begin
    if(~rst_n) begin
        state <= 0;
    end else if(configuring) begin
        state <= state + 1;
    end else begin
        state <= 0;
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        range <= 0;
        velocity <= 0;
        tx <= 0;
        rx <= 0;
    end else if(configuring) begin
        case(state)
            3'd0: range[11:6] <= param;
            3'd1: range[5:0] <= param;
            3'd2: velocity[11:6] <= param;
            3'd3: velocity[5:0] <= param;
            3'd4: begin
                {rx, tx} <= {param[5:3], param[2:0]};
                capacity_choice <= (param[5:3] + 1) * (param[2:0] + 1) < 6;
            end
        endcase
    end
end
endmodule