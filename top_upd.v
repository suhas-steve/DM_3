module debug_module #(

    parameter PTE_START_ADDR = 32'h0002_4000,
    parameter PTE_END_ADDR   = 32'h0002_4FFF,
    parameter IMEM_START_ADDR = 32'h0000_0000,
    parameter IMEM_END_ADDR   = 32'h0000_FFFF,
    parameter DMEM_START_ADDR = 32'h0001_0000,
    parameter DMEM_END_ADDR   = 32'h0001_FFFF

)


(
    // jtag pins
    input  wire        tck,
    input  wire        tms,
    input  wire        tdi,
    input  wire        trst_n,
    output wire        tdo,

  
    // system clock domain
     
    // system / dm interface
  

    input  wire         dbg_clk,
    input  wire         dbg_resetn,
    input  wire [31:0]  dbg_reg_rdata,
    input  wire         dbg_reg_ready,
    input  wire         clk,
    input  wire         rst_n,
    input  wire [31:0]  pte_read_data_out,
    input  wire [1:0]   pte_read_resp,
    input  wire [1:0]   pte_write_resp,
    input  wire [31:0]  axi_read_data_out,
    input  wire [1:0]   axi_read_resp,
    input  wire [1:0]   axi_write_resp,
    input  wire         pte_read_valid,
    input  wire         pte_write_valid,
    input  wire         axi_read_valid,
    input  wire         axi_write_valid,
    input  wire         boot_load_enable,
    input  wire [31:0]  imem_read_data,
    input  wire [31:0]  dmem_read_data,
    input  wire        hart_halted,
    input  wire        hart_reset,

//....................................................
    output wire         pte_valid,
    output wire         pte_write_en,
    output wire         pte_read_en,
    output wire [31:0]  pte_address,
    output wire [31:0]  pte_write_data,
    output wire         axi_valid,
    output wire         axi_write_en,
    output wire         axi_read_en,
    output wire [31:0]  axi_address,
    output wire [31:0]  axi_write_data,
    output wire [3:0]   axi_byte_enable,
    output wire         imem_valid,
    output wire         imem_write_en,
    output wire [31:0]  imem_address,
    output wire [31:0]  imem_write_data,
    output wire         dmem_valid,
    output wire         dmem_write_en,
    output wire [31:0]  dmem_address,
    output wire [31:0]  dmem_write_data,


 
    output wire        pb_insn_valid,
    output wire        [31:0] pb_insn,
    
    output wire         dbg_reg_read,
    output wire         dbg_reg_write,
    output wire [15:0]  dbg_reg_addr,
    output wire [31:0]  dbg_reg_wdata,
    output wire         haltreq,
    output wire         resethaltreq,
    output wire         resumereq,
    output wire         ndmreset


);
   

    // ------------------------------------------------------------
    // tap controller signals
    // ------------------------------------------------------------
    wire capture_ir;
    wire shift_ir;
    wire update_ir;
    wire capture_dr;
    wire shift_dr;
    wire update_dr;

    // ------------------------------------------------------------
    // ir decode enables
    // ------------------------------------------------------------
    wire dmi_enable;
    wire idcode_enable;
    wire bypass_enable;
    wire dtmcs_enable;

    // ------------------------------------------------------------
    // tdo sources
    // ------------------------------------------------------------
    wire ir_tdo;
    wire dmi_tdo;
    wire idcode_tdo;
    wire bypass_tdo;
    wire dtmcs_tdo;

    // ------------------------------------------------------------
    // dmi data register outputs
    // ------------------------------------------------------------
    wire [6:0]  dtm_dmi_addr;
    wire [31:0] dmi_data;
    wire [1:0]  dtm_dmi_op;
    wire        dmi_req_pulse;
    wire        dtm_dmi_reset_pulse;

    // ------------------------------------------------------------
    // dmi fsm <-> cdc <-> response buffer
    // ------------------------------------------------------------
    wire        issue_req;
    wire        tck_resp_pulse;
    wire [31:0] tck_resp_data;
    wire [1:0]  tck_resp_op;

    wire        dtm_resp_valid;
    wire [31:0] resp_data;
    wire [1:0]  resp_op;

    wire dmi_busy;
    wire sticky_busy;
    wire sticky_error;

    wire         dmi_req_valid;
    wire [1:0]   dmi_req_op;
    wire [6:0]   dmi_req_addr;
    wire [31:0]  dmi_req_wdata;

    wire         dmi_resp_valid;
    wire [31:0]  dmi_resp_data;
    wire [1:0]   dmi_resp_op;

    wire        resp_valid_dbg;
     wire [31:0] resp_rdata_dbg;
     wire        resp_error_dbg;

    wire [6:0]  cdc_dmi_req_addr;
    wire [31:0] cdc_dmi_req_data;
    wire [1:0]  cdc_dmi_req_op;
    wire         cdc_dmi_req_pulse;


    // ------------------------------------------------------------
    // jtag tap controller
    // ------------------------------------------------------------
    jtag_tap_controller u_tap (
        .tck        (tck),
        .tms        (tms),
        .trst_n     (trst_n),
        .capture_ir (capture_ir),
        .shift_ir   (shift_ir),
        .update_ir  (update_ir),
        .capture_dr (capture_dr),
        .shift_dr   (shift_dr),
        .update_dr  (update_dr)
    );

    // ------------------------------------------------------------
    // jtag instruction register
    // ------------------------------------------------------------
    jtag_ir u_ir (
        .tck            (tck),
        .trst_n         (trst_n),
        .capture_ir     (capture_ir),
        .shift_ir       (shift_ir),
        .update_ir      (update_ir),
        .tdi            (tdi),
        .tdo            (ir_tdo),
        .bypass_enable  (bypass_enable),
        .idcode_enable  (idcode_enable),
        .dtmcs_enable   (dtmcs_enable),
        .dmi_enable     (dmi_enable)
    );

    // ------------------------------------------------------------
    // bypass data register
    // ------------------------------------------------------------
    DTM_bypass u_bypass (
        .tck        (tck),
        .trst_n     (trst_n),
        .capture_dr (capture_dr & bypass_enable),
        .shift_dr   (shift_dr & bypass_enable), 
        .bypass_enable(bypass_enable),
        .tdi        (tdi),
        .bypass_tdo (bypass_tdo)
    );

    // ------------------------------------------------------------
    // idcode data register
    // ------------------------------------------------------------
    jtag_idcode_dr u_idcode (
        .tck        (tck),
        .trst_n     (trst_n),
        .capture_dr (capture_dr),
        .shift_dr   (shift_dr & idcode_enable),
        .idcode_enable(idcode_enable),
        .tdi        (tdi),
        .idcode_tdo (idcode_tdo)
    );

    // ------------------------------------------------------------
    // dmi data register
    // ------------------------------------------------------------
    dmi_data_register u_dmi_dr (
        .tck            (tck),
        .trst_n         (trst_n),
        .capture_dr     (capture_dr & dmi_enable),
        .shift_dr       (shift_dr & dmi_enable),
        .update_dr      (update_dr & dmi_enable),
        .dmi_enable     (dmi_enable),
        .tdi            (tdi),
        .tdo            (dmi_tdo),
        .dtm_dmi_addr   (dtm_dmi_addr),
        .dmi_data       (dmi_data),
        .dmi_req_pulse  (dmi_req_pulse),
        .dtm_dmi_op     (dtm_dmi_op)
    );

// ------------------------------------------------------------
// DTMCS register
// ------------------------------------------------------------
      dtmcs_register u_dtmcs_reg(
      .tck(tck),
      .trst_n(trst_n),
      .capture_dr(capture_dr),
      .shift_dr(shift_dr),
      .update_dr(update_dr),
      .dtmcs_enable(dtmcs_enable),
      .sticky_busy(sticky_busy),
      .sticky_error(sticky_error),
      .tdi(tdi),
      .dtmcs_tdo(dtmcs_tdo),
      .dtm_dmi_reset_pulse(dtm_dmi_reset_pulse)
  );     
   

    // ------------------------------------------------------------
    // jtag tdo mux
    // ------------------------------------------------------------
    jtag_tdo_mux u_tdo_mux (
        .shift_ir       (shift_ir),
        .shift_dr       (shift_dr),
        .ir_tdo         (ir_tdo),
        .dmi_tdo        (dmi_tdo),
        .idcode_tdo     (idcode_tdo),
        .bypass_tdo     (bypass_tdo),
        .dtmcs_tdo      (dtmcs_tdo),
        .dmi_enable     (dmi_enable),
        .idcode_enable  (idcode_enable),
        .bypass_enable  (bypass_enable),
        .dtmcs_enable   (dtmcs_enable),
        .tdo            (tdo)
    );

    // ------------------------------------------------------------
    // dmi transaction fsm (tck domain)
    // ------------------------------------------------------------
    dmi_transaction_fsm u_dmi_fsm (
        .tck           (tck),
        .trst_n        (trst_n),
        .dmi_req_pulse (dmi_req_pulse),
        .dtm_resp_valid(dtm_resp_valid),
        .resp_op       (resp_op),
        .clr_sticky    (dtm_dmi_reset_pulse),   
        .dmi_busy      (dmi_busy),
        .sticky_busy   (sticky_busy),
        .sticky_error  (sticky_error),
        .issue_req     (issue_req)
    );

    // ------------------------------------------------------------
    // dmi response buffer (tck domain)
    // ------------------------------------------------------------
    dmi_response_buffer u_resp_buf (
        .tck          (tck),
        .trst_n       (trst_n),
        .resp_write   (tck_resp_pulse),
        .resp_data_in (tck_resp_data),
        .resp_op_in   (tck_resp_op),
        .resp_read    (capture_dr & dmi_enable),
        .resp_data    (resp_data),
        .resp_op      (resp_op),
        .dtm_resp_valid(dtm_resp_valid)
    );    


   

    // =====================================================
    // DMI REQUEST
    // =====================================================
      dmi_request u_dmi_request (

        .dbg_clk        (dbg_clk  ),
        .dbg_resetn     (dbg_resetn),

        .dmi_req_pulse     (cdc_dmi_req_pulse),
        .dmi_req_addr_in    (cdc_dmi_req_addr),
        .dmi_req_data_in    (cdc_dmi_req_data),
        .dmi_req_op_in     (cdc_dmi_req_op),

        .resp_valid     (resp_valid_dbg),
        .resp_rdata     (resp_rdata_dbg),
        .resp_error     (resp_error_dbg),


          .dmi_req_valid   (dmi_req_valid),
          .dmi_req_op      (dmi_req_op  ),
          .dmi_req_addr    (dmi_req_addr),
          .dmi_req_wdata   (dmi_req_wdata ),

        .dmi_resp_valid    (dmi_resp_valid),
        .dmi_resp_data     (dmi_resp_data),
        .dmi_resp_op       (dmi_resp_op),

        .dm_busy (dm_busy)
    );
    // =====================================================
    // DECODER
    // =====================================================
    dmi_address_decoder u_decoder (

        .dmi_addr       (dmi_req_addr),
        .dmi_valid      (dmi_req_valid),

        .sel_data      (sel_data),
        .sel_dmcontrol      (sel_dmcontrol),
        .sel_dmstatus      (sel_dmstatus),
        .sel_hartinfo      (sel_hartinfo),
        .sel_abstractcs      (sel_abstractcs),
        .sel_command      (sel_command),
        .sel_abstractauto      (sel_abstractauto),
        .sel_progbuf      (sel_progbuf),
        .sel_haltsum0      (sel_haltsum0),
        .sel_invalid_addr      (sel_invalid_addr),
        .sel_sbcs          (sel_sbcs),
        .sel_sbaddress0    (sel_sbaddress0),
        .sel_sbdata0        (sel_sbdata0)

    );

    //===================================================
    //DTM CDC
    //===================================================
      DTM_cdc u_dtm_cdc (
         .tck      (tck),
         .trst_n   (trst_n),

          .issue_req      (issue_req),
          .dtm_dmi_addr      (dtm_dmi_addr),
          .dmi_data      (dmi_data),
          .dtm_dmi_op      (dtm_dmi_op),

        .tck_resp_pulse     (tck_resp_pulse),
        .tck_resp_data      (tck_resp_data),
        .tck_resp_op        (tck_resp_op),


        .dbg_clk        (dbg_clk  ),
        .dbg_resetn     (dbg_resetn),

        
        .dmi_req_pulse    (cdc_dmi_req_pulse),
        .dmi_req_addr     (cdc_dmi_req_addr),
        .dmi_req_data     (cdc_dmi_req_data),
        .dmi_req_op       (cdc_dmi_req_op),

        .dmi_resp_valid    (dmi_resp_valid),
        .dmi_resp_data     (dmi_resp_data),
        .dmi_resp_op       (dmi_resp_op)
    );


    /* =========================================================
       DMI / CDC INPUTS
       ========================================================= */
    

      /*wire        sel_data;
      wire        sel_dmcontrol;
      wire        sel_dmstatus;
      wire        sel_hartinfo;
      wire        sel_abstractcs;
      wire        sel_command;
      wire        sel_abstractauto;
      wire        sel_progbuf;
      wire        sel_haltsum0;
      wire        sel_invalid_addr;*/
      wire [3:0]  progbuf_index;
      wire [3:0]  data_index;

         

    /* =========================================================
       INTERNAL WIRES
       ========================================================= */

    /* ---- Reset wires ---- */
    wire dm_reset;
    wire hartreset;

    /* ---- DM control ---- */
    wire haltreq;
    wire resethaltreq;
    wire resumereq;
    wire ndmreset;
    wire dmactive;
    wire sbcs_write_pulse;
    wire sbaddress0_write_pulse;
    wire sbdata0_write_pulse;
    wire   [31:0] sbcs;
    wire   [31:0] sbaddress0;
    wire   [31:0] sbdata0;
    wire        sbbusy_set;
    wire        sbbusy_clear;
    wire        sberror_valid;
    wire [2:0]   sberror_set;
    wire         auto_inc_en;
    wire [31:0]  auto_inc_value;
    wire        read_data_valid;
    wire [31:0] sba_read_data_out;
 
    /*----SBA FSM----*/
    wire [1:0] sba_resp_error;
    wire [31:0]sba_req_addr;
    wire sba_req_ready;
    wire sba_resp_valid;
    wire [31:0] sba_resp_rdata;
    wire [31:0] sba_req_wdata;
    wire sba_req_valid;
    wire sba_req_write;
    wire sbbusyerror_set;
    wire         in_valid;
    wire         write_en;
    wire         read_en;
    wire [31:0]  in_address;
    wire [31:0]  write_data;
    wire [3:0]   byte_enable;

    /*---SBA Addr Decoder---*/
    wire         decoder_resp_valid;
    wire [31:0]  decoder_read_data_out;
    wire [1:0]   decoder_read_resp;
    wire [1:0]   decoder_write_resp;
    /* ---- Command path ---- */
    wire        cmd_write_pulse;
    wire [31:0] command;

    /* ---- Abstract engine ---- */
    wire        abstract_busy;
    wire [2:0]  abstract_cmderr;
    wire        execute_progbuf;
    wire        clear_cmderr;
    wire [31:0] ace_data_wdata;
    wire [3:0]  ace_data_index;
    wire        ace_data_write;

    /* ---- Program buffer ---- */
    wire        pb_done;

    /* ---- Program buffer storage ---- */
    wire [31:0] progbuf0,  progbuf1,  progbuf2,  progbuf3;
    wire [31:0] progbuf4,  progbuf5,  progbuf6,  progbuf7;
    wire [31:0] progbuf8,  progbuf9,  progbuf10, progbuf11;
    wire [31:0] progbuf12, progbuf13, progbuf14, progbuf15;
    
    /* --- Data0 - Data11 storage ---- */
    wire [31:0] data0, data1, data2, data3;
    wire [31:0] data4, data5, data6, data7;
    wire [31:0] data8, data9, data10, data11;

     

    /* =========================================================
       RESET CONTROL LOGIC
       ========================================================= */
    dm_reset_ctrl u_dm_reset_ctrl (
        .dbg_clk    (dbg_clk),
        .dbg_resetn (dbg_resetn),
        .dmactive   (dmactive),
        .ndmreset   (ndmreset),
        .dm_reset   (dm_reset)
    );

    /* =========================================================
       DEBUG MODULE REGISTER FILE
       ========================================================= */
    DM_reg u_dm_regfile (
        .dbg_clk      (dbg_clk),
        .dbg_resetn   (dbg_resetn),

        /* DMI */
        .dmi_wdata    (dmi_req_wdata),
        .dmi_op       (dmi_req_op),

        /* Decoder selects */
        .sel_data         (sel_data),
        .sel_dmcontrol    (sel_dmcontrol),
        .sel_dmstatus     (sel_dmstatus),
        .sel_hartinfo     (sel_hartinfo),
        .sel_abstractcs   (sel_abstractcs),
        .sel_command      (sel_command),
        .sel_abstractauto (sel_abstractauto),
        .sel_progbuf      (sel_progbuf),
        .sel_haltsum0     (sel_haltsum0),
        .sel_invalid_addr (sel_invalid_addr),

        .progbuf_index (progbuf_index),
        .data_index    (data_index),

        /* From other DM blocks */
        .hart_halted     (hart_halted),
        .hart_reset      (hart_reset),
        .hart_running   (hart_running),
        .abstract_busy  (abstract_busy),
        .abstract_cmderr(abstract_cmderr),
        .sel_sbcs       (sel_sbcs),
        .sel_sbaddress0 (sel_sbaddress0),
        .sel_sbdata0    (sel_sbdata0),
        .sbcs_write_pulse(sbcs_write_pulse),
        .sbaddress0_write_pulse(sbaddress0_write_pulse),
        .sbdata0_write_pulse(sbdata0_write_pulse),
        .sbcs(sbcs),
        .sbaddress0(sbaddress0),
        .sbdata0(sbdata0),
        .ace_data_wdata(ace_data_wdata),
        .ace_data_index(ace_data_index),
        .ace_data_write(ace_data_write),
        .sbbusy_set(sbbusy_set),
        .sbbusy_clear(sbbusy_clear),
        .sberror_valid(sberror_valid),
        .sberror_set(sberror_set),
        .auto_inc_en(auto_inc_en),
        .auto_inc_value(auto_inc_value),
        .read_data_valid(read_data_valid),
        .sba_read_data_out(sba_read_data_out),

        /* Response to DMI */
        .resp_valid_dbg (resp_valid_dbg),
        .resp_rdata_dbg (resp_rdata_dbg),
        .resp_error_dbg (resp_error_dbg),

        /* Control outputs */
        .haltreq         (haltreq),
        .resethaltreq    (resethaltreq),
        .resumereq      (resumereq),
        .ndmreset       (ndmreset),
        .dmactive       (dmactive),
        .cmd_write_pulse(cmd_write_pulse),
        .clear_cmderr   (clear_cmderr),
        .command        (command),

        /* Program buffer storage */
        .progbuf0 (progbuf0),   .progbuf1 (progbuf1),
        .progbuf2 (progbuf2),   .progbuf3 (progbuf3),
        .progbuf4 (progbuf4),   .progbuf5 (progbuf5),
        .progbuf6 (progbuf6),   .progbuf7 (progbuf7),
        .progbuf8 (progbuf8),   .progbuf9 (progbuf9),
        .progbuf10(progbuf10),  .progbuf11(progbuf11),
        .progbuf12(progbuf12),  .progbuf13(progbuf13),
        .progbuf14(progbuf14),  .progbuf15(progbuf15),

        /* Data0 - Data11 storage */
        .data0 (data0),  .data1(data1),
        .data2 (data2),  .data3(data3),
        .data4 (data4),  .data5(data5),
        .data6 (data6),  .data7(data7),
        .data8 (data8),  .data9(data9),
        .data10(data10), .data11(data11)
    );

    /* =========================================================
       ABSTRACT COMMAND ENGINE
       ========================================================= */
    DM_ace u_ace (
        .dbg_clk         (dbg_clk),
        .dbg_resetn      (~dm_reset),
        .cmd_write_pulse (cmd_write_pulse),
        .command         (command),
        .hart_halted     (hart_halted),
        .pb_done         (pb_done),
        .execute_progbuf (execute_progbuf),
        .abstract_busy   (abstract_busy),
        .abstract_cmderr (abstract_cmderr),
        .clear_cmderr(clear_cmderr),
        .data0(data0),
        .data1(data1),
        .data2(data2),
        .data3(data3),
        .data4(data4),
        .data5(data5),
        .data6(data6),
        .data7(data7),
        .data8(data8),
        .data9(data9),
        .data10(data10),
        .data11(data11),
        .ace_data_wdata(ace_data_wdata),
        .ace_data_index(ace_data_index),
        .ace_data_write(ace_data_write),
        .dbg_reg_read(dbg_reg_read),
        .dbg_reg_write(dbg_reg_write),
        .dbg_reg_addr(dbg_reg_addr),
        .dbg_reg_wdata(dbg_reg_wdata),
        .dbg_reg_rdata(dbg_reg_rdata),
        .dbg_reg_ready(dbg_reg_ready)        
    );

    /* =========================================================
       PROGRAM BUFFER
       ========================================================= */
    dm_program_buffer u_program_buffer (
        .dbg_clk        (dbg_clk),
        .dbg_resetn     (~dm_reset),
        .execute_progbuf(execute_progbuf),
        .hart_halted    (hart_halted),

        .progbuf0 (progbuf0),   .progbuf1 (progbuf1),
        .progbuf2 (progbuf2),   .progbuf3 (progbuf3),
        .progbuf4 (progbuf4),   .progbuf5 (progbuf5),
        .progbuf6 (progbuf6),   .progbuf7 (progbuf7),
        .progbuf8 (progbuf8),   .progbuf9 (progbuf9),
        .progbuf10(progbuf10),  .progbuf11(progbuf11),
        .progbuf12(progbuf12),  .progbuf13(progbuf13),
        .progbuf14(progbuf14),  .progbuf15(progbuf15),

        .pb_insn       (pb_insn),
        .pb_insn_valid (pb_insn_valid),
        .pb_done       (pb_done)
    );


  /* =========================================================
       SBA CONTROL FSM
     ========================================================= */
    sba_control_fsm u_sba_fsm (
        .dbg_clk      (dbg_clk),
        .dbg_resetn   (dbg_resetn),
        .sbcs_write_pulse(sbcs_write_pulse),
        .sbaddress0_write_pulse(sbaddress0_write_pulse),
        .sbdata0_write_pulse(sbdata0_write_pulse),
        .sbcs(sbcs),
        .sbaddress0(sbaddress0),
        .sbdata0(sbdata0),
        .sba_req_ready(sba_req_ready),
        .sba_resp_valid(sba_resp_valid),
        .sba_resp_rdata(sba_resp_rdata),
        .sba_resp_error(sba_resp_error),
        .sba_req_valid(sba_req_valid),
        .sba_req_write(sba_req_write),
        .sba_req_addr(sba_req_addr),  
        .sba_req_wdata(sba_req_wdata),
        .sbbusy_set(sbbusy_set),
        .sbbusy_clear(sbbusy_clear),
        .sbbusyerror_set(sbbusyerror_set),
        .sberror_set(sberror_set),
        .sberror_valid(sberror_valid),
        .auto_inc_en(auto_inc_en),
        .auto_inc_value(auto_inc_value),
        .sba_read_data_out(sba_read_data_out),
        .read_data_valid(read_data_valid)

    );

   
    /* =========================================================
       SBA CDC
       ========================================================= */
        sba_cdc u_cdc_sba (
        .dbg_clk      (dbg_clk),
        .dbg_resetn   (dbg_resetn),
        .req_valid    (sba_req_valid),
        .req_write    (sba_req_write),
        .req_addr     (sba_req_addr),
        .req_wdata    (sba_req_wdata),
        .req_ready    (sba_req_ready),
        .resp_valid   (sba_resp_valid),
        .resp_rdata   (sba_resp_rdata),
        .resp_error   (sba_resp_error),
        .clk          (clk),
        .rst_n        (rst_n),
        .in_valid     (in_valid),
        .write_en     (write_en),
        .read_en      (read_en),
        .in_address  (in_address),
        .write_data   (write_data),
        .byte_enable  (byte_enable),
        .resp_done    (decoder_resp_valid),
        .read_data_out(decoder_read_data_out),
        .read_resp    (decoder_read_resp),
        .write_resp   (decoder_write_resp)
           
    );

/* =========================================================
       SBA Addr Decoder
   ========================================================= */
sba_address_decoder #(

        .PTE_START_ADDR (PTE_START_ADDR) ,
        .PTE_END_ADDR  (PTE_END_ADDR),
        .IMEM_START_ADDR (IMEM_START_ADDR),
        .IMEM_END_ADDR   (IMEM_END_ADDR),
        .DMEM_START_ADDR (DMEM_START_ADDR),
        .DMEM_END_ADDR   (DMEM_END_ADDR)

) u_sba_address_decoder (

    .clk               (clk),
    .rst_n             (rst_n),
    .in_valid          (in_valid),
    .write_en          (write_en),
    .read_en           (read_en),

    .in_address        (in_address),
    .write_data        (write_data),
    .byte_enable       (byte_enable),
    .pte_valid         (pte_valid),
    .pte_write_en      (pte_write_en),
    .pte_read_en       (pte_read_en),

    .pte_address       (pte_address),
    .pte_write_data    (pte_write_data),
    .axi_valid         (axi_valid),
    .axi_write_en      (axi_write_en),
    .axi_read_en       (axi_read_en),
    .axi_address       (axi_address),
    .axi_write_data    (axi_write_data),
    .axi_byte_enable   (axi_byte_enable),
    .pte_read_valid    (pte_read_valid), 
    .pte_write_valid   (pte_write_valid), 
    .pte_read_data_out (pte_read_data_out), 
    .pte_read_resp     (pte_read_resp), 
    .pte_write_resp    (pte_write_resp), 
    .axi_read_valid (axi_read_valid), 
    .axi_write_valid (axi_write_valid), 
    .axi_read_data_out (axi_read_data_out), 
    .axi_read_resp (axi_read_resp), 
    .axi_write_resp (axi_write_resp),    
    .resp_valid        (decoder_resp_valid),
    .read_data_out     (decoder_read_data_out),
    .read_resp         (decoder_read_resp),
    .write_resp        (decoder_write_resp),
    .imem_valid        (imem_valid),
    .imem_write_en     (imem_write_en),
    .imem_address      (imem_address),
    .imem_write_data   (imem_write_data),
    .imem_read_data    (imem_read_data),
    .dmem_valid        (dmem_valid),
    .dmem_write_en     (dmem_write_en),
    .dmem_address      (dmem_address),
    .dmem_write_data   (dmem_write_data),
    .dmem_read_data    (dmem_read_data),
    .boot_load_enable  (boot_load_enable)

);



assign progbuf_index  =dmi_req_addr[3:0];
assign data_index = dmi_req_addr[3:0]- 4'h4;
endmodule





