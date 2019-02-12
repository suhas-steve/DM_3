module DM_ace (

    input               dbg_clk,
    input               dbg_resetn,

    // ---------------------------------------------------------
    // Command interface
    // ---------------------------------------------------------
    input               cmd_write_pulse,
    input      [31:0]   command,

    // ---------------------------------------------------------
    // Data registers from DM regfile
    // data0 used for read/write transfer
    // ---------------------------------------------------------
    input  [31:0] data0,
	input  [31:0] data1,
	input  [31:0] data2,
	input  [31:0] data3,
	input  [31:0] data4,
	input  [31:0] data5,
	input  [31:0] data6,
	input  [31:0] data7,
	input  [31:0] data8,
    input  [31:0] data9,
    input  [31:0] data10,
	input  [31:0] data11,

    // ---------------------------------------------------------
    // Hart state
    // ---------------------------------------------------------
    input               hart_halted,

    // ---------------------------------------------------------
    // Program buffer handshake
    // ---------------------------------------------------------
    input               pb_done,
    output reg          execute_progbuf,

    // ---------------------------------------------------------
    // cmderr clear pulse from DM regfile
    // ---------------------------------------------------------
    input               clear_cmderr,

    // ---------------------------------------------------------
    // Direct CPU register access interface
    // ---------------------------------------------------------
    output reg          dbg_reg_read,
    output reg          dbg_reg_write,
    output reg [15:0]   dbg_reg_addr,
    output reg [31:0]   dbg_reg_wdata,

    input      [31:0]   dbg_reg_rdata,
    input               dbg_reg_ready,

    // ---------------------------------------------------------
    // Status
    // ---------------------------------------------------------
    output reg          abstract_busy,
    output     [2:0]    abstract_cmderr,

	output reg [31:0] ace_data_wdata,
	output reg [3:0]  ace_data_index,
	output reg        ace_data_write

);

    // =========================================================
    // Registered Inputs
    // =========================================================

    reg [31:0] command_r;
    reg        hart_halted_r;
    reg        pb_done_r;
    reg        cmd_write_pulse_r;
    reg        cmd_write_pulse_d;

    reg [31:0]   dbg_reg_rdata_r;
    reg          dbg_reg_ready_r;

reg  [31:0] data0_r;
reg  [31:0] data1_r;
reg  [31:0] data2_r;
reg  [31:0] data3_r;
reg  [31:0] data4_r;
reg  [31:0] data5_r;
reg  [31:0] data6_r;
reg  [31:0] data7_r;
reg  [31:0] data8_r;
reg  [31:0] data9_r;
reg  [31:0] data10_r;
reg  [31:0] data11_r;

    always @(posedge dbg_clk or negedge dbg_resetn) begin

        if (!dbg_resetn) begin

            command_r           <= 32'h0;
            hart_halted_r       <= 1'b0;
            pb_done_r           <= 1'b0;

            cmd_write_pulse_r   <= 1'b0;
            cmd_write_pulse_d   <= 1'b0; 

			data0_r				<= 1'b0;
			data1_r				<= 1'b0;
			data2_r				<= 1'b0;
			data3_r				<= 1'b0;
			data4_r				<= 1'b0;
			data5_r				<= 1'b0;
			data6_r				<= 1'b0;
			data7_r				<= 1'b0;
			data8_r				<= 1'b0;
			data9_r				<= 1'b0;
			data10_r			<= 1'b0;
			data11_r			<= 1'b0;

            dbg_reg_rdata_r      <= 32'h0;
            dbg_reg_ready_r      <= 2'b0;
        end
        else begin

            command_r           <= command;
            hart_halted_r       <= hart_halted;
            pb_done_r           <= pb_done;

            cmd_write_pulse_r   <= cmd_write_pulse;
            cmd_write_pulse_d   <= cmd_write_pulse_r;

			data0_r				<= data0;
			data1_r				<= data1;
			data2_r				<= data2;
			data3_r				<= data3;
			data4_r				<= data4;
			data5_r				<= data5;
			data6_r				<= data6;
			data7_r				<= data7;
			data8_r				<= data8;
			data9_r				<= data9;
			data10_r			<= data10;
			data11_r			<= data11;

            dbg_reg_rdata_r      <= dbg_reg_rdata;
            dbg_reg_ready_r      <= dbg_reg_ready;
        end
    end

    // =========================================================
    // Edge Detect
    // =========================================================

    wire cmd_write_edge;

    assign cmd_write_edge =
            cmd_write_pulse_r &
           ~cmd_write_pulse_d;

    // =========================================================
    // Abstract Command Decode
    // =========================================================

    parameter cmdtype_access_reg = 8'h00;

    wire [7:0]  cmdtype;
    wire        transfer;
    wire        write_cmd;
    wire        postexec;
    wire [15:0] regno;

    assign cmdtype   = command_r[31:24];
    assign postexec  = command_r[18];
    assign transfer  = command_r[17];
    assign write_cmd = command_r[16];
    assign regno     = command_r[15:0];

    // =========================================================
    // cmderr
    // =========================================================

    reg [2:0] abstract_cmderr_r;

    assign abstract_cmderr = abstract_cmderr_r;

    // =========================================================
    // FSM States
    // =========================================================

    parameter st_idle        = 3'd0;
    parameter st_reg_read    = 3'd1;
    parameter st_reg_write   = 3'd2;
    parameter st_pb_exec     = 3'd3;
    parameter st_wait_pb     = 3'd4;

    reg [2:0] state;

    // =========================================================
    // Sequential FSM
    // =========================================================

    always @(posedge dbg_clk or negedge dbg_resetn) begin

        if (!dbg_resetn) begin

            state               <= st_idle;

            abstract_busy       <= 1'b0;
            abstract_cmderr_r   <= 3'b000;

            execute_progbuf     <= 1'b0;

            dbg_reg_read        <= 1'b0;
            dbg_reg_write       <= 1'b0;
            dbg_reg_addr        <= 16'h0;
            dbg_reg_wdata       <= 32'h0;

			ace_data_wdata <= 32'h0;
			ace_data_index <= 4'h0;
			ace_data_write <= 1'b0;

        end
        else begin

            // -------------------------------------------------
            // defaults
            // -------------------------------------------------

            execute_progbuf <= 1'b0;

            dbg_reg_read    <= 1'b0;
            dbg_reg_write   <= 1'b0;

			ace_data_write <= 1'b0;

            // -------------------------------------------------
            // cmderr clear
            // -------------------------------------------------

            if (clear_cmderr)
                abstract_cmderr_r <= 3'b000;

            // -------------------------------------------------
            // FSM
            // -------------------------------------------------

            case (state)

                // =============================================
                // IDLE
                // =============================================

                st_idle: begin

                    abstract_busy <= 1'b0;

                    if (cmd_write_edge) begin

                        // -------------------------------------
                        // Existing error
                        // -------------------------------------

                        if (abstract_cmderr_r != 3'b000) begin
                            state <= st_idle;
                        end

                        // -------------------------------------
                        // Unsupported command
                        // -------------------------------------

                        
                        // -------------------------------------
                        // Hart not halted
                        // -------------------------------------

                        else if (!hart_halted_r) begin

                            abstract_cmderr_r <= 3'b010;
                            state             <= st_idle;

                        end


                        else if (cmdtype != cmdtype_access_reg) begin

                            abstract_cmderr_r <= 3'b011;
                            state             <= st_idle;

                        end


                        // -------------------------------------
                        // no transfer , no pb execution
                        // -------------------------------------

                        else if((transfer == 1'b0) && (postexec == 1'b0)) begin
                            abstract_cmderr_r <= 3'b100;
                            state             <= st_idle;

                        end

                        // -------------------------------------
                        // Valid command
                        // -------------------------------------

                        else begin

                            abstract_busy <= 1'b1;

                            // ---------------------------------
                            // direct register transfer
                            // ---------------------------------

                            if (transfer) begin

                                dbg_reg_addr <= regno;

                                // -----------------------------
                                // WRITE register
                                // -----------------------------

                                if (write_cmd) begin

                                    dbg_reg_wdata <= data0_r;
                                    dbg_reg_write <= 1'b1;

                                    state <= st_reg_write;
                                end

                                // -----------------------------
                                // READ register
                                // -----------------------------

                                else begin

                                    dbg_reg_read <= 1'b1;

                                    state <= st_reg_read;
                                end
                            end

                            // ---------------------------------
                            // Program buffer execution
                            // ---------------------------------

                            else if (postexec) begin

                                execute_progbuf <= 1'b1;
                                state <= st_pb_exec;

                            end

                            else begin

                                abstract_busy <= 1'b0;
                                state <= st_idle;

                            end
                        end
                    end
                end

                // =============================================
                // DIRECT REGISTER READ
                // =============================================

                st_reg_read: begin

                    abstract_busy <= 1'b1;

                    if(cmd_write_edge) begin
                        abstract_cmderr_r <= 3'b001; //busy violation
                    end

                    if (dbg_reg_ready_r) begin

					ace_data_wdata <= dbg_reg_rdata_r;
					ace_data_index <= 4'd0;
					ace_data_write <= 1'b1;
				
			// optional PB execution after transfer
                        if (postexec) begin

                            execute_progbuf <= 1'b1;

                            state <= st_pb_exec;
                        end
                        else begin

                            abstract_busy <= 1'b0;

                            state <= st_idle;
                        end
                    end
                end

                // =============================================
                // DIRECT REGISTER WRITE
                // =============================================

                st_reg_write: begin

                    abstract_busy <= 1'b1;

                    if(cmd_write_edge) begin
                        abstract_cmderr_r <= 3'b001; //busy violation
                    end

                        // optional PB execution after transfer
                        if (postexec) begin

                            execute_progbuf <= 1'b1;

                            state <= st_pb_exec;
                        end
                        else begin

                            abstract_busy <= 1'b0;

                            state <= st_idle;
                        end
                end

                // =============================================
                // PROGRAM BUFFER EXECUTE
                // =============================================

                st_pb_exec: begin

                    abstract_busy <= 1'b1;

                    state <= st_wait_pb;
                end

                // =============================================
                // WAIT FOR PB DONE
                // =============================================

                st_wait_pb: begin

                    abstract_busy <= 1'b1;

                    if(cmd_write_edge) begin
                        abstract_cmderr_r <= 3'b001; //busy violation
                    end


                    if (pb_done_r) begin

                        abstract_busy <= 1'b0;

                        state <= st_idle;
                    end
                end

                // =============================================
                // DEFAULT
                // =============================================

                default: begin

                    state <= st_idle;

                    abstract_busy <= 1'b0;
                end

            endcase
        end
    end

endmodule

