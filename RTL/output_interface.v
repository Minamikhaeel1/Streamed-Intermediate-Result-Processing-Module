module output_interface #( parameter DATA_WIDTH=16 , OUTPUT_SIZE=8,ADDR_WIDTH=8)
(
input  [(OUTPUT_SIZE*DATA_WIDTH)-1:0] mem_data,
input                                 addr_finalized,  
input  [ADDR_WIDTH-1:0]               output_addr_req, 
    
       
output      [ADDR_WIDTH-1:0]               output_addr,
output reg                                 output_valid,
output reg  [(OUTPUT_SIZE*DATA_WIDTH)-1:0] output_data
);

    assign output_addr = output_addr_req;

    always @(*) begin
       
        if (addr_finalized) begin
            output_valid = 1'b1;
            output_data  = mem_data;
        end else begin
            output_valid = 1'b0;
            output_data  = 0;
        end
    end

endmodule