`timescale 1ns/1ns
`include "hydra.v"
module tb_hydra;

reg clk = 1;
reg rst_n;

initial forever #(5) clk = ~clk;

reg [1:0] command;
reg [5:0] param;
reg data_in_vld;
reg [31:0] data_in [8:0];

wire target_vld;
wire [11:0] target_range;
wire [11:0] target_velocity;
wire [18:0] target_energy;
wire [15:0] target_cnt;

wire [9*32-1:0] data_in_flat = {data_in[8], data_in[7], data_in[6], 
                                data_in[5], data_in[4], data_in[3], 
                                data_in[2], data_in[1], data_in[0]};

hydra hydra(
    .clk(clk),
    .rst_n(rst_n),
    .command(command),
    .param(param),
    .data_in_vld(data_in_vld),
    .data_in(data_in_flat),
    .target_vld(target_vld),
    .target_range(target_range),
    .target_velocity(target_velocity),
    .target_energy(target_energy),
    .target_cnt(target_cnt)
);

initial begin
    command = 0;
    param = 0;
    data_in_vld = 0;
    data_in[0] = 0;
    data_in[1] = 0;
    data_in[2] = 0;
    data_in[3] = 0;
    data_in[4] = 0;
    data_in[5] = 0;
    data_in[6] = 0;
    data_in[7] = 0;
    data_in[8] = 0;
end

integer fd, i;
reg ret;

reg [11:0] range = 12'd127;
reg [11:0] velocity = 12'd95;
reg [2:0] rx = 3'd5;
reg [2:0] tx = 3'd5;

initial begin
    $dumpfile("tb_hydra.vcd");
    $dumpvars();
    fd = $fopen("data.txt", "r");
    rst_n = 0;
#10 rst_n = 1;
    command = 2'b01;
    param = range[11:6];
#10 param = range[5:0];
#10 param = velocity[11:6];
#10 param = range[5:0];
#10 param = {rx, tx};
#10 command = 2'b10;
#10 command = 2'b00;
    data_in_vld <= 1;
    while(!$feof(fd)) begin
        ret <= $fscanf(fd, "%32b %32b %32b %32b %32b %32b %32b %32b %32b", data_in[0], data_in[1], data_in[2], data_in[3], data_in[4], data_in[5], data_in[6], data_in[7], data_in[8]);
#10;end
    data_in_vld = 0;
#100;
    $fclose(fd);
    $finish();
end
endmodule

