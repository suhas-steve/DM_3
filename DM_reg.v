module DM_reg (
    input               dbg_clk,
    input               dbg_resetn,

    /* from CDC adapter */
    input      [31:0]   dmi_wdata,
    input      [1:0]    dmi_op,        

    /* from DMI address decoder */
    input               sel_data,
    input               sel_dmcontrol,
    input               sel_dmstatus,
    input               sel_hartinfo,
    input               sel_abstractcs,
    input               sel_command,
    input               sel_abstractauto,
    input               sel_progbuf,
    input               sel_haltsum0,
    input               sel_invalid_addr,

        //SBA input signals
    input               sel_sbcs,
    input               sel_sbaddress0,
    input               sel_sbdata0,

    /* index for progbuf (addr[3:0]) */
    input      [3:0]    progbuf_index,
    input      [3:0]    data_index,    

    /* from other dm blocks */
    input               hart_halted,
    input               hart_reset,
    input               abstract_busy,
    input [2:0]    abstract_cmderr,
    input [31:0] ace_data_wdata,
	input [3:0]  ace_data_index,
	input        ace_data_write,
    input         sbbusy_set,
    input         sbbusy_clear,
    input         sberror_valid,
    input [2:0]   sberror_set,
    input         auto_inc_en,
    input [31:0]  auto_inc_value,
    input         read_data_valid,
    input [31:0]  sba_read_data_out,


        //SBA output signals
    output reg sbcs_write_pulse,
    output reg sbaddress0_write_pulse,
    output reg sbdata0_write_pulse,
    output reg [31:0] sbcs,
    output reg [31:0] sbaddress0,
    output reg [31:0] sbdata0,

    /* response to DMI / CDC */
    output reg          resp_valid_dbg,
    output reg [31:0]   resp_rdata_dbg,
    output reg          resp_error_dbg,

    /* outputs to other dm blocks */
    output reg          haltreq,
    output reg          resethaltreq,
    output reg          resumereq,
    output reg          ndmreset,
    output reg          dmactive,
    output reg          cmd_write_pulse,
    output reg          clear_cmderr,

    /* command register to ACE */
    output reg [31:0]   command,

    /* program buffer storage */
    output  [31:0]   progbuf0,
    output  [31:0]   progbuf1,
    output  [31:0]   progbuf2,
    output  [31:0]   progbuf3,
    output  [31:0]   progbuf4,
    output  [31:0]   progbuf5,
    output  [31:0]   progbuf6,
    output  [31:0]   progbuf7,
    output  [31:0]   progbuf8,
    output  [31:0]   progbuf9,
    output  [31:0]   progbuf10,
    output  [31:0]   progbuf11,
    output  [31:0]   progbuf12,
    output  [31:0]   progbuf13,
    output  [31:0]   progbuf14,
    output  [31:0]   progbuf15,

    output  [31:0] data0,
	output  [31:0] data1,
	output  [31:0] data2,
	output  [31:0] data3,
	output  [31:0] data4,
	output  [31:0] data5,
	output  [31:0] data6,
	output  [31:0] data7,
	output  [31:0] data8,
    output  [31:0] data9,
    output  [31:0] data10,
	output  [31:0] data11

);

reg [31:0] data0_r;
reg [31:0] data1_r;
reg [31:0] data2_r;
reg [31:0] data3_r;
reg [31:0] data4_r;
reg [31:0] data5_r;
reg [31:0] data6_r;
reg [31:0] data7_r;
reg [31:0] data8_r;
reg [31:0] data9_r;
reg [31:0] data10_r;
reg [31:0] data11_r;
reg [31:0] dmcontrol;
reg [31:0] abstractauto;


    //output registration

    reg [31:0]     progbuf0_r;
    reg [31:0]     progbuf1_r;
    reg [31:0]     progbuf2_r;
    reg [31:0]     progbuf3_r;
    reg [31:0]     progbuf4_r;
    reg [31:0]     progbuf5_r;
    reg [31:0]     progbuf6_r;
    reg [31:0]     progbuf7_r;
    reg [31:0]     progbuf8_r;
    reg [31:0]     progbuf9_r;
    reg [31:0]     progbuf10_r;
    reg [31:0]     progbuf11_r;
    reg [31:0]     progbuf12_r;
    reg [31:0]     progbuf13_r;
    reg [31:0]     progbuf14_r;
    reg [31:0]     progbuf15_r; 

     assign     progbuf0 		= progbuf0_r;
     assign		progbuf1		= progbuf1_r;
     assign	   	progbuf2		= progbuf2_r;
     assign		progbuf3		= progbuf3_r;
     assign		progbuf4		= progbuf4_r;
     assign		progbuf5		= progbuf5_r;
     assign		progbuf6		= progbuf6_r;
     assign		progbuf7		= progbuf7_r;
     assign		progbuf8		= progbuf8_r;
     assign		progbuf9		= progbuf9_r;
     assign		progbuf10		= progbuf10_r;
     assign		progbuf11		= progbuf11_r;
     assign		progbuf12		= progbuf12_r;
     assign		progbuf13	    = progbuf13_r;
     assign		progbuf14	    = progbuf14_r;
     assign		progbuf15		= progbuf15_r;

     assign     data0 		= data0_r;
     assign		data1		= data1_r;
     assign	   	data2		= data2_r;
     assign		data3		= data3_r;
     assign		data4		= data4_r;
     assign		data5		= data5_r;
     assign		data6		= data6_r;
     assign		data7		= data7_r;
     assign		data8		= data8_r;
     assign		data9		= data9_r;
     assign		data10	    = data10_r;
     assign		data11		= data11_r;
    
    
 //registration of inputs
    reg [31:0] dmi_wdata_r;
    reg [1:0]  dmi_op_r;       
    reg sel_data_r;
    reg sel_dmcontrol_r;
    reg sel_dmstatus_r;
    reg sel_hartinfo_r;
    reg sel_abstractcs_r;
    reg sel_command_r;
    reg sel_abstractauto_r;
    reg sel_progbuf_r;
    reg sel_haltsum0_r;
    reg sel_invalid_addr_r;
    reg [3:0] progbuf_index_r;
    reg hart_halted_r;
    reg hart_reset_r;
    reg abstract_busy_r;
    reg [2:0] abstract_cmderr_r;
    reg [3:0] data_index_r;
   
    reg sel_sbcs_r;
    reg sel_sbaddress0_r;
    reg sel_sbdata0_r;



wire hart_running_int;

assign hart_running_int =
        !hart_halted_r &&
        !hart_reset_r;

    wire dmi_write = (dmi_op_r == 2'b10);
    wire dmi_read  = (dmi_op_r == 2'b01);

    wire any_sel =
        sel_data_r | sel_dmcontrol_r | sel_dmstatus_r | sel_hartinfo_r |
        sel_abstractcs_r | sel_command_r | sel_abstractauto_r |
        sel_progbuf_r | sel_haltsum0_r | sel_invalid_addr_r|sel_sbcs_r|
        sel_sbaddress0_r|sel_sbdata0_r;

    /* ---------------------------------------------------------- */
    /* write logic                                                */
    /* ---------------------------------------------------------- */
    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin
        dmi_wdata_r      <=32'h0;
        dmi_op_r         <=2'b0;       
        sel_data_r       <=1'b0;
        sel_dmcontrol_r  <=1'b0;
        sel_dmstatus_r   <=1'b0;
        sel_hartinfo_r   <=1'b0;
        sel_abstractcs_r <=1'b0;
        sel_command_r    <=1'b0;
        sel_abstractauto_r<=1'b0;
        sel_progbuf_r    <=1'b0;
        sel_haltsum0_r   <=1'b0;
        sel_invalid_addr_r<=1'b0;
        progbuf_index_r   <=4'b0;
        data_index_r      <=4'b0;
        hart_halted_r     <= 1'b0;
        hart_reset_r      <= 1'b0;
        abstract_busy_r   <=1'b0;
        abstract_cmderr_r <=3'b0;
        sel_sbcs_r       <= 1'b0;
        sel_sbaddress0_r <= 1'b0;
        sel_sbdata0_r    <= 1'b0;


        end else begin
            dmi_wdata_r <= dmi_wdata;
            dmi_op_r <= dmi_op;

            sel_data_r <= sel_data;
            sel_dmcontrol_r <= sel_dmcontrol;
            sel_dmstatus_r <= sel_dmstatus;
            sel_hartinfo_r <= sel_hartinfo;
            sel_abstractcs_r <= sel_abstractcs;
            sel_command_r <= sel_command;
            sel_abstractauto_r <= sel_abstractauto;
            sel_progbuf_r <= sel_progbuf;
            sel_haltsum0_r <= sel_haltsum0;
            sel_invalid_addr_r <= sel_invalid_addr;
                     
            progbuf_index_r <= progbuf_index;
            data_index_r <= data_index;         
            hart_halted_r <= hart_halted;
            hart_reset_r <= hart_reset; 
            abstract_busy_r <= abstract_busy;
            abstract_cmderr_r <= abstract_cmderr;
            sel_sbcs_r        <= sel_sbcs;
            sel_sbaddress0_r  <=sel_sbaddress0;            
            sel_sbdata0_r    <=sel_sbdata0;

          end
      end
//.....................
always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin

data0_r  <= 32'h0;
data1_r  <= 32'h0;
data2_r  <= 32'h0;
data3_r  <= 32'h0;
data4_r  <= 32'h0;
data5_r  <= 32'h0;
data6_r  <= 32'h0;
data7_r  <= 32'h0;
data8_r  <= 32'h0;
data9_r  <= 32'h0;
data10_r <= 32'h0;
data11_r <= 32'h0;

            dmcontrol    <= 32'h0;
            command      <= 32'h0;
            abstractauto <= 32'h0;
            sbcs         <= 32'h0;
            sbaddress0   <= 32'h0;
            sbdata0      <= 32'h0;
            haltreq        <= 1'b0;
            resethaltreq   <= 1'b0;
            resumereq      <= 1'b0;
            ndmreset       <= 1'b0;
            dmactive       <= 1'b0;
            cmd_write_pulse<= 1'b0;
            clear_cmderr   <= 1'b0;

                        //SBA signals
             sbcs_write_pulse <= 1'b0;
             sbaddress0_write_pulse   <= 1'b0;
             sbdata0_write_pulse      <= 1'b0;



            progbuf0_r  <= 32'h0; progbuf1_r  <= 32'h0;
            progbuf2_r  <= 32'h0; progbuf3_r  <= 32'h0;
            progbuf4_r  <= 32'h0; progbuf5_r  <= 32'h0;
            progbuf6_r  <= 32'h0; progbuf7_r  <= 32'h0;
            progbuf8_r  <= 32'h0; progbuf9_r  <= 32'h0;
            progbuf10_r <= 32'h0; progbuf11_r <= 32'h0;
            progbuf12_r <= 32'h0; progbuf13_r <= 32'h0;
            progbuf14_r <= 32'h0; progbuf15_r <= 32'h0;

        end else begin

            cmd_write_pulse <= 1'b0;
            clear_cmderr   <= 1'b0;
            haltreq    <= 1'b0;
            resethaltreq    <= 1'b0;
            resumereq <= 1'b0;
            ndmreset  <= 1'b0;
            sbcs_write_pulse <= 1'b0;
            sbaddress0_write_pulse   <= 1'b0;
            sbdata0_write_pulse      <= 1'b0;

       if (ace_data_write) begin

    case (ace_data_index)

        4'd0:  data0_r  <= ace_data_wdata;
        4'd1:  data1_r  <= ace_data_wdata;
        4'd2:  data2_r  <= ace_data_wdata;
        4'd3:  data3_r  <= ace_data_wdata;
        4'd4:  data4_r  <= ace_data_wdata;
        4'd5:  data5_r  <= ace_data_wdata;
        4'd6:  data6_r  <= ace_data_wdata;
        4'd7:  data7_r  <= ace_data_wdata;
        4'd8:  data8_r  <= ace_data_wdata;
        4'd9:  data9_r  <= ace_data_wdata;
        4'd10: data10_r <= ace_data_wdata;
        4'd11: data11_r <= ace_data_wdata;

    endcase
end 
     
if (sbbusy_set)begin
sbcs[21] <= 1'b1;
end

else if (sbbusy_clear)begin
    sbcs[21] <= 1'b0;
end

if (sberror_valid)begin
    sbcs[14:12] <= sberror_set;
end

if (auto_inc_en)begin
    sbaddress0 <= sbaddress0 + auto_inc_value;
end

if (read_data_valid)begin
    sbdata0 <= sba_read_data_out;
end
            if (dmi_write) begin
            
            if (sel_abstractcs_r) begin
                
                if(dmi_wdata_r[10:8] != 3'b000)
                  clear_cmderr <= 1'b1;
             end
                
           

					if (sel_data_r)begin
                 case (data_index_r)

        4'd0:  data0_r  <= dmi_wdata_r;
        4'd1:  data1_r  <= dmi_wdata_r;
        4'd2:  data2_r  <= dmi_wdata_r;
        4'd3:  data3_r  <= dmi_wdata_r;
        4'd4:  data4_r  <= dmi_wdata_r;
        4'd5:  data5_r  <= dmi_wdata_r;
        4'd6:  data6_r  <= dmi_wdata_r;
        4'd7:  data7_r  <= dmi_wdata_r;
        4'd8:  data8_r  <= dmi_wdata_r;
        4'd9:  data9_r  <= dmi_wdata_r;
        4'd10: data10_r <= dmi_wdata_r;
        4'd11: data11_r <= dmi_wdata_r;

    endcase
end   
                    
                if (sel_sbcs_r) begin

               sbcs_write_pulse <= 1'b1;
              sbcs[20] <= dmi_wdata_r[20];
              sbcs[16] <= dmi_wdata_r[16];
              sbcs[15] <= dmi_wdata_r[15];

              if (dmi_wdata_r[22])
              sbcs[22] <= 1'b0;

             if (dmi_wdata_r[14:12] != 3'b000)
             sbcs[14:12] <= 3'b000;
             end

            if (sel_sbaddress0_r) begin
            sbaddress0 <= dmi_wdata_r;
            sbaddress0_write_pulse <= 1'b1;
            end

           if (sel_sbdata0_r) begin
           sbdata0 <= dmi_wdata_r;
           sbdata0_write_pulse <= 1'b1;
           end                
  
                if (sel_dmcontrol_r) begin
                    dmcontrol <= dmi_wdata_r;
                    dmactive  <= dmi_wdata_r[0];
                    ndmreset  <= dmi_wdata_r[1];
                    resethaltreq  <= dmi_wdata_r[3];
                    resumereq <= dmi_wdata_r[30];
                    haltreq   <= dmi_wdata_r[31];
                end

                if (sel_command_r) begin
                    command <= dmi_wdata_r;
                    cmd_write_pulse <= 1'b1;
                end

                if (sel_abstractauto_r) begin
                    abstractauto <= dmi_wdata_r;
                end

                if (sel_progbuf_r) begin
                    case (progbuf_index_r)
                        4'd0:  progbuf0_r  <= dmi_wdata_r;
                        4'd1:  progbuf1_r  <= dmi_wdata_r;
                        4'd2:  progbuf2_r  <= dmi_wdata_r;
                        4'd3:  progbuf3_r  <= dmi_wdata_r;
                        4'd4:  progbuf4_r  <= dmi_wdata_r;
                        4'd5:  progbuf5_r  <= dmi_wdata_r;
                        4'd6:  progbuf6_r  <= dmi_wdata_r;
                        4'd7:  progbuf7_r  <= dmi_wdata_r;
                        4'd8:  progbuf8_r  <= dmi_wdata_r;
                        4'd9:  progbuf9_r  <= dmi_wdata_r;
                        4'd10: progbuf10_r <= dmi_wdata_r;
                        4'd11: progbuf11_r <= dmi_wdata_r;
                        4'd12: progbuf12_r <= dmi_wdata_r;
                        4'd13: progbuf13_r <= dmi_wdata_r;
                        4'd14: progbuf14_r <= dmi_wdata_r;
                        4'd15: progbuf15_r <= dmi_wdata_r;
                     
                    endcase
                end
            end
        end
end

    /* ---------------------------------------------------------- */
    /* read mux                                                   */
    /* ---------------------------------------------------------- */
    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if(!dbg_resetn)begin
        resp_rdata_dbg <= 32'h0;
      end

      else begin

        if (dmi_read) begin

				if (sel_data_r)begin
                case (data_index_r)

        4'd0:  resp_rdata_dbg <= data0_r;
        4'd1:  resp_rdata_dbg <= data1_r;
        4'd2:  resp_rdata_dbg <= data2_r;
        4'd3:  resp_rdata_dbg <= data3_r;
        4'd4:  resp_rdata_dbg <= data4_r;
        4'd5:  resp_rdata_dbg <= data5_r;
        4'd6:  resp_rdata_dbg <= data6_r;
        4'd7:  resp_rdata_dbg <= data7_r;
        4'd8:  resp_rdata_dbg <= data8_r;
        4'd9:  resp_rdata_dbg <= data9_r;
        4'd10: resp_rdata_dbg <= data10_r;
        4'd11: resp_rdata_dbg <= data11_r;

    endcase
    end

            else if (sel_dmcontrol_r)begin
                resp_rdata_dbg <= dmcontrol;
            end

            else if (sel_sbcs_r)
                   resp_rdata_dbg <= sbcs;

            else if (sel_sbaddress0_r)
                  resp_rdata_dbg <= sbaddress0;

            else if (sel_sbdata0_r)
                   resp_rdata_dbg <= sbdata0;



            else if (sel_dmstatus_r)
                resp_rdata_dbg <= {
                    2'h0,
                    9'h0,
                    1'b0,
                    hart_reset_r,
                    hart_reset_r,
                    2'b00,
                    2'b00,
                    2'b00,
                    hart_running_int,
                    hart_running_int,
                    hart_halted_r,
                    hart_halted_r,
                    3'b000,
                    1'b0,
                    4'h2
                };

            else if (sel_hartinfo_r)
                resp_rdata_dbg <= {8'h0,8'h20,16'h1};

            else if (sel_abstractcs_r)
                resp_rdata_dbg <= { 4'h0,4'h0, 4'h0,5'd0,abstract_busy_r,abstract_cmderr_r, 4'h0,4'd2};

            else if (sel_abstractauto_r)
                resp_rdata_dbg <= abstractauto;

            else if (sel_haltsum0_r)
                resp_rdata_dbg <= {31'b0, hart_halted_r};

            else if (sel_progbuf_r) begin

                case (progbuf_index_r)
                    4'd0:  resp_rdata_dbg <= progbuf0_r; 
                    4'd1:  resp_rdata_dbg <= progbuf1_r; 
                    4'd2:  resp_rdata_dbg <= progbuf2_r; 
                    4'd3:  resp_rdata_dbg <= progbuf3_r; 
                    4'd4:  resp_rdata_dbg <= progbuf4_r; 
                    4'd5:  resp_rdata_dbg <= progbuf5_r; 
                    4'd6:  resp_rdata_dbg <= progbuf6_r; 
                    4'd7:  resp_rdata_dbg <= progbuf7_r; 
                    4'd8:  resp_rdata_dbg <= progbuf8_r; 
                    4'd9:  resp_rdata_dbg <= progbuf9_r; 
                    4'd10: resp_rdata_dbg <= progbuf10_r;
                    4'd11: resp_rdata_dbg <= progbuf11_r;
                    4'd12: resp_rdata_dbg <= progbuf12_r;
                    4'd13: resp_rdata_dbg <= progbuf13_r;
                    4'd14: resp_rdata_dbg <= progbuf14_r;
                    4'd15: resp_rdata_dbg <= progbuf15_r;
                   
                endcase
            end
        end
    end
end   
 
 


    /* ---------------------------------------------------------- */
    /* response handshake generation                              */
    /* ---------------------------------------------------------- */
    always @(posedge dbg_clk or negedge dbg_resetn) begin
        if (!dbg_resetn) begin
            resp_valid_dbg <= 1'b0;
            resp_error_dbg <= 1'b0;
        end else begin
            resp_valid_dbg <= 1'b0;

            if ((dmi_read || dmi_write) && any_sel) begin
                resp_valid_dbg <= 1'b1;
                resp_error_dbg <= sel_invalid_addr_r;
            end
        end
    end
    

endmodule


