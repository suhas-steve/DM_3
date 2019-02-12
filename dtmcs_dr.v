module dtmcs_register #(
    parameter ABITS = 6'h07
)(
    input  wire tck,
    input  wire trst_n,

    input  wire capture_dr,
    input  wire shift_dr,
    input  wire update_dr,

    input  wire dtmcs_enable,

    input  wire sticky_busy,
    input  wire sticky_error,

    input  wire tdi,
    output reg  dtmcs_tdo,

    output reg  dtm_dmi_reset_pulse
);



    
    // DTMCS fields

    parameter  [3:0] VERSION = 4'h1;
    parameter  [3:0] IDLE    = 4'd1;

    reg [31:0] shift_reg;

    wire [1:0] dmistat;

    assign dmistat =
            (sticky_busy)  ? 2'b11 :
            (sticky_error) ? 2'b10 :
                             2'b00;

        // Capture / Shift / Update
    
    always @(posedge tck or negedge trst_n) begin

        if(!trst_n) begin
            shift_reg       <= 32'b0;
            dtm_dmi_reset_pulse  <= 1'b0;
        end

        else begin

            dtm_dmi_reset_pulse <= 1'b0;

            if(dtmcs_enable) begin

                
                // CAPTURE-DR
               
                   if(capture_dr) begin
                       shift_reg <= {
                      14'b0,          // [31:18]
                       1'b0,          // [17] dmihardreset
                       1'b0,          // [16] dmireset
                       IDLE,          // [15:12]
                    dmistat,          // [11:10]
                      6'h07,          // [9:4]
                     VERSION         // [3:0]
};

              end

                // SHIFT-DR
                
                else if(shift_dr) begin
                    shift_reg <= {tdi, shift_reg[31:1]};
                end

                // --------------------------------------------
                // UPDATE-DR
                // --------------------------------------------
                else if(update_dr) begin

                    // dmireset bit
                    if(shift_reg[16])
                        dtm_dmi_reset_pulse <= 1'b1;
                end
            end
        end
    end

    // --------------------------------------------------------
    // TDO
    // --------------------------------------------------------
    always @(negedge tck or negedge trst_n) begin

        if(!trst_n)
            dtmcs_tdo <= 1'b0;

        else if(dtmcs_enable && shift_dr)
            dtmcs_tdo <= shift_reg[0];

        else
            dtmcs_tdo <= 1'b0;
    end

endmodule
