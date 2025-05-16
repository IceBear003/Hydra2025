module output_buffer(
    input clk,
    input rst_n,

    input [11:0] r,
    input [11:0] v,

    input [5:0] object_detected,
    input [5:0] object_energy,
    input [5:0] object_noise,

    output reg detected,
    output reg [11:0] detected_range,
    output reg [11:0] detected_velocity,
    output reg [17:0] detected_energy,
    output reg [17:0] detected_noise
);

//3深度漏桶，并行写入，需要一组仲裁选通信号

endmodule