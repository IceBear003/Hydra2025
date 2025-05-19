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
    input [6*19-1:0] energy_flat,
    input [3*19-1:0] noise_flat,

    output reg target_vld,
    output reg [11:0] target_range,
    output reg [11:0] target_velocity,
    output reg [18:0] target_energy,
    output reg [18:0] target_noise,
    output reg [15:0] target_cnt
);

reg [5:0] target_select;
reg [18:0] target_energies [6:0];
reg [18:0] target_noises [4:0];
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
        target_energies[0] <= 0;
        target_energies[1] <= 0;
        target_energies[2] <= 0;
        target_energies[3] <= 0;
        target_energies[4] <= 0;
        target_energies[5] <= 0;
        target_energies[6] <= 0;
    end else if(en) begin
        target_energies[0] <= energy_flat[18:0];
        target_energies[1] <= energy_flat[37:19];
        target_energies[2] <= energy_flat[56:38];
        target_energies[3] <= energy_flat[75:57];
        target_energies[4] <= energy_flat[94:76];
        target_energies[5] <= energy_flat[113:95];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        target_noises[0] <= 0;
        target_noises[1] <= 0;
        target_noises[2] <= 0;
        target_noises[3] <= 0;
    end else if(en) begin
        target_noises[0] <= noise_flat[18:0];
        target_noises[1] <= noise_flat[37:19];
        target_noises[2] <= noise_flat[56:38];
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
reg [18:0] target_energy_buf;
reg [18:0] target_noise_buf;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        target_index_buf <= 6;
        target_range_buf <= 0;
        target_velocity_buf <= 0;
        target_energy_buf <= 0;
        target_noise_buf <= 0;
    end else begin 
        target_index_buf <= index;
        target_range_buf <= range_cnt + 1;
        target_velocity_buf <= velocity_cnt + index + 3;    //TODO 问题！
        target_energy_buf <= target_energies[index];
        target_noise_buf <= target_noises[index[2:1]];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        target_vld <= 0;
        target_range <= 0;
        target_velocity <= 0;
        target_energy <= 0;
        target_noise <= 0;
    end else begin 
        target_vld <= target_velocity_buf > velocity + 2 ? 0 : target_index_buf != 6;
        target_range <= target_range_buf > range ? target_range_buf - range : target_range_buf;
        target_velocity <= target_velocity_buf > velocity ? target_velocity_buf - velocity : target_velocity_buf;
        target_energy <= target_energy_buf;
        target_noise <= target_noise_buf;
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