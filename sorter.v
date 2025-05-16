module sorter(
    input clk,
    input rst_n,

    input en,
    input rst,

    input [6*18-1:0] accumulation,

    output reg diff_en,
    output [6*18-1:0] rank_3
);

reg [1:0] old_time_stamp;
reg [1:0] new_time_stamp;

always @(posedge clk) begin
    if(rst_n) begin
        new_time_stamp <= 0;
        old_time_stamp <= 1;
    end else if(rst) begin
        new_time_stamp <= 0;
        old_time_stamp <= 1;
    end else if(en) begin
        new_time_stamp <= new_time_stamp + 1;
        old_time_stamp <= old_time_stamp + 1;
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        diff_en <= 0;
    end else begin
        diff_en <= en;
    end
end

genvar index;
generate for(index = 0; index < 6; index = index + 1) begin: Sorters

reg [17:0] elements [3:0];
reg [1:0] ages [3:0];

wire new_element = accumulation[index*18+17:index*18];
assign rank_3[index*18+17:index*18] = elements[2];

wire [3:0] comps;
reg [2:0] comp_element;

assign comps[0] = new_element > elements[0];
assign comps[1] = new_element > elements[1];
assign comps[2] = new_element > elements[2];
assign comps[3] = new_element > elements[3];

always @(*) begin
    case (comps)
        4'b1111: comp_element = 0; 
        4'b1110: comp_element = 1; 
        4'b1100: comp_element = 2; 
        default: comp_element = 3; 
    endcase
end

wire [3:0] decay;
reg [2:0] decay_element;

assign decay[0] = ages[0] == old_time_stamp;
assign decay[1] = ages[0] == old_time_stamp;
assign decay[2] = ages[0] == old_time_stamp;
assign decay[3] = ages[0] == old_time_stamp;

always @(*) begin
    case (comps)
        4'b0001: decay_element = 0; 
        4'b0010: decay_element = 1; 
        4'b0100: decay_element = 2; 
        default: decay_element = 3; 
    endcase
end

always @(posedge clk) begin
    if(~rst_n) begin
        {ages[0], elements[0]} <= {2'b00, 18'b0};
    end else if(rst) begin
        {ages[0], elements[0]} <= {2'b00, 18'b0};
    end else if(~en) begin
    end else if(comp_element == 0) begin
        {ages[0], elements[0]} <= {new_time_stamp, new_element};
    end else if(decay_element == 0 && comp_element > 0) begin
        {ages[0], elements[0]} <= {ages[1], elements[1]};
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        {ages[1], elements[1]} <= {2'b00, 18'b0};
    end else if(rst) begin
        {ages[1], elements[1]} <= {2'b00, 18'b0};
    end else if(~en) begin
    end else if(comp_element == 1) begin
        {ages[1], elements[1]} <= {new_time_stamp, new_element};
    end else if(decay_element <= 1 && comp_element > 1) begin
        {ages[1], elements[1]} <= {ages[2], elements[2]};
    end else if(comp_element < 1 && decay_element >= 1) begin
        {ages[1], elements[1]} <= {ages[0], elements[0]};
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        {ages[2], elements[2]} <= {2'b00, 18'b0};
    end else if(rst) begin
        {ages[2], elements[2]} <= {2'b00, 18'b0};
    end else if(~en) begin
    end else if(comp_element == 2) begin
        {ages[2], elements[2]} <= {new_time_stamp, new_element};
    end else if(decay_element <= 2 && comp_element > 2) begin
        {ages[2], elements[2]} <= {ages[3], elements[3]};
    end else if(comp_element < 2 && decay_element >= 2) begin
        {ages[2], elements[2]} <= {ages[1], elements[1]};
    end
end

always @(posedge clk) begin
    if(~rst_n) begin
        {ages[3], elements[3]} <= {2'b00, 18'b0};
    end else if(rst) begin
        {ages[3], elements[3]} <= {2'b00, 18'b0};
    end else if(~en) begin
    end else if(comp_element == 3) begin
        {ages[3], elements[3]} <= {new_time_stamp, new_element};
    end else if(comp_element < 3 && decay_element == 3) begin
        {ages[3], elements[3]} <= {ages[2], elements[2]};
    end
end

end endgenerate

endmodule