module dmi_transaction_fsm (
  input  wire        tck,
  input  wire        trst_n,

  // request from dmi dr (update_dr pulse)
  input  wire        dmi_req_pulse,

  // response from system (after cdc)
  input  wire        dtm_resp_valid,
  input  wire [1:0]  resp_op,

  // sticky clear (from dtmcs)
  input  wire        clr_sticky,

  // status outputs
  output reg         dmi_busy,
  output reg         sticky_error,
  output reg         sticky_busy,

  // control toward cdc
  output reg         issue_req
);

  reg 	dmi_req_pulse_r;
  reg	dtm_resp_valid_r;
  reg	[1:0]  resp_op_r;
  reg 	clr_sticky_r;

  always @(posedge tck or negedge trst_n) begin
    if (!trst_n) begin
		dmi_req_pulse_r <= 1'b0;
		dtm_resp_valid_r<= 1'b0;
		resp_op_r		<= 2'b00;
		clr_sticky_r	<= 1'b0;		
	end
	else begin
		dmi_req_pulse_r <= dmi_req_pulse;
		dtm_resp_valid_r<= dtm_resp_valid;
		resp_op_r		<= resp_op;
		clr_sticky_r	<= clr_sticky;
	end
  end

  

  // ------------------------------------------------------------
  // fsm states
  // ------------------------------------------------------------
  parameter s_idle      = 2'd0;
  parameter s_issue_req = 2'd1;
  parameter s_wait_resp = 2'd2;
  parameter s_error     = 2'd3;

  reg [1:0] state, next_state;

  // ------------------------------------------------------------
  // state register
  // ------------------------------------------------------------
  always @(posedge tck or negedge trst_n) begin
    if (!trst_n)
      state <= s_idle;
    else
      state <= next_state;
  end

  // ------------------------------------------------------------
  // next-state logic
  // ------------------------------------------------------------
  always @(state, dmi_req_pulse_r, dtm_resp_valid_r, resp_op_r, clr_sticky_r) begin
    next_state = state;

    case (state)
      s_idle: begin
        if (dmi_req_pulse_r)
          next_state = s_issue_req;
      end

      s_issue_req: begin
        next_state = s_wait_resp;
      end

      s_wait_resp: begin
        if (dtm_resp_valid_r) begin
          if (resp_op_r == 2'b00)
            next_state = s_idle;
          else
            next_state = s_error;
        end
      end

      s_error: begin
        if (clr_sticky_r)
          next_state = s_idle;
      end

/*
      default: begin
        next_state = s_idle;
      end
*/
    endcase
  end

  // ------------------------------------------------------------
  // output & sticky logic
  // ------------------------------------------------------------
  always @(posedge tck or negedge trst_n) begin
    if (!trst_n) begin
      dmi_busy     <= 1'b0;
      sticky_busy  <= 1'b0;
      sticky_error <= 1'b0;
      issue_req    <= 1'b0;
    end
    else begin
      // defaults
      dmi_busy  <= 1'b0;
      issue_req <= 1'b0;

      // sticky clear has highest priority
      if (clr_sticky_r) begin
        sticky_busy  <= 1'b0;
        sticky_error <= 1'b0;
      end

      else begin

      case (state)
        s_idle: begin
          dmi_busy <= 1'b0;
        end

        s_issue_req: begin
          dmi_busy  <= 1'b1;
          issue_req <= 1'b1;   // one-cycle pulse
        end

        s_wait_resp: begin
          dmi_busy <= 1'b1;
        end

        s_error: begin
          dmi_busy <= 1'b0;
          if (!clr_sticky_r)
            sticky_error <= 1'b1;
        end
      endcase

      // detect new request while busy  sticky_busy
      if (state != s_idle && dmi_req_pulse_r)
        sticky_busy <= 1'b1;
    end
  end
end
endmodule



