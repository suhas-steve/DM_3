module jtag_tdo_mux (

    input  wire shift_ir,
    input  wire shift_dr,

    // TDO sources
    input  wire ir_tdo,
    input  wire dmi_tdo,
    input  wire dtmcs_tdo,
    input  wire idcode_tdo,
    input  wire bypass_tdo,
    // instruction enables
    input  wire dmi_enable,
    input  wire dtmcs_enable,
    input  wire idcode_enable,
    input  wire bypass_enable,

    output wire tdo
);

assign tdo =
       (shift_ir)                   ? ir_tdo       :

       (shift_dr && dmi_enable)     ? dmi_tdo      :
       (shift_dr && dtmcs_enable)   ? dtmcs_tdo    :
       (shift_dr && idcode_enable)  ? idcode_tdo   :
       (shift_dr && bypass_enable)  ? bypass_tdo   :

                                      1'b0;

endmodule

