module dm_reset_ctrl (
    input  wire dbg_clk,
    input  wire dbg_resetn,

    // From dmcontrol register
    input  wire dmactive,     // dmcontrol.dmactive
    input  wire ndmreset,     // dmcontrol.ndmreset

    // Outputs
    output reg  dm_reset,     // Internal Debug Module reset
    output reg  hartreset    // Hart reset request (to CPU)
);
	
	reg dmactive_r;
	reg ndmreset_r;

	always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin
			dmactive_r <= 1'b0;
			ndmreset_r <= 1'b0;
		end 
		else begin
			dmactive_r <= dmactive;
			ndmreset_r <= ndmreset;
		end
	end
	


    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin
            // -------------------------------------------------
            // Case 1: Hardware Debug Reset
            // -------------------------------------------------
            // Reset Debug Module internal state
            dm_reset   <= 1'b1;

            // MUST NOT reset hart on debug reset
            hartreset <= 1'b0;

        end else begin
            // -------------------------------------------------
            // Case 2: Debug Module inactive (software reset)
            // -------------------------------------------------
            if (!dmactive_r) begin
                dm_reset <= 1'b1;   // Hold DM in reset
            end else begin
                dm_reset <= 1'b0;   // DM active
            end

            // -------------------------------------------------
            // Case 3: Hart reset request (explicit, pass-through)
            // -------------------------------------------------
            if (ndmreset_r && dmactive_r) begin
                hartreset <= 1'b1; // Request hart reset
            end else begin
                hartreset <= 1'b0;
            end
        end
    end

endmodule




