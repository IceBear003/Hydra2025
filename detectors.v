module detectors(
    input clk,
    input rst_n,

    input en,

    input [3*18-1:0] summations,
    input [6*18-1:0] elements,

    output reg [5:0] target_detected
);

genvar index;
generate for(index = 0; index < 3; index = index + 1) begin: Detector

wire [18:0] left_element = {1'b0, elements[index*36+35:index*36+18]};
wire [18:0] right_element = {1'b0, elements[index*36+17:index*36]};
wire [17:0] summation = summations[index*18+17:index*18];

wire [4:0] threshold_exp = summation[17:14] + 2;
wire [13:0] threshold_man = summation[13:0];
wire [18:0] threshold = {threshold_exp, threshold_man};

always @(posedge clk) begin
    if(~rst_n) begin
        target_detected[2*index] <= 0;
        target_detected[2*index+1] <= 0;
    end else if(en) begin
        target_detected[2*index] <= left_element > threshold;
        target_detected[2*index+1] <= right_element > threshold;
    end else begin 
        target_detected[2*index] <= 0;
        target_detected[2*index+1] <= 0;
    end
end

end endgenerate

endmodule