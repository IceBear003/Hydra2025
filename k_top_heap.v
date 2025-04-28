module k_top_heap
#(
    parameter WIDTH = 20
)(
    input clk,
    input rst_n,

    input enable,
    input heap_type,//1:MAX 0:MIN
    input [3:0] k,  //k-th

    input [WIDTH-1:0] number,
    output [WIDTH-1:0] kth_number
);

reg [WIDTH-1:0] heap [7:0];

wire comp [8:0];
assign comp[8] = 1'b0;

genvar i;
generate for(i = 0; i < 8; i = i + 1) begin: heap_regs
    wire [19:0] value = heap[i];
    assign comp[i] = ~heap_type ^ (number > heap[i]);

    always @(posedge clk) begin
        if(~rst_n) begin
            heap[i] <= {WIDTH{heap_type ^ (i < k)}};
        end else if(~enable) begin    
        end else if(i >= k) begin
        end else if(~comp[i]) begin
        end else if(comp[i+1]) begin
            heap[i] <= heap[i+1];
        end else begin
            heap[i] <= number;
        end
    end
end endgenerate

assign kth_number = heap[0];

endmodule