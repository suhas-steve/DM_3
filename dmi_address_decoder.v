/*
module dmi_address_decoder (
    input          dmi_valid,
    input   [6:0]  dmi_addr,

    output reg         sel_data,            // 0x04 - 0x0F
    output reg         sel_dmcontrol,       // 0x10
    output reg         sel_dmstatus,        // 0x11
    output reg         sel_hartinfo,        // 0x12
    output reg         sel_abstractcs,      // 0x16
    output reg         sel_command,         // 0x17
    output reg         sel_abstractauto,    // 0x18
    output reg         sel_progbuf,         // 0x20 - 0x2F
    output reg         sel_haltsum0,        // 0x40
    output reg         sel_invalid_addr     // invalid address
);

    always @(dmi_valid, dmi_addr) begin
        // Default outputs
        sel_data          = 1'b0;
        sel_dmcontrol     = 1'b0;
        sel_dmstatus      = 1'b0;
        sel_hartinfo      = 1'b0;
        sel_abstractcs    = 1'b0;
        sel_command       = 1'b0;
        sel_abstractauto  = 1'b0;
        sel_progbuf       = 1'b0;
        sel_haltsum0      = 1'b0;
        sel_invalid_addr  = 1'b0;

        // Decode only when DMI transaction is valid
        if (dmi_valid) begin

            if (dmi_addr >= 7'h04 && dmi_addr <= 7'h0F) begin
                sel_data = 1'b1;
            end

            else if (dmi_addr == 7'h10) begin
                sel_dmcontrol = 1'b1;
            end

            else if (dmi_addr == 7'h11) begin
                sel_dmstatus = 1'b1;
            end

            else if (dmi_addr == 7'h12) begin
                sel_hartinfo = 1'b1;
            end

            else if (dmi_addr == 7'h16) begin
                sel_abstractcs = 1'b1;
            end

            else if (dmi_addr == 7'h17) begin
                sel_command = 1'b1;
            end

            else if (dmi_addr == 7'h18) begin
                sel_abstractauto = 1'b1;
            end

            else if (dmi_addr >= 7'h20 && dmi_addr <= 7'h2F) begin
                sel_progbuf = 1'b1;
            end

            else if (dmi_addr == 7'h40) begin
                sel_haltsum0 = 1'b1;
            end

            else begin
                sel_invalid_addr = 1'b1;
            end
        end
    end

endmodule
*/


module dmi_address_decoder (
    input          dmi_valid,
    input   [6:0]  dmi_addr,

    output reg         sel_data,            // 0x04 - 0x0F
    output reg         sel_dmcontrol,       // 0x10
    output reg         sel_dmstatus,        // 0x11
    output reg         sel_hartinfo,        // 0x12
    output reg         sel_abstractcs,      // 0x16
    output reg         sel_command,         // 0x17
    output reg         sel_abstractauto,    // 0x18
    output reg         sel_progbuf,         // 0x20 - 0x2F
    output reg         sel_haltsum0,        // 0x40
    output reg         sel_invalid_addr,     // invalid address
    output reg         sel_sbcs,
    output reg         sel_sbaddress0,
    output reg         sel_sbdata0
);

    always @(dmi_valid, dmi_addr) begin
        // Default outputs
        sel_data          = 1'b0;
        sel_dmcontrol     = 1'b0;
        sel_dmstatus      = 1'b0;
        sel_hartinfo      = 1'b0;
        sel_abstractcs    = 1'b0;
        sel_command       = 1'b0;
        sel_abstractauto  = 1'b0;
        sel_progbuf       = 1'b0;
        sel_haltsum0      = 1'b0;
        sel_invalid_addr  = 1'b0;
        sel_sbcs          = 1'b0;
        sel_sbaddress0    = 1'b0;
        sel_sbdata0       = 1'b0;

        // Decode only when DMI transaction is valid
        if (dmi_valid) begin

            if (dmi_addr >= 7'h04 && dmi_addr <= 7'h0F) begin
                sel_data = 1'b1;
            end

            else if (dmi_addr == 7'h10) begin
                sel_dmcontrol = 1'b1;
            end

            else if (dmi_addr == 7'h11) begin
                sel_dmstatus = 1'b1;
            end

            else if (dmi_addr == 7'h12) begin
                sel_hartinfo = 1'b1;
            end

            else if (dmi_addr == 7'h16) begin
                sel_abstractcs = 1'b1;
            end

            else if (dmi_addr == 7'h17) begin
                sel_command = 1'b1;
            end

            else if (dmi_addr == 7'h18) begin
                sel_abstractauto = 1'b1;
            end

            else if (dmi_addr >= 7'h20 && dmi_addr <= 7'h2F) begin
                sel_progbuf = 1'b1;
            end

            else if (dmi_addr == 7'h40) begin
                sel_haltsum0 = 1'b1;
            end

            else if (dmi_addr == 7'h38) begin
                 sel_sbcs = 1'b1;
            end

            else if (dmi_addr == 7'h39) begin
                  sel_sbaddress0 = 1'b1;
            end

            else if (dmi_addr == 7'h3C) begin
                  sel_sbdata0 = 1'b1;
            end

            else begin
                sel_invalid_addr = 1'b1;
            end
        end
    end

endmodule


