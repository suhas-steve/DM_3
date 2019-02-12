


module dmi_data_register #(
    parameter abits = 7,
    parameter dr_len = 32 + abits + 2
	
)(
    input  wire           tck,
    input  wire           trst_n,

    input  wire           capture_dr,
    input  wire           shift_dr,
    input  wire           update_dr,

    input  wire           dmi_enable,

    input  wire           tdi,
    output reg            tdo,

    output  [abits-1:0] dtm_dmi_addr,
    output	[31:0]      dmi_data,
    output  [1:0]       dtm_dmi_op,

    output reg             dmi_req_pulse 
);

	reg capture_dr_r;
	reg	shift_dr_r;
	reg update_dr_r;
	reg dmi_enable_r;
	reg	tdi_r;

	always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
			capture_dr_r	<= 1'b0;
			shift_dr_r	    <= 1'b0;
			update_dr_r		<= 1'b0;
			dmi_enable_r	<= 1'b0;	
			tdi_r 		    <= 1'b0;
		end
		else begin 
			capture_dr_r 	<= capture_dr;
			shift_dr_r    	<= shift_dr;
			update_dr_r 	<= update_dr;
			dmi_enable_r 	<= dmi_enable;	
			tdi_r 		    <= tdi;
		end
	end

	//   "Output port 'dmi_data' is read in the design-unit 'dmi_data_register'
	reg	[31:0]   	dmi_data_r;
	assign dmi_data = dmi_data_r;

	reg	[abits-1:0] dtm_dmi_addr_r;
	assign dtm_dmi_addr = dtm_dmi_addr_r;

	reg	[1:0]       dtm_dmi_op_r;
	assign dtm_dmi_op = dtm_dmi_op_r;
	
	
    reg [dr_len-1:0] shift_reg;

    // capture / shift / update
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            shift_reg     <= {dr_len{1'b0}};
            dtm_dmi_addr_r  <= {abits{1'b0}};
            dmi_data_r    <= 32'b0;
            dtm_dmi_op_r    <= 2'b00;
            dmi_req_pulse <= 1'b0;
        end else begin
            // default: pulse clears automatically
            dmi_req_pulse <= 1'b0;

            if (dmi_enable_r) begin
                if (capture_dr_r) begin
                    shift_reg <= {dtm_dmi_addr_r,dmi_data_r, dtm_dmi_op_r};
                end
                else if (shift_dr_r) begin
                    shift_reg <= {tdi_r, shift_reg[dr_len-1:1]};
                end
                else if (update_dr_r) begin
                    dtm_dmi_op_r   <= shift_reg[1:0];
                    dmi_data_r     <= shift_reg[33:2];
                    dtm_dmi_addr_r <= shift_reg[33+abits:34]; 
                    

                    // >>> ISSUE REQUEST <<<
                    if (shift_reg[1:0] != 2'b00)
                        dmi_req_pulse <= 1'b1;
                end
            end
        end
    end

    // tdo logic (ieee 1149.1 compliant)
    always @(negedge tck or negedge trst_n) begin
//    always @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            tdo <= 1'b0;
        else if (dmi_enable_r && shift_dr_r)
            tdo <= shift_reg[0];
        else
            tdo <= 1'b0;
    end

endmodule





