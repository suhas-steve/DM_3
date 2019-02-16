/*module sba_cdc (

    //====================================================//
    // DEBUG DOMAIN                                       //
    //====================================================//

    input  wire         dbg_clk,
    input  wire         dbg_resetn,

    input  wire         req_valid,
    input  wire         req_write,
    input  wire [31:0]  req_addr,
    input  wire [31:0]  req_wdata,

    output reg          req_ready,

    output reg          resp_valid,
    output reg [31:0]   resp_rdata,
    output reg [1:0]    resp_error,

    //====================================================//
    // AXI DOMAIN                                         //
    //====================================================//

    input  wire         clk,
    input  wire         rst_n,

    output reg          in_valid,
    output reg          write_en,
    output reg          read_en,

    output reg [31:0]   in_address,
    output reg [31:0]   write_data,
    output reg [3:0]    byte_enable,

    input  wire         resp_done,    
    input  wire [31:0]  read_data_out,
    input  wire [1:0]   read_resp,
    input  wire [1:0]   write_resp 

);


wire trans_done;

assign trans_done = resp_done;
       


    //====================================================//
    // REQUEST BUFFER                                     //
    //====================================================//
    reg        req_toggle;
    reg        req_write_buf;
    reg [31:0] req_addr_buf;
    reg [31:0] req_wdata_buf;

reg req_valid_d;

always @(posedge dbg_clk or negedge dbg_resetn)
begin
    if(!dbg_resetn)
        req_valid_d <= 1'b0;
    else
        req_valid_d <= req_valid;
end

wire req_valid_pulse;
assign req_valid_pulse =
       req_valid &
      ~req_valid_d;    
    
    always @(posedge dbg_clk or negedge dbg_resetn)
    begin

        if(!dbg_resetn)
        begin

            req_toggle    <= 1'b0;

            req_ready     <= 1'b0;

            req_write_buf <= 1'b0;
            req_addr_buf  <= 32'd0;
            req_wdata_buf <= 32'd0;

        end
        else
        begin

            req_ready <= 1'b0;

            if(req_valid_pulse)
            begin
            req_write_buf <= req_write;
            req_addr_buf  <= req_addr;
            req_wdata_buf <= req_wdata;
            req_toggle <= ~req_toggle;
            req_ready <= 1'b1;
            
        end

    end
end

    //====================================================//
    // REQUEST TO AXI DOMAIN                              //
    //====================================================//

    reg req_sync_ff1;
    reg req_sync_ff2;

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            req_sync_ff1 <= 1'b0;
            req_sync_ff2 <= 1'b0;

        end
        else
        begin

            req_sync_ff1 <= req_toggle;
            req_sync_ff2 <= req_sync_ff1;

        end

    end

    wire req_pulse;

    assign req_pulse =
            req_sync_ff1 ^
            req_sync_ff2;

    reg req_pulse_d;
    always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        req_pulse_d <= 1'b0;
    else
        req_pulse_d <= req_pulse;
end    

reg req_write_sync_ff1;
reg req_write_sync_ff2;


always @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
    begin

        req_write_sync_ff1 <= 1'b0;
        req_write_sync_ff2 <= 1'b0;

    end
    else
    begin

        req_write_sync_ff1 <= req_write_buf;
        req_write_sync_ff2 <= req_write_sync_ff1;

    end

end


    //====================================================//
    // AXI REQUEST OUTPUTS                                //
    //====================================================//
   
always @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
    begin

        in_valid    <= 1'b0;
        write_en    <= 1'b0;
        read_en     <= 1'b0;

        in_address  <= 32'd0;
        write_data  <= 32'd0;

        byte_enable <= 4'b0000;

    end
    else
    begin

        in_valid <= req_pulse_d;

        write_en <= req_pulse_d &
                    req_write_sync_ff2;

        read_en  <= req_pulse_d &
                   ~req_write_sync_ff2;

        if(req_pulse_d)
        begin

            in_address <= req_addr_buf;
            write_data <= req_wdata_buf;

            byte_enable <= 4'b1111;

        end

    end

end 
    
 
    //====================================================//
    // RESPONSE BUFFER                                    //
    //====================================================//

    reg [31:0] resp_data_buf;
    reg [1:0]  resp_error_buf;
    reg        resp_toggle; 

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            resp_toggle    <= 1'b0;

            resp_data_buf  <= 32'd0;
            resp_error_buf <= 2'd0;

        end
        else
        begin

            if(trans_done)
            begin

                resp_data_buf <= read_data_out;

                if(req_write_sync_ff2)
                    resp_error_buf <= write_resp;
                else
                    resp_error_buf <= read_resp;

                resp_toggle <= ~resp_toggle;

            end

        end

    end

    //====================================================//
    // RESPONSE TO DEBUG DOMAIN                           //
    //====================================================//

    reg resp_sync_ff1;
    reg resp_sync_ff2;

    always @(posedge dbg_clk or negedge dbg_resetn)
    begin

        if(!dbg_resetn)
        begin

            resp_sync_ff1 <= 1'b0;
            resp_sync_ff2 <= 1'b0;

        end
        else
        begin

            resp_sync_ff1 <= resp_toggle;
            resp_sync_ff2 <= resp_sync_ff1;

        end

    end

    wire resp_pulse;

    assign resp_pulse =
            resp_sync_ff1 ^
            resp_sync_ff2;

    //====================================================//
    // RESPONSE TO FSM                                    //
    //====================================================//

    always @(posedge dbg_clk or negedge dbg_resetn)
    begin

        if(!dbg_resetn)
        begin

            resp_valid <= 1'b0;
            resp_rdata <= 32'd0;
            resp_error <= 2'd0;

        end
        else
        begin

            resp_valid <= resp_pulse;

            if(resp_pulse)
            begin

                resp_rdata <= resp_data_buf;
                resp_error <= resp_error_buf;

            end

        end

    end

endmodule
*/
module sba_cdc (

    /*=====================================================*/
    /* DEBUG DOMAIN                                        */
    /*=====================================================*/

    input wire         dbg_clk,
    input wire         dbg_resetn,

    input wire         req_valid,
    input wire         req_write,
    input wire [31:0]  req_addr,
    input wire [31:0]  req_wdata,

    output reg         req_ready,

    output reg         resp_valid,
    output reg [31:0]  resp_rdata,
    output reg [1:0]   resp_error,

    /*=====================================================*/
    /* AXI DOMAIN                                          */
    /*=====================================================*/

    input wire         clk,
    input wire         rst_n,

    output reg         in_valid,
    output reg         write_en,
    output reg         read_en,

    output reg [31:0]  in_address,
    output reg [31:0]  write_data,
    output reg [3:0]   byte_enable,

    input wire         resp_done,
    input wire [31:0]  read_data_out,
    input wire [1:0]   read_resp,
    input wire [1:0]   write_resp

);

wire trans_done;
assign trans_done = resp_done;


/*=====================================================*/
/* REQUEST BUFFER (dbg_clk domain)                    */
/*=====================================================*/

reg        req_toggle;
reg        req_write_buf;
reg [31:0] req_addr_buf;
reg [31:0] req_wdata_buf;

reg req_valid_d;

always @(posedge dbg_clk or negedge dbg_resetn)
begin
    if (!dbg_resetn)
        req_valid_d <= 1'b0;
    else
        req_valid_d <= req_valid;
end

wire req_valid_pulse;
assign req_valid_pulse = req_valid & ~req_valid_d;

always @(posedge dbg_clk or negedge dbg_resetn)
begin
    if (!dbg_resetn)
    begin
        req_toggle    <= 1'b0;
        req_ready     <= 1'b0;
        req_write_buf <= 1'b0;
        req_addr_buf  <= 32'd0;
        req_wdata_buf <= 32'd0;
    end
    else
    begin
        req_ready <= 1'b0;

        if (req_valid_pulse)
        begin
            req_write_buf <= req_write;
            req_addr_buf  <= req_addr;
            req_wdata_buf <= req_wdata;
            req_toggle    <= ~req_toggle;
            req_ready     <= 1'b1;
        end
    end
end


/*=====================================================*/
/* REQUEST CDC        
/*     
/*=====================================================*/

// --- Toggle synchronizer (2-FF) ---
reg req_sync_ff1;
reg req_sync_ff2;

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        req_sync_ff1 <= 1'b0;
        req_sync_ff2 <= 1'b0;
    end
    else
    begin
        req_sync_ff1 <= req_toggle;
        req_sync_ff2 <= req_sync_ff1;
    end
end

wire req_pulse;
assign req_pulse = req_sync_ff1 ^ req_sync_ff2;

reg req_pulse_d;

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        req_pulse_d <= 1'b0;
    else
        req_pulse_d <= req_pulse;
end


reg        req_write_capt;   
reg [31:0] req_addr_capt;    
reg [31:0] req_wdata_capt;   

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        req_write_capt <= 1'b0;
        req_addr_capt  <= 32'd0;
        req_wdata_capt <= 32'd0;
    end
    else
    begin
        if (req_pulse)
        begin
            req_write_capt <= req_write_buf;
            req_addr_capt  <= req_addr_buf;
            req_wdata_capt <= req_wdata_buf;
        end
    end
end


/*========================================================*/
/* AXI REQUEST OUTPUTS                                    */
/*========================================================*/

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        in_valid    <= 1'b0;
        write_en    <= 1'b0;
        read_en     <= 1'b0;
        in_address  <= 32'd0;
        write_data  <= 32'd0;
        byte_enable <= 4'b0000;
    end
    else
    begin
        in_valid <= req_pulse_d;

        write_en <= req_pulse_d &  req_write_capt;
        read_en  <= req_pulse_d & ~req_write_capt;

        if (req_pulse_d)
        begin
            in_address  <= req_addr_capt;
            write_data  <= req_wdata_capt;
            byte_enable <= 4'b1111;
        end
    end
end


/*=====================================================*/
/* RESPONSE BUFFER                                     */
/*=====================================================*/

reg [31:0] resp_data_buf;
reg [1:0]  resp_error_buf;
reg        resp_toggle;

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        resp_toggle    <= 1'b0;
        resp_data_buf  <= 32'd0;
        resp_error_buf <= 2'd0;
    end
    else
    begin
        if (trans_done)
        begin
            resp_data_buf  <= read_data_out;
            resp_error_buf <= req_write_capt ? write_resp : read_resp;
            resp_toggle    <= ~resp_toggle;
        end
    end
end


/*=====================================================*/
/* RESPONSE CDC                                       */ 
 
/*=====================================================*/

// --- Toggle synchronizer (2-FF) ---
reg resp_sync_ff1;
reg resp_sync_ff2;

always @(posedge dbg_clk or negedge dbg_resetn)
begin
    if (!dbg_resetn)
    begin
        resp_sync_ff1 <= 1'b0;
        resp_sync_ff2 <= 1'b0;
    end
    else
    begin
        resp_sync_ff1 <= resp_toggle;
        resp_sync_ff2 <= resp_sync_ff1;
    end
end

wire resp_pulse;
assign resp_pulse = resp_sync_ff1 ^ resp_sync_ff2;


reg [31:0] resp_data_capt;   
reg [1:0]  resp_error_capt;  

always @(posedge dbg_clk or negedge dbg_resetn)
begin
    if (!dbg_resetn)
    begin
        resp_data_capt  <= 32'd0;
        resp_error_capt <= 2'd0;
    end
    else
    begin
        if (resp_pulse)
        begin
            resp_data_capt  <= resp_data_buf;
            resp_error_capt <= resp_error_buf;
        end
    end
end


/*========================================================*/
/* RESPONSE OUTPUTS                                       */
/*========================================================*/

always @(posedge dbg_clk or negedge dbg_resetn)
begin
    if (!dbg_resetn)
    begin
        resp_valid <= 1'b0;
        resp_rdata <= 32'd0;
        resp_error <= 2'd0;
    end
    else
    begin
        resp_valid <= resp_pulse;

        if (resp_pulse)
        begin
            resp_rdata <= resp_data_capt;
            resp_error <= resp_error_capt;
        end
    end
end

endmodule
