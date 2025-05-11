module os #(parameter WIDTH = 20)
(
    input clk,
    input rst_n,

    input enable,
    input [1:0] k,
    input [1:0] new_age,
    input [WIDTH-1:0] number,

    output [WIDTH-1:0] os_result
);

reg [WIDTH-1:0] regs [3:0];
reg [1:0] age [3:0];
wire [WIDTH+1:0] heap [5:0];
assign heap[0] = {age[3], regs[3]};
assign heap[1] = {age[0], regs[0]};
assign heap[2] = {age[1], regs[1]};
assign heap[3] = {age[2], regs[2]};
assign heap[4] = {age[3], regs[3]};
assign heap[5] = {age[0], regs[0]};

wire [3:0] comp;
reg [1:0] insert_idx;
always @(*) begin
    if(comp[3]) begin 
        insert_idx = 2'b11;
    end else if(comp[2]) begin 
        insert_idx = 2'b10;
    end else if(comp[1]) begin 
        insert_idx = 2'b01;
    end else begin 
        insert_idx = 2'b00;
    end 
end

wire [3:0] old;
reg [1:0] remove_idx;
always @(*) begin
    if(old[3]) begin 
        remove_idx = 2'b11;
    end else if(old[2]) begin 
        remove_idx = 2'b10;
    end else if(old[1]) begin 
        remove_idx = 2'b01;
    end else begin 
        remove_idx = 2'b00;
    end 
end

genvar i;
generate for(i = 0; i < 4; i = i + 1) begin: heap_regs
    assign comp[i] = heap[i] <= number;
    assign old[i] = &(age[i] | new_age);

    always @(posedge clk) begin
        if(~rst_n) begin
            {age[i], regs[i]} <= 0;
        end else if(~enable) begin
        end else if(i == insert_idx) begin
            {age[i], regs[i]} <= {new_age, number};
        end else if(i >= remove_idx && i < insert_idx) begin
            {age[i], regs[i]} <= heap[i+2];
        end else if(i > insert_idx && i <= remove_idx) begin
            {age[i], regs[i]} <= heap[i];
        end
    end
end endgenerate

assign os_result = regs[k];

endmodule