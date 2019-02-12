module sba_control_fsm (

    input  wire         dbg_clk,
    input  wire         dbg_resetn,

    /* --------------------------------------------------------- */
    /* From DM REGFILE                                           */
    /* --------------------------------------------------------- */

    input  wire         sbcs_write_pulse,
    input  wire         sbaddress0_write_pulse,
    input  wire         sbdata0_write_pulse,

    input  wire [31:0]  sbcs,
    input  wire [31:0]  sbaddress0,
    input  wire [31:0]  sbdata0,

    /* --------------------------------------------------------- */
    /* From AXI MASTER / CDC                                     */
    /* --------------------------------------------------------- */

    input  wire         sba_req_ready,

    input  wire         sba_resp_valid,
    input  wire [31:0]  sba_resp_rdata,
    input  wire [1:0]   sba_resp_error,

    /* --------------------------------------------------------- */
    /* To AXI MASTER / CDC                                       */
    /* --------------------------------------------------------- */

    output reg          sba_req_valid,
    output reg          sba_req_write,

    output reg [31:0]   sba_req_addr,
    output reg [31:0]   sba_req_wdata,

    /* --------------------------------------------------------- */
    /* To DM REGFILE                                             */
    /* --------------------------------------------------------- */

    output reg          sbbusy_set,
    output reg          sbbusy_clear,

    output reg          sbbusyerror_set,

    output reg [2:0]    sberror_set,
    output reg          sberror_valid,

    output reg          auto_inc_en,
    output reg [31:0]   auto_inc_value,

    output reg [31:0]   sba_read_data_out,
    output reg          read_data_valid

);

    /* ========================================================= */
    /* STATE DECLARATION                                         */
    /* ========================================================= */

    parameter  IDLE           = 3'b000;
    parameter  REQ_SEND       = 3'b001;
    parameter  WAIT_ACCEPT    = 3'b010;
    parameter  WAIT_RESPONSE  = 3'b011;
    parameter  COMPLETE       = 3'b100;
    parameter  ERROR          = 3'b101;

    reg [2:0] current_state;
    reg [2:0] next_state;
    reg [31:0] req_addr_hold;
    reg [31:0] req_wdata_hold;
    reg        req_write_hold;

    /* ========================================================= */
    /* INTERNAL SIGNALS                                          */
    /* ========================================================= */

    wire sbreadonaddr;
    wire sbautoincrement;
    wire sbreadondata;

    assign sbreadonaddr    = sbcs[20];
    assign sbautoincrement = sbcs[16];
    assign sbreadondata    = sbcs[15];


    /* ========================================================= */
    /* REQUEST DETECTION                                         */
    /* ========================================================= */

    wire write_request;
    wire read_request;
    wire auto_read_request;

    assign write_request =
                sbdata0_write_pulse;

    assign read_request =
                sbaddress0_write_pulse &&
                sbreadonaddr;

    assign auto_read_request =
           sbdata0_write_pulse && sbreadondata;
    /* ========================================================= */
    /* STATE REGISTER                                            */
    /* ========================================================= */

    always @(posedge dbg_clk or negedge dbg_resetn) begin

        if (!dbg_resetn)
            current_state <= IDLE;

        else
            current_state <= next_state;

    end


    /* ========================================================= */
    /* NEXT STATE LOGIC                                          */
    /* ========================================================= */

    always @(current_state or write_request or read_request or auto_read_request or sba_req_ready or sba_resp_valid or sba_resp_error or sbautoincrement) begin
    
        
        next_state = current_state;

        case (current_state)

            /* ------------------------------------------------- */
            /* IDLE                                              */
            /* ------------------------------------------------- */

            IDLE : begin
            
             if (write_request ||
        read_request  ||
        auto_read_request)
        next_state = REQ_SEND;

        end    

                          

            /* ------------------------------------------------- */
            /* REQ_SEND                                          */
            /* ------------------------------------------------- */

            REQ_SEND : begin

                next_state = WAIT_ACCEPT;

            end


            /* ------------------------------------------------- */
            /* WAIT_ACCEPT                                       */
            /* ------------------------------------------------- */

            WAIT_ACCEPT :
            begin

            if (sba_req_ready)
        next_state = WAIT_RESPONSE;    
            
            end
          

            /* ------------------------------------------------- */
            /* WAIT_RESPONSE                                     */
            /* ------------------------------------------------- */

            WAIT_RESPONSE : begin

                if (sba_resp_valid) begin

                    if (sba_resp_error == 2'b00)
                        next_state = COMPLETE;

                    else
                        next_state = ERROR;

                end

            end


            /* ------------------------------------------------- */
            /* COMPLETE                                          */
            /* ------------------------------------------------- */

            COMPLETE : begin

                next_state = IDLE;

            end


            /* ------------------------------------------------- */
            /* ERROR                                             */
            /* ------------------------------------------------- */

            ERROR : begin

                next_state = IDLE;

            end

            default :
                next_state = IDLE;

        endcase

    end


    /* ========================================================= */
    /* OUTPUT LOGIC                                              */
    /* ========================================================= */

    always @(posedge dbg_clk or negedge dbg_resetn) begin

        if (!dbg_resetn) begin

            sba_req_valid         <= 1'b0;
            sba_req_write         <= 1'b0;

            sba_req_addr          <= 32'h0;
            sba_req_wdata         <= 32'h0;
            
            req_addr_hold  <= 32'h0;
            req_wdata_hold <= 32'h0;
            req_write_hold <= 1'b0;

            sbbusy_set        <= 1'b0;
            sbbusy_clear      <= 1'b0;

            sbbusyerror_set   <= 1'b0;

            sberror_set       <= 3'b000;
            sberror_valid     <= 1'b0;

            auto_inc_en       <= 1'b0;
            auto_inc_value    <= 32'h0;

        sba_read_data_out     <= 32'h0;
            read_data_valid   <= 1'b0;

        end

        else begin

            /* ------------------------------------------------- */
            /* DEFAULTS                                          */
            /* ------------------------------------------------- */

            sba_req_valid         <= 1'b0;

            sbbusy_set        <= 1'b0;
            sbbusy_clear      <= 1'b0;

            sbbusyerror_set   <= 1'b0;

            sberror_valid     <= 1'b0;

            auto_inc_en       <= 1'b0;

            read_data_valid   <= 1'b0;

            sberror_set <= 3'b000;
            sba_req_write <= 1'b0;


            case (current_state)

                /* --------------------------------------------- */
                /* IDLE                                          */
                /* --------------------------------------------- */
                
                IDLE : begin
                    
if (sbaddress0_write_pulse)
    req_addr_hold <= sbaddress0;

    if (write_request) begin

        req_wdata_hold <= sbdata0;
        req_write_hold <= 1'b1;

        sbbusy_set <= 1'b1;

    end

    else if (read_request || auto_read_request) begin

        req_addr_hold  <= sbaddress0;
        req_wdata_hold <= 32'h0;
        req_write_hold <= 1'b0;

        sbbusy_set <= 1'b1;

    end

end
                 


                /* --------------------------------------------- */
                /* REQ_SEND                                      */
                /* --------------------------------------------- */

                REQ_SEND : begin

                sba_req_valid <= 1'b1;
                sba_req_addr  <= req_addr_hold;
                sba_req_wdata <= req_wdata_hold;
                sba_req_write <= req_write_hold;
                
                end
                                        
                /* --------------------------------------------- */
                /* WAIT_ACCEPT                                   */
                /* --------------------------------------------- */

                WAIT_ACCEPT : begin

                    sba_req_valid <= 1'b1;
                    sba_req_addr  <= req_addr_hold;
                    sba_req_wdata <= req_wdata_hold;
                    sba_req_write <= req_write_hold;

                    end

                /* --------------------------------------------- */
                /* WAIT_RESPONSE                                 */
                /* --------------------------------------------- */

                WAIT_RESPONSE : begin

                    if (sba_resp_valid &&sba_resp_error == 2'b00) begin

                        sba_read_data_out   <= sba_resp_rdata;
                        read_data_valid <= 1'b1;

                    end

                end


                /* --------------------------------------------- */
                /* COMPLETE                                      */
                /* --------------------------------------------- */

                COMPLETE : begin

                    sbbusy_clear <= 1'b1;

                    if (sbautoincrement) begin

                        auto_inc_en    <= 1'b1;
                        auto_inc_value <= 32'h4;

                    end

                end


                /* --------------------------------------------- */
                /* ERROR                                         */
                /* --------------------------------------------- */

                ERROR : begin

                    sbbusy_clear <= 1'b1;

                    sberror_valid <= 1'b1;

                    case (sba_resp_error)

                        2'b10 :
                            sberror_set <= 3'b010;

                        2'b11 :
                            sberror_set <= 3'b011;

                        default :
                            sberror_set <= 3'b001;

                    endcase

                end

            endcase

        end

    end

endmodule
