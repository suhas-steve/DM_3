module dm_reset_ctrl (
    input  wire dbg_clk,
    input  wire dbg_resetn,

    // From dmcontrol register
    input  wire dmactive,     // dmcontrol.dmactive

    // Outputs
    output reg  dm_reset     // Internal Debug Module reset
);
	
	reg dmactive_r;

	always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin
			dmactive_r <= 1'b0;
		end 
		else begin
			dmactive_r <= dmactive;
		end
	end
	


    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin
            // -------------------------------------------------
            // Case 1: Hardware Debug Reset
            // -------------------------------------------------
            // Reset Debug Module internal state
            dm_reset   <= 1'b1;

        end else begin
            // -------------------------------------------------
            // Case 2: Debug Module inactive (software reset)
            // -------------------------------------------------
            if (!dmactive_r) begin
                dm_reset <= 1'b1;   // Hold DM in reset
            end else begin
                dm_reset <= 1'b0;   // DM active
            end

        end
    end

endmodule




