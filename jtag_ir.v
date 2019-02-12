module jtag_ir #(
    parameter ir_len = 5, // standard IR length

	// instruction opcodes 
	parameter ir_bypass = 5'h1f,  // default bypass
    parameter ir_idcode = 5'h01,  // idcode
    parameter ir_dtmcs  = 5'h10,  //dtmcs
    parameter ir_dmi    = 5'h11   // dmi
  
)(
    input  wire        tck,
    input  wire        trst_n,
    input  wire        capture_ir,
    input  wire        shift_ir,
    input  wire        update_ir,
    input  wire        tdi,
    output reg         tdo,
   

    // decoded enables for other blocks
    output wire        bypass_enable,
    output wire        idcode_enable,
    output wire        dtmcs_enable,
    output wire        dmi_enable
);

    
    reg [ir_len-1:0] ir_shift;
    reg [ir_len-1:0] ir_value;
/*
	reg	capture_ir;
    reg shift_ir;
    reg update_ir;
    reg tdi;

	always @(posedge tck or negedge trst_n) begin
        if(!trst_n) begin
			capture_ir <= 1'b0;	
			shift_ir   <= 1'b0;	
			update_ir  <= 1'b0;	
			tdi		 <= 1'b0;	
		end
		else begin
			capture_ir <= capture_ir;	
			shift_ir   <= shift_ir;	
			update_ir  <= update_ir;	
			tdi 	     <= tdi;	
		end
	end

*/

    // shift/capture logic
    always @(posedge tck or negedge trst_n) begin
        if(!trst_n) begin
            ir_shift  <= ir_idcode;  // default after reset
            ir_value  <= ir_idcode;
        end
        else begin
            if(capture_ir)
               ir_shift <= {{(ir_len-2){1'b0}}, 2'b01};

            else if(shift_ir)
                ir_shift <= {tdi, ir_shift[ir_len-1:1]};

            else if(update_ir)
                ir_value <= ir_shift; // latch instruction
        end
    end

    // tdo output during shift
    always @(shift_ir, ir_shift[0]) begin
        if(shift_ir) begin
            tdo = ir_shift[0];
		end
        else begin
            tdo = 1'b0;
		end
    end

    // instruction decode signals
    assign bypass_enable = (ir_value == ir_bypass);
    assign idcode_enable = (ir_value == ir_idcode);
    assign dmi_enable    = (ir_value == ir_dmi);
    assign dtmcs_enable  = (ir_value == ir_dtmcs);

endmodule


