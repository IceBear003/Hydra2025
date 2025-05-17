`timescale 1ns/1ns
`include "hydra.v"
module tb_hydra;

reg clk = 1;
reg rst;

initial begin
    forever #(5) clk = ~clk;
end

reg [1:0] command;
reg [5:0] param;
reg data_in_vld;
reg [31:0] data_in [5:0];
reg data_detecting_vld;
reg [31:0] data_detecting [5:0];
wire target_vld;
wire [11:0] target_range;
wire [11:0] target_velocity;
wire [17:0] target_energy;
wire [15:0] target_cnt;

wire [6*32-1:0] data_in_flat = {data_in[5], data_in[4], data_in[3], data_in[2], data_in[1], data_in[0]};
wire [6*32-1:0] data_detecting_flat = {data_detecting[5], data_detecting[4], data_detecting[3], data_detecting[2], data_detecting[1], data_detecting[0]};

hydra hydra(
    .clk(clk),
    .rst_n(rst_n),
    .command(command),
    .param(param),
    .data_in_vld(data_in_vld),
    .data_in(data_in_flat),
    .data_detecting_vld(data_detecting_vld),
    .data_detecting(data_detecting_flat),
    .target_vld(target_vld),
    .target_range(target_range),
    .target_velocity(target_velocity),
    .target_energy(target_energy),
    .target_cnt(target_cnt)
);

initial begin
    $dumpfile("tb_hydra.vcd");
    $dumpvars();
    clk = 1;
    rst = 1;
    #5 
    rst = 0;
    command = 2'b01;
    #5 
    command = 2'b00;
    $finish();
end
endmodule

