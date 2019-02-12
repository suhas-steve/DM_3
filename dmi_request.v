module dmi_request (

    input  wire        dbg_clk,
    input  wire        dbg_resetn,

    // ---------------------------------------------------------
    // Request from DTM CDC
    // ---------------------------------------------------------

    input  wire        dmi_req_pulse,
    input  wire [6:0]  dmi_req_addr_in,
    input  wire [31:0] dmi_req_data_in,
    input  wire [1:0]  dmi_req_op_in,

    // ---------------------------------------------------------
    // Response from DM Register File 
    // ---------------------------------------------------------

    input  wire        resp_valid,
    input  wire [31:0] resp_rdata,
    input  wire        resp_error,

    // ---------------------------------------------------------
    // Request toward DM and Addr decoder
    // ---------------------------------------------------------

    output reg         dmi_req_valid,
    output reg [1:0]   dmi_req_op,
    output reg [6:0]   dmi_req_addr,
    output reg [31:0]  dmi_req_wdata,

    // ---------------------------------------------------------
    // Response toward DTM CDC
    // ---------------------------------------------------------

    output reg         dmi_resp_valid,
    output reg [31:0]  dmi_resp_data,
    output reg [1:0]   dmi_resp_op,

    // ---------------------------------------------------------
    // DMI Busy
    // ---------------------------------------------------------

    output reg         dm_busy
);

    // =========================================================
    // DMI RESPONSE ENCODING
    // =========================================================

    parameter  STATE_IDLE      = 2'b00;
    parameter  STATE_WAIT_RESP = 2'b01;

    reg [1:0] state;

    // =========================================================
    // Input Registration
    // =========================================================

    reg        dmi_req_pulse_r;
    reg [6:0]  dmi_req_addr_in_r;
    reg [31:0] dmi_req_data_in_r;
    reg [1:0]  dmi_req_op_in_r;

    reg        resp_valid_r;
    reg [31:0] resp_rdata_r;
    reg        resp_error_r;

    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin

            dmi_req_pulse_r   <= 1'b0;
            dmi_req_addr_in_r <= 7'd0;
            dmi_req_data_in_r <= 32'd0;
            dmi_req_op_in_r   <= 2'd0;

            resp_valid_r      <= 1'b0;
            resp_rdata_r      <= 32'd0;
            resp_error_r      <= 1'b0;

        end
        else begin

            dmi_req_pulse_r   <= dmi_req_pulse;
            dmi_req_addr_in_r <= dmi_req_addr_in;
            dmi_req_data_in_r <= dmi_req_data_in;
            dmi_req_op_in_r   <= dmi_req_op_in;

            resp_valid_r      <= resp_valid;
            resp_rdata_r      <= resp_rdata;
            resp_error_r      <= resp_error;

        end
    end

    // =========================================================
    //  FSM
    // =========================================================

    always @(posedge dbg_clk or negedge dbg_resetn) begin

        if (!dbg_resetn) begin

            state <= STATE_IDLE;

            dmi_req_valid  <= 1'b0;
            dmi_req_op     <= 2'b00;
            dmi_req_addr   <= 7'd0;
            dmi_req_wdata  <= 32'd0;

            dmi_resp_valid <= 1'b0;
            dmi_resp_data  <= 32'd0;
            dmi_resp_op    <= 2'b00;

            dm_busy        <= 1'b0;

        end
        else begin

            // -------------------------------------------------
            // Default pulse outputs
            // -------------------------------------------------

            dmi_req_valid  <= 1'b0;
            dmi_resp_valid <= 1'b0;

            case (state)

                // =================================================
                // IDLE
                // =================================================

                STATE_IDLE: begin

                    dm_busy <= 1'b0;

                    // ---------------------------------------------
                    // New request arrives while idle
                    // ---------------------------------------------

                    if (dmi_req_pulse_r) begin

                        dmi_req_valid <= 1'b1;

                        dmi_req_op    <= dmi_req_op_in_r;
                        dmi_req_addr  <= dmi_req_addr_in_r;
                        dmi_req_wdata <= dmi_req_data_in_r;

                        dm_busy       <= 1'b1;

                        state         <= STATE_WAIT_RESP;

                    end
                end

                // =================================================
                // WAIT FOR RESPONSE
                // =================================================

                STATE_WAIT_RESP: begin

                    dm_busy <= 1'b1;

                    // ---------------------------------------------
                    // New request while busy
                    // ---------------------------------------------

                    if (dmi_req_pulse_r) begin

                        dmi_resp_valid <= 1'b1;
                        dmi_resp_data  <= 32'd0;

                        // Busy response
                        dmi_resp_op    <= 2'b11;

                    end

                    // ---------------------------------------------
                    // Response received from DM
                    // ---------------------------------------------

                    else if (resp_valid_r) begin

                        dmi_resp_valid <= 1'b1;
                        dmi_resp_data  <= resp_rdata_r;

                        // -----------------------------------------
                        // Response Encoding
                        // -----------------------------------------

                        if (resp_error_r)
                            dmi_resp_op <= 2'b10; // Failed/Error
                        else
                            dmi_resp_op <= 2'b00; // Success

                        dm_busy <= 1'b0;

                        state <= STATE_IDLE;

                    end
                end

                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    state <= STATE_IDLE;

                    dmi_req_valid  <= 1'b0;

                    dmi_req_op     <= 2'b00;
                    dmi_req_addr   <= 7'd0;
                    dmi_req_wdata  <= 32'd0;

                    dmi_resp_valid <= 1'b0;
                    dmi_resp_data  <= 32'd0;
                    dmi_resp_op    <= 2'b00;

                    dm_busy        <= 1'b0;

                end
            endcase
        end
    end

endmodule



