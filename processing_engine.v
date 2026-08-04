module processing_engine
#(
    parameter DATA_WIDTH          = 16,
    parameter PARTIAL_SIZE        = 4,
    parameter OUTPUT_SIZE         = 8,
    parameter ADDR_WIDTH          = 8,
    parameter PARTIALS_PER_OUTPUT = OUTPUT_SIZE / PARTIAL_SIZE
)
(
    input  wire clk,
    input  wire rst_n,

    // From Stream Receiver
    input  wire partial_valid,
    input  wire [PARTIAL_SIZE*DATA_WIDTH-1:0] partial_data,

    // From Processing Controller
    input  wire initial_mode,
    input  wire [ADDR_WIDTH-1:0] write_addr,

    // From Output Memory
    input  wire [OUTPUT_SIZE*DATA_WIDTH-1:0] old_word,

    // To Output Memory
    output reg                           write_enable,
    output reg [ADDR_WIDTH-1:0]          write_addr_out,
    output reg [OUTPUT_SIZE*DATA_WIDTH-1:0] write_data
);

// Internal Registers for State
reg [$clog2(PARTIALS_PER_OUTPUT)-1:0] partial_index;
reg [PARTIAL_SIZE*DATA_WIDTH-1:0] first_partial;
reg word_in_segment;

wire [OUTPUT_SIZE*DATA_WIDTH-1:0] output_word;
assign output_word = {partial_data, first_partial};

// Combinational Address for Memory Read
wire [ADDR_WIDTH-1:0] next_write_addr;
assign next_write_addr = (word_in_segment == 1'b0) ? write_addr : (write_addr + 1'b1);

// Element-wise Accumulation
wire [OUTPUT_SIZE*DATA_WIDTH-1:0] accumulated_word;
genvar i;
generate
    for(i=0; i<OUTPUT_SIZE; i=i+1)
    begin : ACC
        assign accumulated_word[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] =
               old_word[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]
             + output_word[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
    end
endgenerate

// Combinational Outputs to Memory
always @(*)
begin
    write_addr_out = next_write_addr;
    write_enable   = 1'b0;
    write_data     = {OUTPUT_SIZE*DATA_WIDTH{1'b0}};

    if(partial_valid && partial_index == 1'b1)
    begin
        write_enable = 1'b1;
        if(initial_mode)
            write_data = output_word;
        else
            write_data = accumulated_word;
    end
end

// Sequential State Updates
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        partial_index   <= 0;
        first_partial   <= 0;
        word_in_segment <= 1'b0;
    end
    else
    begin
        if(partial_valid)
        begin
            if(partial_index == 0)
            begin
                first_partial <= partial_data;
                partial_index <= 1'b1;
            end
            else
            begin
                partial_index   <= 0;
                word_in_segment <= ~word_in_segment;
            end
        end
    end
end

endmodule