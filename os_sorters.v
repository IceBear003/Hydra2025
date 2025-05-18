module os_sorters(
    input clk,
    input rst_n,

    input [11:0] range,

    input forced_clear,
    input en_external,

    input [6*18-1:0] accumulation_flat,

    output next_clear, //改成reg
    output reg next_en,
    output [6*18-1:0] rank_3_flat,

    output reg [11:0] range_cnt,
    output reg [11:0] velocity_cnt
);

reg clear;
wire en_internal = range_cnt > range;
wire en = en_internal || en_external;
assign next_clear = clear;
reg [2:0] velocity_cnt_inc;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        range_cnt <= 0;
        velocity_cnt <= 0;
        velocity_cnt_inc <= 3'b111;
    end else if(~en) begin
    end else if(range_cnt != range + 3) begin
        range_cnt <= range_cnt + 1;
    end else begin
        range_cnt <= 0;
        velocity_cnt <= velocity_cnt + velocity_cnt_inc;
        velocity_cnt_inc[1] <= ~velocity_cnt_inc[1];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        clear <= 0;
    end else begin
        clear <= (range_cnt == range + 3 && en) || forced_clear;
    end
end

reg [6*18-1:0] accumulation_storage_1;
reg [6*18-1:0] accumulation_storage_2;
reg [6*18-1:0] accumulation_storage_3;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        accumulation_storage_1 <= 0;
        accumulation_storage_2 <= 0;
        accumulation_storage_3 <= 0;
    end else if(range_cnt <= 2 && en) begin
        accumulation_storage_1 <= accumulation_flat;
        accumulation_storage_2 <= accumulation_storage_1;
        accumulation_storage_3 <= accumulation_storage_2;
    end else if(range_cnt > range) begin
        accumulation_storage_1 <= 0;
        accumulation_storage_2 <= accumulation_storage_1;
        accumulation_storage_3 <= accumulation_storage_2;
    end
end

reg [1:0] time_stamp;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        time_stamp <= 0;
    end else if(clear) begin
        time_stamp <= 0;
    end else if(en) begin
        time_stamp <= time_stamp + 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        next_en <= 0;
    end else begin
        next_en <= en;
    end
end

genvar i;
generate for(i = 0; i < 6; i = i + 1) begin: Sorter
    reg [17:0] ranks [3:0];
    reg [1:0] ages [3:0];

    wire [17:0] accumulation = en_internal ? accumulation_storage_3[i*18+17:i*18] : accumulation_flat[i*18+17:i*18];
    wire [17:0] rank_3 = ranks[2];
    assign rank_3_flat[i*18+17:i*18] = rank_3;

    wire [3:0] comps;
    reg [2:0] comp_i;

    assign comps[0] = accumulation > ranks[0];
    assign comps[1] = accumulation > ranks[1];
    assign comps[2] = accumulation > ranks[2];
    assign comps[3] = accumulation > ranks[3];

    always @(*) begin
        case (comps)
            4'b1111: comp_i = 0; 
            4'b1110: comp_i = 1; 
            4'b1100: comp_i = 2; 
            default: comp_i = 3; 
        endcase
    end

    wire [3:0] decay;
    reg [2:0] decay_i;

    assign decay[0] = ages[0] == time_stamp;
    assign decay[1] = ages[1] == time_stamp;
    assign decay[2] = ages[2] == time_stamp;
    assign decay[3] = ages[3] == time_stamp;

    always @(*) begin
        case (decay)
            4'b0001: decay_i = 0; 
            4'b0010: decay_i = 1; 
            4'b0100: decay_i = 2; 
            default: decay_i = 3; 
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            {ages[0], ranks[0]} <= {2'b00, 18'b0};
        end else if(clear) begin
            {ages[0], ranks[0]} <= {2'b00, 18'b0};
        end else if(~en) begin
        end else if(comp_i == 0) begin
            {ages[0], ranks[0]} <= {time_stamp, accumulation};
        end else if(decay_i == 0 && comp_i > 0) begin
            {ages[0], ranks[0]} <= {ages[1], ranks[1]};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            {ages[1], ranks[1]} <= {2'b00, 18'b0};
        end else if(clear) begin
            {ages[1], ranks[1]} <= {2'b00, 18'b0};
        end else if(~en) begin
        end else if(comp_i == 1) begin
            {ages[1], ranks[1]} <= {time_stamp, accumulation};
        end else if(decay_i <= 1 && comp_i > 1) begin
            {ages[1], ranks[1]} <= {ages[2], ranks[2]};
        end else if(comp_i < 1 && decay_i >= 1) begin
            {ages[1], ranks[1]} <= {ages[0], ranks[0]};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            {ages[2], ranks[2]} <= {2'b00, 18'b0};
        end else if(clear) begin
            {ages[2], ranks[2]} <= {2'b00, 18'b0};
        end else if(~en) begin
        end else if(comp_i == 2) begin
            {ages[2], ranks[2]} <= {time_stamp, accumulation};
        end else if(decay_i <= 2 && comp_i > 2) begin
            {ages[2], ranks[2]} <= {ages[3], ranks[3]};
        end else if(comp_i < 2 && decay_i >= 2) begin
            {ages[2], ranks[2]} <= {ages[1], ranks[1]};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            {ages[3], ranks[3]} <= {2'b00, 18'b0};
        end else if(clear) begin
            {ages[3], ranks[3]} <= {2'b00, 18'b0};
        end else if(~en) begin
        end else if(comp_i == 3) begin
            {ages[3], ranks[3]} <= {time_stamp, accumulation};
        end else if(comp_i < 3 && decay_i == 3) begin
            {ages[3], ranks[3]} <= {ages[2], ranks[2]};
        end
    end
end endgenerate
endmodule