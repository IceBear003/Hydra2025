module storage(
    input clk,
    input rst_n,

    input wr_en,
    input [17:0] wr_data,

    input rd_en,
    output [17:0] rd_data
);

reg [17:0] data [2:0];

always @(posedge clk) begin
    if(~rst_n) begin
        data[0] <= 0;
        data[1] <= 0;
        data[2] <= 0;
    end else if(wr_en) begin
        data[0] <= wr_data;
        data[1] <= data[0];
        data[2] <= data[1];
    end else if(rd_en) begin
        data[0] <= 0;
        data[1] <= data[0];
        data[2] <= data[1];
    end
end

assign rd_data = data[2];

endmodule