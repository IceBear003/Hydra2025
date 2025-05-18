module ca
(
    input clk,
    input rst_n,

    input enable,
    input [17:0] os_result,
    input [WIDTH-1:0] ca_result,

    output [WIDTH-1:0] ca_result_bus_a,
    output [WIDTH-1:0] ca_result_bus_b
);

reg [WIDTH-1:0] os_result_old;
reg [WIDTH-1:0] os_result_diff;
reg [WIDTH-1:0] ca_result_old;
reg enable_1d;
reg enable_2d;

always @(posedge clk or negedge rst_n) begin
    enable_1d <= enable;
    enable_2d <= enable_1d;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        os_result_old <= 0;
    end else if(enable) begin
        os_result_old <= os_result;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        os_result_diff <= 0;
    end else if(enable) begin
        os_result_diff <= os_result - os_result_old; //减法模块
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        ca_result_old <= 0;
    end else if(enable_2d) begin
        ca_result_old <= ca_result;
    end
end

assign ca_result_bus_a = enable_1d ? ca_result_old : {WIDTH{'z}};
assign ca_result_bus_b = enable_1d ? os_result_diff : {WIDTH{'z}};

endmodule