module os_sorters(
    input clk,
    input rst_n,

    input [10:0] range,

    input forced_clear,
    input en,

    input [6*18-1:0] accumulation_flat,

    output reg next_en,
    output next_clear,
    output [6*18-1:0] rank_3_flat
);

reg clear;
reg [11:0] range_cnt;
assign next_clear = clear;

always @(posedge clk) begin
    if(~rst_n) begin
        range_cnt <= 0;
    end else if(~en) begin
    end else if(range_cnt != range + 3) begin
        range_cnt <= range_cnt + 1;
    end else begin
        range_cnt <= 0;
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        clear <= 0;
    end else begin
        clear <= (range_cnt != range + 3 && en) || forced_clear;
    end
end

reg [1:0] old_time_stamp;
reg [1:0] new_time_stamp;

always @(posedge clk) begin
    if(rst_n) begin
        new_time_stamp <= 0;
        old_time_stamp <= 1;
    end else if(clear) begin
        new_time_stamp <= 0;
        old_time_stamp <= 1;
    end else if(en) begin
        new_time_stamp <= new_time_stamp + 1;
        old_time_stamp <= old_time_stamp + 1;
    end
end

always @(posedge clk) begin
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

    wire accumulation = accumulation_flat[i*18+17:i*18];
    assign rank_3_flat[i*18+17:i*18] = ranks[2];

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

    assign decay[0] = ages[0] == old_time_stamp;
    assign decay[1] = ages[0] == old_time_stamp;
    assign decay[2] = ages[0] == old_time_stamp;
    assign decay[3] = ages[0] == old_time_stamp;

    always @(*) begin
        case (comps)
            4'b0001: decay_i = 0; 
            4'b0010: decay_i = 1; 
            4'b0100: decay_i = 2; 
            default: decay_i = 3; 
        endcase
    end

    always @(posedge clk) begin
        if(~rst_n) begin
            {ages[0], ranks[0]} <= {2'b00, 18'b0};
        end else if(clear) begin
            {ages[0], ranks[0]} <= {2'b00, 18'b0};
        end else if(~en) begin
        end else if(comp_i == 0) begin
            {ages[0], ranks[0]} <= {new_time_stamp, accumulation};
        end else if(decay_i == 0 && comp_i > 0) begin
            {ages[0], ranks[0]} <= {ages[1], ranks[1]};
        end
    end

    always @(posedge clk) begin
        if(~rst_n) begin
            {ages[1], ranks[1]} <= {2'b00, 18'b0};
        end else if(clear) begin
            {ages[1], ranks[1]} <= {2'b00, 18'b0};
        end else if(~en) begin
        end else if(comp_i == 1) begin
            {ages[1], ranks[1]} <= {new_time_stamp, accumulation};
        end else if(decay_i <= 1 && comp_i > 1) begin
            {ages[1], ranks[1]} <= {ages[2], ranks[2]};
        end else if(comp_i < 1 && decay_i >= 1) begin
            {ages[1], ranks[1]} <= {ages[0], ranks[0]};
        end
    end

    always @(posedge clk) begin
        if(~rst_n) begin
            {ages[2], ranks[2]} <= {2'b00, 18'b0};
        end else if(clear) begin
            {ages[2], ranks[2]} <= {2'b00, 18'b0};
        end else if(~en) begin
        end else if(comp_i == 2) begin
            {ages[2], ranks[2]} <= {new_time_stamp, accumulation};
        end else if(decay_i <= 2 && comp_i > 2) begin
            {ages[2], ranks[2]} <= {ages[3], ranks[3]};
        end else if(comp_i < 2 && decay_i >= 2) begin
            {ages[2], ranks[2]} <= {ages[1], ranks[1]};
        end
    end

    always @(posedge clk) begin
        if(~rst_n) begin
            {ages[3], ranks[3]} <= {2'b00, 18'b0};
        end else if(clear) begin
            {ages[3], ranks[3]} <= {2'b00, 18'b0};
        end else if(~en) begin
        end else if(comp_i == 3) begin
            {ages[3], ranks[3]} <= {new_time_stamp, accumulation};
        end else if(comp_i < 3 && decay_i == 3) begin
            {ages[3], ranks[3]} <= {ages[2], ranks[2]};
        end
    end
end endgenerate
endmodule