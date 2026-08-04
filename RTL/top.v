module top_processing_module #(
    // Configuration Parameters matching Section 3 of the Specs
    parameter DATA_WIDTH             = 16,
    parameter PARTIAL_SIZE           = 4,
    parameter OUTPUT_SIZE            = 8,
    parameter ADDR_WIDTH             = 8,
    parameter MAX_SEGMENTS_PER_RANGE = 100
)
(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Input Stream Interface
    input  wire                                 partial_valid,
    input  wire [(PARTIAL_SIZE*DATA_WIDTH)-1:0] partial_data,
    input  wire                                 segment_step,
    input  wire                                 phase_change,
    input  wire                                 next_range,
    input  wire                                 operation_done,

    // Output Interface
    input  wire [ADDR_WIDTH-1:0]                output_addr,
    output wire                                 output_valid,
    output wire [(OUTPUT_SIZE*DATA_WIDTH)-1:0]  output_data
);

    // =========================================================================
    // Internal Derived Parameters
    // =========================================================================
    localparam OUTPUTS_PER_SEGMENT = (PARTIAL_SIZE * PARTIAL_SIZE) / OUTPUT_SIZE; 
    localparam MAX_WORDS = MAX_SEGMENTS_PER_RANGE * OUTPUTS_PER_SEGMENT;

    // =========================================================================
    // Internal Interconnect Wires
    // =========================================================================

    // From controller_fsm
    wire initial_mode;
    wire accumulate_mode;
    wire reverse_direction;

    // From address_manager
    wire internal_done;
    wire addr_finalized;

    // From address_gen
    wire [ADDR_WIDTH-1:0] output_addr_base;
    wire [6:0]            current_segment; 

    // From processing_engine
    wire                                write_enable;
    wire [ADDR_WIDTH-1:0]               write_addr_out;
    wire [(OUTPUT_SIZE*DATA_WIDTH)-1:0] write_data;

    // From output_memory
    wire [(OUTPUT_SIZE*DATA_WIDTH)-1:0] mem_data_out;
    wire [(OUTPUT_SIZE*DATA_WIDTH)-1:0] old_word;

    // =========================================================================
    // Module Instantiations
    // =========================================================================

    // 1. Controller FSM
    controller_fsm u_controller_fsm (
        .clk                (clk),
        .rst_n              (rst_n),
        .partial_valid      (partial_valid),
        .segment_step       (segment_step),
        .phase_change       (phase_change),
        .next_range         (next_range),
        .operation_done     (operation_done),
        .internal_done      (internal_done),      // Unlocks the FSM from COMPLETE state
        .initial_mode       (initial_mode),
        .accumulate_mode    (accumulate_mode),
        .reverse_direction  (reverse_direction)
    );

    // 2. Address Generator
    address_gen #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .MAX_SEGMENTS       (MAX_SEGMENTS_PER_RANGE),
        .OUTPUTS_PER_SEGMENT(OUTPUTS_PER_SEGMENT)
    ) u_address_gen (
        .clk                (clk),
        .rst_n              (rst_n),
        .partial_valid      (partial_valid),
        .segment_step       (segment_step),
        .initial_mode       (initial_mode),
        .accumulate_mode    (accumulate_mode),
        .reverse_direction  (reverse_direction),
        .next_range         (next_range),
        .phase_change       (phase_change),
        .operation_done     (operation_done),
        .output_addr_base   (output_addr_base),
        .current_segment    (current_segment)
    );

    // 3. Processing Engine
    processing_engine #(
        .DATA_WIDTH         (DATA_WIDTH),
        .PARTIAL_SIZE       (PARTIAL_SIZE),
        .OUTPUT_SIZE        (OUTPUT_SIZE),
        .ADDR_WIDTH         (ADDR_WIDTH)
    ) u_processing_engine (
        .clk                (clk),
        .rst_n              (rst_n),
        .partial_valid      (partial_valid),
        .partial_data       (partial_data),
        .initial_mode       (initial_mode),
        .write_addr         (output_addr_base),
        .old_word           (old_word),           // Combinational read data for accumulation
        .write_enable       (write_enable),
        .write_addr_out     (write_addr_out),
        .write_data         (write_data)
    );

    // 4. Output Memory
    output_memory #(
        .DATA_WIDTH             (DATA_WIDTH),
        .OUTPUT_SIZE            (OUTPUT_SIZE),
        .ADDR_WIDTH             (ADDR_WIDTH),
        .PARTIAL_SIZE           (PARTIAL_SIZE),
        .MAX_SEGMENTS_PER_RANGE (MAX_SEGMENTS_PER_RANGE),
        .OUTPUTS_PER_SEGMENT    (OUTPUTS_PER_SEGMENT),
        .MAX_WORDS              (MAX_WORDS)
    ) u_output_memory (
        .clk                (clk),
        .write_enable       (write_enable),
        .write_data         (write_data),
        .write_addr_out     (write_addr_out),
        .output_addr        (output_addr),        // Request from downstream
        .output_data        (mem_data_out),
        .old_word           (old_word)            // Combinational read port for engine
    );

    // 5. Address Manager
    address_manager #(
        .DATA_WIDTH             (DATA_WIDTH),
        .OUTPUT_SIZE            (OUTPUT_SIZE),
        .ADDR_WIDTH             (ADDR_WIDTH),
        .PARTIAL_SIZE           (PARTIAL_SIZE),
        .MAX_SEGMENTS_PER_RANGE (MAX_SEGMENTS_PER_RANGE),
        .OUTPUTS_PER_SEGMENT    (OUTPUTS_PER_SEGMENT),
        .MAX_WORDS              (MAX_WORDS)
    ) u_address_manager (
        .clk                (clk),
        .rst_n              (rst_n),
        .word_finalized     (write_enable),       // Pules exactly when datapath commits a word
        .operation_done     (operation_done),
        .next_range         (next_range),
        .output_addr        (output_addr),
        .output_addr_base   (output_addr_base),   // To latch target_count correctly
        .addr_finalized     (addr_finalized),
        .internal_done      (internal_done)       // Tells FSM everything is flushed
    );

    // 6. Output Interface
    output_interface #(
        .DATA_WIDTH         (DATA_WIDTH),
        .OUTPUT_SIZE        (OUTPUT_SIZE),
        .ADDR_WIDTH         (ADDR_WIDTH)
    ) u_output_interface (
        .mem_data           (mem_data_out),
        .addr_finalized     (addr_finalized),
        .output_addr_req    (output_addr),
        .output_addr        (),                 
        .output_valid       (output_valid),
        .output_data        (output_data)
    );

endmodule