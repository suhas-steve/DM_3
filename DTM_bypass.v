module DTM_bypass (
    input        tck,
    input        trst_n,

    input        capture_dr,
    input        shift_dr,

    input        bypass_enable,

    input        tdi,
    output reg   bypass_tdo
);

reg bypass_shift;

// Shift register
always @(posedge tck or negedge trst_n) begin
    if (!trst_n)
        bypass_shift <= 1'b0;

    else if (bypass_enable) begin

        if (capture_dr)
            bypass_shift <= 1'b0;

        else if (shift_dr)
            bypass_shift <= tdi;
    end
end

// TDO launch
always @(bypass_enable or shift_dr or bypass_shift) begin
    if (bypass_enable && shift_dr)
        bypass_tdo = bypass_shift;
    else
        bypass_tdo = 1'b0;
end


endmodule





