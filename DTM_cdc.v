module DTM_cdc (

    // =====================================================
    // TCK DOMAIN
    // =====================================================

    input  wire        tck,
    input  wire        trst_n,

    // Request from DTM
    input  wire        issue_req,
    input  wire [6:0]  dtm_dmi_addr,
    input  wire [31:0] dmi_data,
    input  wire [1:0]  dtm_dmi_op,

    // Response toward DTM
    output reg         tck_resp_pulse,
    output reg [31:0]  tck_resp_data,
    output reg [1:0]   tck_resp_op,

    // =====================================================
    // DEBUG CLOCK DOMAIN
    // =====================================================

    input  wire        dbg_clk,
    input  wire        dbg_resetn,

    // Request toward dmi_request FSM
    output reg         dmi_req_pulse,
    output reg [6:0]   dmi_req_addr,
    output reg [31:0]  dmi_req_data,
    output reg [1:0]   dmi_req_op,

    // Response from dmi_request FSM
    input  wire        dmi_resp_valid,
    input  wire [31:0] dmi_resp_data,
    input  wire [1:0]  dmi_resp_op
);

    // =====================================================
    // TCK DOMAIN REGISTRATION
    // =====================================================

    reg        issue_req_r;
    reg [6:0]  dtm_dmi_addr_r;
    reg [31:0] dmi_data_r;
    reg [1:0]  dtm_dmi_op_r;

    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin

            issue_req_r    <= 1'b0;
            dtm_dmi_addr_r <= 7'd0;
            dmi_data_r     <= 32'd0;
            dtm_dmi_op_r   <= 2'd0;

        end
        else begin

            issue_req_r    <= issue_req;
            dtm_dmi_addr_r <= dtm_dmi_addr;
            dmi_data_r     <= dmi_data;
            dtm_dmi_op_r   <= dtm_dmi_op;

        end
    end

    // =====================================================
    // DBG DOMAIN REGISTRATION
    // =====================================================

    reg        dmi_resp_valid_r;
    reg [31:0] dmi_resp_data_r;
    reg [1:0]  dmi_resp_op_r;

    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin

            dmi_resp_valid_r <= 1'b0;
            dmi_resp_data_r  <= 32'd0;
            dmi_resp_op_r    <= 2'b00;

        end
        else begin

            dmi_resp_valid_r <= dmi_resp_valid;
            dmi_resp_data_r  <= dmi_resp_data;
            dmi_resp_op_r    <= dmi_resp_op;

        end
    end

    // =====================================================
    // REQUEST PENDING CONTROL
    // =====================================================

    reg request_pending;

    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin

            request_pending <= 1'b0;

        end
        else begin

            // ---------------------------------------------
            // Set when new request issued
            // ---------------------------------------------

            if (issue_req_r && !request_pending)
                request_pending <= 1'b1;

            // ---------------------------------------------
            // Clear when response returns
            // ---------------------------------------------

            else if (tck_resp_pulse)
                request_pending <= 1'b0;

        end
    end

    // =====================================================
    // TCK -> DBG_CLK CDC
    // =====================================================

    reg tck_req_toggle;

    reg dbg_req_toggle_ff1;
    reg dbg_req_toggle_ff2;

    // -----------------------------------------------------
    // Toggle generated on request
    // -----------------------------------------------------

    always @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            tck_req_toggle <= 1'b0;

        else if (issue_req_r && !request_pending)
            tck_req_toggle <= ~tck_req_toggle;
    end

    // -----------------------------------------------------
    // Synchronize toggle into dbg_clk domain
    // -----------------------------------------------------

    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin

            dbg_req_toggle_ff1 <= 1'b0;
            dbg_req_toggle_ff2 <= 1'b0;

        end
        else begin

            dbg_req_toggle_ff1 <= tck_req_toggle;
            dbg_req_toggle_ff2 <= dbg_req_toggle_ff1;

        end
    end

    // -----------------------------------------------------
    // Detect request pulse in dbg_clk domain
    // -----------------------------------------------------

    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin

            dmi_req_pulse <= 1'b0;
            dmi_req_addr  <= 7'd0;
            dmi_req_data  <= 32'd0;
            dmi_req_op    <= 2'b00;

        end
        else begin

            dmi_req_pulse <= dbg_req_toggle_ff1 ^ dbg_req_toggle_ff2;

            // ---------------------------------------------
            // Capture stable payload
            // ---------------------------------------------

            if (dbg_req_toggle_ff1 ^ dbg_req_toggle_ff2) begin

                dmi_req_addr <= dtm_dmi_addr_r;
                dmi_req_data <= dmi_data_r;
                dmi_req_op   <= dtm_dmi_op_r;

            end
        end
    end

    // =====================================================
    // DBG_CLK -> TCK CDC
    // =====================================================

    reg dbg_resp_toggle;

    reg tck_resp_toggle_ff1;
    reg tck_resp_toggle_ff2;

    // -----------------------------------------------------
    // Toggle generated on response valid
    // -----------------------------------------------------

    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn)
            dbg_resp_toggle <= 1'b0;

        else if (dmi_resp_valid_r)
            dbg_resp_toggle <= ~dbg_resp_toggle;
    end

    // -----------------------------------------------------
    // Synchronize toggle into TCK domain
    // -----------------------------------------------------

    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin

            tck_resp_toggle_ff1 <= 1'b0;
            tck_resp_toggle_ff2 <= 1'b0;

        end
        else begin

            tck_resp_toggle_ff1 <= dbg_resp_toggle;
            tck_resp_toggle_ff2 <= tck_resp_toggle_ff1;

        end
    end

    // -----------------------------------------------------
    // Detect response pulse in TCK domain
    // -----------------------------------------------------

    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin

            tck_resp_pulse <= 1'b0;
            tck_resp_data  <= 32'd0;
            tck_resp_op    <= 2'b00;

        end
        else begin

            tck_resp_pulse <= tck_resp_toggle_ff1 ^
                              tck_resp_toggle_ff2;

            // ---------------------------------------------
            // Capture stable response payload
            // ---------------------------------------------

            if (tck_resp_toggle_ff1 ^
                tck_resp_toggle_ff2) begin

                tck_resp_data <= dmi_resp_data_r;
                tck_resp_op   <= dmi_resp_op_r;

            end
        end
    end

endmodule




