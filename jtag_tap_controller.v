
module jtag_tap_controller (
    input       tck,
    input       tms,
    input       trst_n,      // active-low tap reset

//	output wire dr_scan;

    output wire capture_dr,
    output wire shift_dr,
    output wire update_dr,

    output wire capture_ir,
    output wire shift_ir,
    output wire update_ir
);
/*
reg tms;

always @(posedge tck or negedge trst_n) begin
    if (!trst_n) begin
		tms <= 1'b0;
	end
	else begin
		tms <= tms;
	end
end
*/

// -------------------------------------------------------------------------
// tap fsm states (ieee-1149.1)
// -------------------------------------------------------------------------
parameter test_logic_reset = 4'd0;
parameter run_test_idle    = 4'd1;
parameter select_dr_scan   = 4'd2;
parameter capture_dr_s     = 4'd3;
parameter shift_dr_s       = 4'd4;
parameter exit1_dr_s       = 4'd5;
parameter pause_dr_s       = 4'd6;
parameter exit2_dr_s       = 4'd7;
parameter update_dr_s      = 4'd8;
parameter select_ir_scan   = 4'd9;
parameter capture_ir_s     = 4'd10;
parameter shift_ir_s       = 4'd11;
parameter exit1_ir_s       = 4'd12;
parameter pause_ir_s       = 4'd13;
parameter exit2_ir_s       = 4'd14;
parameter update_ir_s      = 4'd15;

reg [3:0] state, next_state;

// -------------------------------------------------------------------------
// state register
// -------------------------------------------------------------------------
always @(posedge tck or negedge trst_n) begin
    if (!trst_n)
        state <= test_logic_reset;
    else
        state <= next_state;
end

// -------------------------------------------------------------------------
// next-state logic
// -------------------------------------------------------------------------
always @(state, tms) begin
    next_state = state;
    case (state)

        test_logic_reset: next_state = tms ? test_logic_reset : run_test_idle;
        run_test_idle:    next_state = tms ? select_dr_scan   : run_test_idle;
        select_dr_scan:   next_state = tms ? select_ir_scan   : capture_dr_s;
        capture_dr_s:     next_state = tms ? exit1_dr_s       : shift_dr_s;
        shift_dr_s:       next_state = tms ? exit1_dr_s       : shift_dr_s;
        exit1_dr_s:       next_state = tms ? update_dr_s      : pause_dr_s;
        pause_dr_s:       next_state = tms ? exit2_dr_s       : pause_dr_s;
        exit2_dr_s:       next_state = tms ? update_dr_s      : shift_dr_s;
        update_dr_s:      next_state = tms ? select_dr_scan   : run_test_idle;

        select_ir_scan:   next_state = tms ? test_logic_reset : capture_ir_s;
        capture_ir_s:     next_state = tms ? exit1_ir_s       : shift_ir_s;
        shift_ir_s:       next_state = tms ? exit1_ir_s       : shift_ir_s;
        exit1_ir_s:       next_state = tms ? update_ir_s      : pause_ir_s;
        pause_ir_s:       next_state = tms ? exit2_ir_s       : pause_ir_s;
        exit2_ir_s:       next_state = tms ? update_ir_s      : shift_ir_s;
        update_ir_s:      next_state = tms ? select_dr_scan   : run_test_idle;

//        default:          next_state = test_logic_reset;

    endcase
end

// -------------------------------------------------------------------------
// output logic
// -------------------------------------------------------------------------
// assign dr_scan     = (state == select_dr_scan);

// DR strobes
assign capture_dr  = (state == capture_dr_s);
assign shift_dr    = (state == shift_dr_s);
assign update_dr   = (state == update_dr_s);

// IR strobes
assign capture_ir  = (state == capture_ir_s);
assign shift_ir    = (state == shift_ir_s);
assign update_ir   = (state == update_ir_s);


endmodule




