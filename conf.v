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
    output reg [2:0] rx
);

wire configuring = command == 2'b01;
reg [2:0] state;

always @(posedge clk) begin
    if(~rst_n) begin
        state <= 0;
    end else if(configuring) begin
        state <= state + 1;
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
            3'd1: range[11:6] <= param;
            3'd2: range[5:0] <= param;
            3'd3: velocity[11:6] <= param;
            3'd4: velocity[5:0] <= param;
            3'd5: tx <= param[2:0];
            3'd6: rx <= param[2:0];
        endcase
    end
end
endmodule