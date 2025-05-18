module buffers(
    input clk,
    input rst_n,

    input clear,
    input en,

    input [11:0] range,
    input [11:0] velocity,
    input [11:0] range_cnt,
    input [11:0] velocity_cnt,

    input [5:0] detection_flat,
    input [6*18-1:0] energy_sqrt_flat,

    output reg target_vld,
    output reg [11:0] target_range,
    output reg [11:0] target_velocity,
    output reg [17:0] target_energy,
    // output reg [17:0] target_noise,
    output reg [15:0] target_cnt
);

reg [5:0] target_select;
reg [17:0] target_energy_sqrt_flat [6:0];
reg [5:0] mask;
wire [5:0] target_select_masked = target_select & mask;

always @(posedge clk or negedge rst_n) begin
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

always @(posedge clk or negedge rst_n) begin
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

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        target_energy_sqrt_flat[0] <= 0;
        target_energy_sqrt_flat[1] <= 0;
        target_energy_sqrt_flat[2] <= 0;
        target_energy_sqrt_flat[3] <= 0;
        target_energy_sqrt_flat[4] <= 0;
        target_energy_sqrt_flat[5] <= 0;
        target_energy_sqrt_flat[6] <= 0;
    end else if(en) begin
        target_energy_sqrt_flat[0] <= energy_sqrt_flat[17:0];
        target_energy_sqrt_flat[1] <= energy_sqrt_flat[35:18];
        target_energy_sqrt_flat[2] <= energy_sqrt_flat[53:36];
        target_energy_sqrt_flat[3] <= energy_sqrt_flat[71:54];
        target_energy_sqrt_flat[4] <= energy_sqrt_flat[89:72];
        target_energy_sqrt_flat[5] <= energy_sqrt_flat[107:90];
    end
end

reg [2:0] index;

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
end

reg [2:0] target_index_buf;
reg [11:0] target_range_buf;
reg [11:0] target_velocity_buf;
reg [17:0] target_energy_sqrt_buf;

wire [13:0] energy_man = {target_energy_sqrt_buf[13:0] * target_energy_sqrt_buf[13:0]};
wire [4:0] energy_exp = target_energy_sqrt_buf[17:14] << 1;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        target_index_buf <= 6;
        target_range_buf <= 0;
        target_velocity_buf <= 0;
        target_energy_sqrt_buf <= 0;
    end else begin 
        target_index_buf <= index;
        target_range_buf <= range_cnt + 1;
        target_velocity_buf <= velocity_cnt + index + 3;
        target_energy_sqrt_buf <= target_energy_sqrt_flat[index];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        target_vld <= 0;
        target_range <= 0;
        target_velocity <= 0;
        target_energy <= 0;
    end else begin 
        target_vld <= target_velocity_buf > velocity + 2 ? 0 : target_index_buf != 6;
        target_range <= target_range_buf > range ? target_range_buf - range : target_range_buf;
        target_velocity <= target_velocity_buf > velocity ? target_velocity_buf - velocity : target_velocity_buf;
        target_energy <= {18{energy_exp[4]}} | {energy_exp, energy_man};
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        target_cnt <= 0;
    end else if(clear) begin
        target_cnt <= 0;
    end else if(target_vld) begin
        target_cnt <= target_cnt + 1;
    end
end

endmodule