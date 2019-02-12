module dm_program_buffer (
    input            dbg_clk,
    input            dbg_resetn,

    input [31:0]     progbuf0,
    input [31:0]     progbuf1,
    input [31:0]     progbuf2,
    input [31:0]     progbuf3,
    input [31:0]     progbuf4,
    input [31:0]     progbuf5,
    input [31:0]     progbuf6,
    input [31:0]     progbuf7,
    input [31:0]     progbuf8,
    input [31:0]     progbuf9,
    input [31:0]     progbuf10,
    input [31:0]     progbuf11,
    input [31:0]     progbuf12,
    input [31:0]     progbuf13,
    input [31:0]     progbuf14,
    input [31:0]     progbuf15,

    input            execute_progbuf,
    input            hart_halted,

    output reg [31:0] pb_insn,
    output reg        pb_insn_valid,
    output reg        pb_done
);

	reg [31:0]     progbuf0_r;
    reg [31:0]     progbuf1_r;
    reg [31:0]     progbuf2_r;
    reg [31:0]     progbuf3_r;
    reg [31:0]     progbuf4_r;
    reg [31:0]     progbuf5_r;
    reg [31:0]     progbuf6_r;
    reg [31:0]     progbuf7_r;
    reg [31:0]     progbuf8_r;
    reg [31:0]     progbuf9_r;
    reg [31:0]     progbuf10_r;
    reg [31:0]     progbuf11_r;
    reg [31:0]     progbuf12_r;
    reg [31:0]     progbuf13_r;
    reg [31:0]     progbuf14_r;
    reg [31:0]     progbuf15_r;
    reg            execute_progbuf_r;
    reg            hart_halted_r;

	always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin
			progbuf0_r 		<= 32'h0;
    		progbuf1_r		<= 32'h0;
    		progbuf2_r		<= 32'h0;
    		progbuf3_r		<= 32'h0;
    		progbuf4_r		<= 32'h0;
    		progbuf5_r		<= 32'h0;
    		progbuf6_r		<= 32'h0;
    		progbuf7_r		<= 32'h0;
    		progbuf8_r		<= 32'h0;
    		progbuf9_r		<= 32'h0;
    		progbuf10_r		<= 32'h0;
    		progbuf11_r		<= 32'h0;
    		progbuf12_r		<= 32'h0;
    		progbuf13_r		<= 32'h0;
    		progbuf14_r		<= 32'h0;
    		progbuf15_r		<= 32'h0;
    		execute_progbuf_r <=  1'b0;
    		hart_halted_r	<= 	1'b0;
		end
		else begin
			progbuf0_r 		<= progbuf0;
    		progbuf1_r		<= progbuf1;
    		progbuf2_r		<= progbuf2;
    		progbuf3_r		<= progbuf3;
    		progbuf4_r		<= progbuf4;
    		progbuf5_r		<= progbuf5;
    		progbuf6_r		<= progbuf6;
    		progbuf7_r		<= progbuf7;
    		progbuf8_r		<= progbuf8;
    		progbuf9_r		<= progbuf9;
    		progbuf10_r		<= progbuf10;
    		progbuf11_r		<= progbuf11;
    		progbuf12_r		<= progbuf12;
    		progbuf13_r		<= progbuf13;
    		progbuf14_r		<= progbuf14;
    		progbuf15_r		<= progbuf15;
    		execute_progbuf_r <=  execute_progbuf;
    		hart_halted_r	<= 	hart_halted;
		end
	end


    parameter ebreak_insn = 32'h0010_0073;

    reg [3:0] pc;
    reg       running;

    reg [31:0] current_insn;

    always @(pc, progbuf0_r, progbuf1_r, progbuf2_r, progbuf3_r, progbuf4_r, progbuf5_r, progbuf6_r, progbuf7_r, progbuf8_r, progbuf9_r, progbuf10_r, progbuf11_r, progbuf12_r, progbuf13_r, progbuf14_r, progbuf15_r) begin
        case (pc)
            4'd0:  current_insn = progbuf0_r;
            4'd1:  current_insn = progbuf1_r;
            4'd2:  current_insn = progbuf2_r;
            4'd3:  current_insn = progbuf3_r;
            4'd4:  current_insn = progbuf4_r;
            4'd5:  current_insn = progbuf5_r;
            4'd6:  current_insn = progbuf6_r;
            4'd7:  current_insn = progbuf7_r;
            4'd8:  current_insn = progbuf8_r;
            4'd9:  current_insn = progbuf9_r;
            4'd10: current_insn = progbuf10_r;
            4'd11: current_insn = progbuf11_r;
            4'd12: current_insn = progbuf12_r;
            4'd13: current_insn = progbuf13_r;
            4'd14: current_insn = progbuf14_r;
            4'd15: current_insn = progbuf15_r;
/*            default: begin
			 	 current_insn = 32'h0;
			end
*/
        endcase
    end

    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin
            pc             <= 4'd0;
            running        <= 1'b0;
            pb_insn        <= 32'h0;
            pb_insn_valid  <= 1'b0;
            pb_done        <= 1'b0;
        end else begin
            pb_done <= 1'b0;

            /* start execution */
            if (execute_progbuf_r && hart_halted_r) begin
                running       <= 1'b1;
                pc            <= 4'd0;
                pb_insn_valid <= 1'b1;
            end

            /* execution in progress */
            else if (running) begin
                pb_insn       <= current_insn;
                pb_insn_valid <= 1'b1;

                if (current_insn == ebreak_insn || pc == 4'd15) begin
                    running        <= 1'b0;
                    pb_insn_valid  <= 1'b0;
                    pb_done        <= 1'b1;
                end else begin
                    pc <= pc + 4'd1;
                end
            end

            /* idle */
            else begin
                pb_insn_valid <= 1'b0;
            end
        end
    end

endmodule




