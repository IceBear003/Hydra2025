module hydra(
    input clk,
    input rst_n,

    input [1:0] command,  //00 - IDLE //01 - configuring //10 - new frame //11 - new data
    input [5:0] param,
    
    input data_vld,
    input [6*32-1:0] data_in,
    input [6*32-1:0] data_detecting,

    output target_vld,
    output [11:0] target_range,
    output [11:0] target_velocity,
    output [17:0] target_energy,
    // output [17:0] target_noise,
    output [15:0] target_cnt
);

endmodule