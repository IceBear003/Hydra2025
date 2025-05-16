module buffer(
    input clk,
    input rst_n,

    input clear,
    input en,

    input [11:0] range,
    input [11:0] range_cnt,
    input [11:0] velocity_cnt,

    input [5:0] detection_flat,
    input [6*18-1:0] energy_flat,

    output reg target_vld,
    output reg [11:0] target_range,
    output reg [11:0] target_velocity,
    output reg [17:0] target_energy,
    // output reg [17:0] target_noise,
    output reg [15:0] target_cnt
);


reg [5:0] target_select;
reg [17:0] target_energy_flat [6:0];
reg [5:0] mask;
wire [5:0] target_select_masked = target_select & mask;

always @(posedge clk) begin
    if(~rst_n) begin
        target_select <= 0;
    end else if(clear) begin
        target_select <= 0;
    end else if(en) begin
        target_select <= detection_flat;
    end else begin
        target_select <= target_select_masked;
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        mask <= 6'b111111;
    end else if(clear || en) begin
        mask <= 6'b111111;
    end else begin
        casex(target_select_masked)
            6'bxxxxx1: mask <= 6'b111110;
            6'bxxxx10: mask <= 6'b111100;
            6'bxxx100: mask <= 6'b111000;
            6'bxx1000: mask <= 6'b110000;
            6'bx10000: mask <= 6'b100000;
            default: mask <= 6'b000000;
        endcase
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        target_energy_flat[0] <= 0;
        target_energy_flat[1] <= 0;
        target_energy_flat[2] <= 0;
        target_energy_flat[3] <= 0;
        target_energy_flat[4] <= 0;
        target_energy_flat[5] <= 0;
        target_energy_flat[6] <= 0;
    end else if(en) begin
        target_energy_flat[0] <= energy_flat[17:0];
        target_energy_flat[1] <= energy_flat[35:18];
        target_energy_flat[2] <= energy_flat[53:36];
        target_energy_flat[3] <= energy_flat[71:54];
        target_energy_flat[4] <= energy_flat[89:72];
        target_energy_flat[5] <= energy_flat[107:90];
    end
end

reg [2:0] index;
reg wrapped_range_cnt;

always @(*) begin
    casex(target_select_masked)
        6'bxxxxx1: index = 0;
        6'bxxxx10: index = 1;
        6'bxxx100: index = 2;
        6'bxx1000: index = 3;
        6'bx10000: index = 4;
        6'b100000: index = 5;
        default: index = 6;
    endcase
    wrapped_range_cnt = range_cnt + index;
    if(wrapped_range_cnt > range) begin
        wrapped_range_cnt = wrapped_range_cnt - range;
        index = wrapped_range_cnt >= 3 ? 6 : index;
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        target_vld <= 0;
        target_range <= 0;
        target_velocity <= 0;
        target_energy <= 0;
        // target_noise <= 0;
    end else begin 
        target_vld <= index != 6;
        target_range <= wrapped_range_cnt;
        target_velocity <= velocity_cnt;
        target_energy <= target_energy_flat[index];
        // target_noise <= noises[index];
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        target_cnt <= 0;
    end else if(clear) begin
        target_cnt <= 0;
    end else if(target_vld) begin
        target_cnt <= target_cnt + 1;
    end
end

endmodule