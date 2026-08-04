module address_manager #(
    parameter DATA_WIDTH             = 16,
    parameter OUTPUT_SIZE            = 8,
    parameter ADDR_WIDTH             = 8,
    parameter PARTIAL_SIZE           = 4,
    parameter MAX_SEGMENTS_PER_RANGE = 100,
    parameter OUTPUTS_PER_SEGMENT    = 2,
    parameter MAX_WORDS              = MAX_SEGMENTS_PER_RANGE * OUTPUTS_PER_SEGMENT
)(
    input                          clk,
    input                          rst_n,
    input                          word_finalized,  
    input                          operation_done,
    input                          next_range,       
    input         [ADDR_WIDTH-1:0] output_addr,
    input         [ADDR_WIDTH-1:0] output_addr_base, 

    output reg                     addr_finalized,  
    output reg                     internal_done     
);

reg [ADDR_WIDTH-1:0] finalized_addr;
reg                  finalized_data; 
reg [ADDR_WIDTH-1:0] max_target;

wire [ADDR_WIDTH-1:0] current_target = output_addr_base + OUTPUTS_PER_SEGMENT;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        finalized_addr <= {ADDR_WIDTH{1'b0}};       
        finalized_data <= 1'b0;
        internal_done  <= 1'b0;
        max_target     <= {ADDR_WIDTH{1'b0}};
    end
    else begin
        internal_done <= 1'b0; 

        if (operation_done || next_range) begin
            max_target <= 0; 
        end
        else if (word_finalized && (current_target > max_target)) begin
            max_target <= current_target;
        end

        if (operation_done || next_range) begin
            
            if (word_finalized && (current_target > max_target))
                finalized_addr <= current_target;
            else
                finalized_addr <= max_target;
                
            finalized_data <= 1'b1;
            
            if (operation_done) begin
                internal_done <= 1'b1; 
            end
        end
    end
end

// Combinational Validity Check
always @(*) begin
    if (finalized_data && (output_addr < finalized_addr)) begin
        addr_finalized = 1'b1;
    end else begin
        addr_finalized = 1'b0;
    end
end

endmodule