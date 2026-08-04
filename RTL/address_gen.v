module address_gen #
(
    parameter ADDR_WIDTH = 8,
    parameter MAX_SEGMENTS = 100,
    parameter OUTPUTS_PER_SEGMENT = 2
)
(
    input  wire clk,
    input  wire rst_n,

    input  wire partial_valid,
    input  wire segment_step,

    input  wire initial_mode,
    input  wire accumulate_mode,

    input  wire reverse_direction,
    
    input  wire next_range,
    input  wire phase_change,
    input  wire operation_done, 
    
    output reg [ADDR_WIDTH-1:0] output_addr_base,
    output reg [6:0] current_segment
);

localparam LAST_SEGMENT = MAX_SEGMENTS-1;

reg [ADDR_WIDTH-1:0] range_offset;
reg [6:0] max_segment; 

// --------------------------------------------------
// Max Segment Tracker
// --------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        max_segment <= 0;
    else if (operation_done || next_range) 
        max_segment <= 0;
    else if (current_segment > max_segment) 
        max_segment <= current_segment;
end

wire [6:0] effective_max = (current_segment > max_segment) ? current_segment : max_segment;

// --------------------------------------------------
// Main Logic
// --------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        current_segment <= 0;
        range_offset    <= 0;
    end
    else 
    begin
        if (partial_valid && operation_done) 
        begin
            current_segment <= 0;
            range_offset    <= 0;
        end
        else if(partial_valid && segment_step)
        begin
            if(next_range)
            begin
                current_segment <= 0;
                // fixed
                range_offset <= range_offset + ((effective_max + 1) << $clog2(OUTPUTS_PER_SEGMENT));
            end
            else if (phase_change)
            begin
                current_segment <= current_segment;
            end
            else if(initial_mode)
            begin
                if(current_segment != LAST_SEGMENT)
                    current_segment <= current_segment + 1;
            end
            else if(accumulate_mode)
            begin
                if(reverse_direction)
                begin
                    if(current_segment != 0)
                        current_segment <= current_segment - 1;
                end
                else
                begin
                    if(current_segment != LAST_SEGMENT)
                        current_segment <= current_segment + 1;
                end
            end
        end
    end
end

always @(*)
begin 
    output_addr_base = range_offset + (current_segment << $clog2(OUTPUTS_PER_SEGMENT));
end

endmodule