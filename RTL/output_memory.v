module output_memory #(parameter DATA_WIDTH=16,
OUTPUT_SIZE=8 ,ADDR_WIDTH=8 ,
PARTIAL_SIZE=4,MAX_SEGMENTS_PER_RANGE= 100,OUTPUTS_PER_SEGMENT= (PARTIAL_SIZE * PARTIAL_SIZE) / OUTPUT_SIZE,
MAX_WORDS = MAX_SEGMENTS_PER_RANGE * OUTPUTS_PER_SEGMENT
)(

input  								 clk,
input 								 write_enable ,
input [(OUTPUT_SIZE*DATA_WIDTH)-1:0] write_data,
input [ADDR_WIDTH-1:0]				 write_addr_out, 

input [ADDR_WIDTH-1:0]				 output_addr,

output [(OUTPUT_SIZE*DATA_WIDTH)-1:0]output_data,
output [(OUTPUT_SIZE*DATA_WIDTH)-1:0]old_word        

);

reg [(OUTPUT_SIZE*DATA_WIDTH)-1:0] mem [MAX_WORDS-1:0];

//read & write operation 
always @(posedge clk ) begin
	if (write_enable ) begin
		mem[write_addr_out]<=write_data;
	end
end
assign output_data = mem[output_addr];
assign old_word     = mem[write_addr_out];   
endmodule 