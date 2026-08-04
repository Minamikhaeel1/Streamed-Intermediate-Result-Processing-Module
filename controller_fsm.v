module controller_fsm (
    input  wire clk,
    input  wire rst_n,

    // Control inputs from computation engine
    input  wire partial_valid,
    input  wire segment_step,
    input  wire phase_change,
    input  wire next_range,
    input  wire operation_done,

    // Asserted by datapath when all remaining outputs are finalized
    input  wire internal_done,

    // FSM outputs
    output reg  initial_mode,
    output reg  accumulate_mode,
    output reg  reverse_direction
);

    // State Encoding
    localparam IDLE       = 2'd0;
    localparam INITIAL    = 2'd1;
    localparam ACCUMULATE = 2'd2;
    localparam COMPLETE   = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;

    // State Register
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next State Logic
    always @(*)
    begin
        next_state = state;

        case(state)

        //-----------------------------------------------------
        IDLE:
        begin
            if(partial_valid)
                next_state = INITIAL;
        end

        //-----------------------------------------------------
        INITIAL:
        begin
            if(partial_valid)
            begin
                if(operation_done)
                    next_state = COMPLETE;

                else if(next_range)
                    next_state = INITIAL;

                else if(phase_change)
                    next_state = ACCUMULATE;

                else
                    next_state = INITIAL;
            end
        end

        //-----------------------------------------------------
        ACCUMULATE:
        begin
            if(partial_valid)
            begin
                if(operation_done)
                    next_state = COMPLETE;

                else if(next_range)
                    next_state = INITIAL;

                else
                    next_state = ACCUMULATE;
            end
        end

        //-----------------------------------------------------
        COMPLETE:
        begin
            if(internal_done)
                next_state = IDLE;
            else
                next_state = COMPLETE;
        end

        default:
            next_state = IDLE;

        endcase
    end

    // reversal Direction
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            reverse_direction <= 1'b0;
        end
        else
        begin
            case(state)

            IDLE:
                reverse_direction <= 1'b0;

            INITIAL:
            begin
                if(partial_valid && phase_change)
                    reverse_direction <= 1'b1;
            end

            ACCUMULATE:
            begin
                if(partial_valid)
				begin
					if(next_range)
						reverse_direction <= 1'b0;

					else if(phase_change)
						reverse_direction <= ~reverse_direction;
	
				end
            end

            //---------------------------------------------
            COMPLETE:
                reverse_direction <= reverse_direction;

            endcase
        end
    end

    // Output Logic
    always @(*)
    begin

        initial_mode       = 1'b0;
        accumulate_mode    = 1'b0;

        case(state)

        IDLE:
        begin
		accumulate_mode    = 1'b0;
			if (partial_valid)
                initial_mode = 1'b1;
            else
                initial_mode = 1'b0;
        end

        INITIAL:
        begin
            initial_mode    = 1'b1;
        end

        ACCUMULATE:
        begin
            accumulate_mode = 1'b1;
        end

        COMPLETE:
        begin
			initial_mode       = 1'b0;
			accumulate_mode    = 1'b0;
        end

        endcase
    end

endmodule