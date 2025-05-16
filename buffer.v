module buffer(
    input clk,
    input rst_n,

    input en,
    input rst,

    input [11:0] range,
    input [11:0] range_cnt,
    input [11:0] velocity_cnt,

    input [5:0] detected,
    input [6*18-1:0] energies,

    output reg target_vld,
    output reg [11:0] target_range,
    output reg [11:0] target_velocity,
    output reg [17:0] target_energy,
    // output reg [17:0] target_noise,

    output reg [15:0] target_cnt
);


reg [5:0] target_select;
reg [17:0] target_energies [6:0];
reg [5:0] mask;
wire [5:0] target_select_masked = target_select & mask;

always @(posedge clk) begin
    if(~rst_n) begin
        target_select <= 0;
    end else if(rst) begin
        target_select <= 0;
    end else if(en) begin
        target_select <= detected;
    end else begin
        target_select <= target_select_masked;
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        target_energies[0] <= 0;
        target_energies[1] <= 0;
        target_energies[2] <= 0;
        target_energies[3] <= 0;
        target_energies[4] <= 0;
        target_energies[5] <= 0;
        target_energies[6] <= 0;
    end else if(en) begin
        target_energies[0] <= energies[17:0];
        target_energies[1] <= energies[35:18];
        target_energies[2] <= energies[53:36];
        target_energies[3] <= energies[71:54];
        target_energies[4] <= energies[89:72];
        target_energies[5] <= energies[107:90];
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        mask <= 6'b111111;
    end else if(rst || en) begin
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

reg [2:0] index;

reg true_range_cnt;

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
    true_range_cnt = range_cnt + index;
    if(true_range_cnt > range) begin
        true_range_cnt = true_range_cnt - range;
        index = true_range_cnt >= 3 ? 6 :index;
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
        target_range <= true_range_cnt;
        target_velocity <= velocity_cnt;
        target_energy <= target_energies[index];
        // target_noise <= noises[index];
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        target_cnt <= 0;
    end else if(rst) begin
        target_cnt <= 0;
    end else if(target_vld) begin
        target_cnt <= target_cnt + 1;
    end
end

endmodule