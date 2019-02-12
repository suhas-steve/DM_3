module hart_fsm (
    input  wire dbg_clk,
    input  wire dbg_resetn,

    // Debug / control inputs
    input  wire hartreset,
    input  wire haltreq,
    input  wire resumereq,
    input  wire resethaltreq,
    input  wire ebreak,

    // State outputs
    output reg  hart_running,
    output reg  hart_halted,
    output reg  hart_reset
);

	reg hartreset_r;
	reg haltreq_r;
	reg resumereq_r;
	reg resethaltreq_r;
	reg ebreak_r;

	always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin
			hartreset_r    <= 1'b0;
			haltreq_r	   <= 1'b0;
			resumereq_r	   <= 1'b0;
			resethaltreq_r <= 1'b0;
			ebreak_r	   <= 1'b0;	
		end
		else begin
			hartreset_r    <= hartreset;
			haltreq_r	   <= haltreq;
			resumereq_r	   <= resumereq;
			resethaltreq_r <= resethaltreq;
			ebreak_r	   <= ebreak;
		end
	end

	

    // --------------------------------------------------
    // State encoding
    // --------------------------------------------------
   
    parameter [1:0] RUNNING=2'b00,
                    HALTED =2'b01,
                    RESET  =2'b10;

   reg [1:0] present_state, next_state;

    // --------------------------------------------------
    // State register
    // --------------------------------------------------
    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn)
            present_state <= RESET;
        else
            present_state <= next_state;
    end

    // --------------------------------------------------
    // Next-state logic
    // --------------------------------------------------
    always @(present_state, hartreset_r, haltreq_r, ebreak_r, resumereq_r, resethaltreq_r) begin
        next_state = present_state;

        case (present_state)

            // ---------------- RUNNING ----------------
            RUNNING: begin
                if (hartreset_r)
                    next_state = RESET;
                else if (haltreq_r || ebreak_r )
                    next_state = HALTED;
            end

            // ---------------- HALTED ----------------
            HALTED: begin
                if (hartreset_r)
                    next_state = RESET;
                else if (resumereq_r && !haltreq_r)
                    next_state = RUNNING;
            end

            // ---------------- RESET ----------------
            RESET: begin
            if (!hartreset_r)begin
                    
                    if (resethaltreq_r || haltreq_r)
                        next_state = HALTED;
                
                    else 
                        next_state = RUNNING;
                    end
            end

            default: next_state = RESET;
        endcase
    end

    // --------------------------------------------------
    // Output decode
    // --------------------------------------------------
    always @(present_state) begin
        hart_running = 1'b0;
        hart_halted  = 1'b0;
        hart_reset   = 1'b0;

        case (present_state)
            RUNNING: hart_running = 1'b1;
            HALTED : hart_halted  = 1'b1;
            RESET  : hart_reset   = 1'b1;
        endcase
    end

endmodule




