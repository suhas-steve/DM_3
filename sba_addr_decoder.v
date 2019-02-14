module sba_address_decoder #(

    parameter PTE_START_ADDR = 32'h0002_4000,
    parameter PTE_END_ADDR   = 32'h0002_4FFF,
    parameter IMEM_START_ADDR = 32'h0000_0000,
    parameter IMEM_END_ADDR   = 32'h1FFF_FFFF,
    parameter DMEM_START_ADDR = 32'h2000_0000,
    parameter DMEM_END_ADDR   = 32'h2FFF_FFFF

    
)(

    /*====================================================*/
    /* CLOCK / RESET                                      */
    /*====================================================*/

    input  wire         clk,
    input  wire         rst_n,
    input wire  boot_load_enable,
    

    /*====================================================*/
    /* FROM SBA CDC                                       */
    /*====================================================*/

    input  wire         in_valid,
    input  wire         write_en,
    input  wire         read_en,

    input  wire [31:0]  in_address,
    input  wire [31:0]  write_data,

    input  wire [3:0]   byte_enable,

    /*====================================================*/
    /* REQUESTS TO MMU / PTE                              */
    /*====================================================*/

    output wire         pte_valid,
    output wire         pte_write_en,
    output wire         pte_read_en,

    output wire [31:0]  pte_address,
    output wire [31:0]  pte_write_data,

    /*====================================================*/
    /* REQUESTS TO AXI WRAPPER                            */
    /*====================================================*/

    output wire         axi_valid,
    output wire         axi_write_en,
    output wire         axi_read_en,

    output wire [31:0]  axi_address,
    output wire [31:0]  axi_write_data,

    output wire [3:0]   axi_byte_enable,

    /*====================================================*/
    /* RESPONSES FROM MMU / PTE                           */
    /*====================================================*/

    input  wire         pte_read_valid,
    input  wire         pte_write_valid,

    input  wire [31:0]  pte_read_data_out,
    input  wire [1:0]   pte_read_resp,
    input  wire [1:0]   pte_write_resp,

    /*====================================================*/
    /* RESPONSES FROM AXI WRAPPER                         */
    /*====================================================*/

    input  wire         axi_read_valid,
    input  wire         axi_write_valid,

    input  wire [31:0]  axi_read_data_out,
    input  wire [1:0]   axi_read_resp,
    input  wire [1:0]   axi_write_resp,

/*====================================================*/
/* REQUESTS TO IMEM                                   */
/*====================================================*/

output wire         imem_valid,
output wire         imem_write_en,

output wire [31:0]  imem_address,
output wire [31:0]  imem_write_data,

/*====================================================*/
/* READ RESPONSE FROM IMEM                            */
/*====================================================*/

input  wire [31:0]  imem_read_data,


/*====================================================*/
/* REQUESTS TO DMEM                                   */
/*====================================================*/

output wire         dmem_valid,
output wire         dmem_write_en,

output wire [31:0]  dmem_address,
output wire [31:0]  dmem_write_data,

/*====================================================*/
/* READ RESPONSE FROM DMEM                            */
/*====================================================*/

input  wire [31:0]  dmem_read_data,


    /*====================================================*/
    /* BACK TO SBA CDC                                    */
    /*====================================================*/

    output wire         resp_valid,

    output wire [31:0]  read_data_out,
    output wire [1:0]   read_resp,
    output wire [1:0]   write_resp

);

    /*====================================================*/
    /* ADDRESS DECODE                                     */
    /*====================================================*/

    wire valid_in_pte;
    wire valid_in_axi;
    wire valid_in_imem;
    wire valid_in_dmem;

reg boot_req_pending;
reg boot_req_write;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        boot_req_pending <= 1'b0;
        boot_req_write   <= 1'b0;
    end
    else if(boot_load_enable && in_valid)
    begin
        boot_req_pending <= 1'b1;
        boot_req_write   <= write_en;
    end
    else if(resp_valid)
    begin
        boot_req_pending <= 1'b0;
    end
end

wire boot_write_resp;
reg  boot_read_resp;

       assign boot_write_resp =
       boot_req_pending &&
       boot_req_write;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        boot_read_resp <= 1'b0;
    else
        boot_read_resp <=
              boot_req_pending &&
             !boot_req_write;
end   
    
    
       assign imem_valid =
       boot_load_enable &
       valid_in_imem;

       assign imem_write_en =
       boot_load_enable &
       write_en &
       valid_in_imem;


       assign dmem_valid =
       boot_load_enable &
       valid_in_dmem;

       assign dmem_write_en =
       boot_load_enable &
       write_en &
       valid_in_dmem;

    assign valid_in_pte =
           in_valid &&
          ((in_address >= PTE_START_ADDR) &&
           (in_address <= PTE_END_ADDR));

assign valid_in_axi =

       in_valid &&

      ~valid_in_pte &&

      ~((boot_load_enable) &&
        (valid_in_imem || valid_in_dmem));


assign valid_in_imem =
       in_valid &&
      ((in_address >= IMEM_START_ADDR) &&
       (in_address <= IMEM_END_ADDR));

assign valid_in_dmem =
       in_valid &&
      ((in_address >= DMEM_START_ADDR) &&
       (in_address <= DMEM_END_ADDR));

   
          

    /*====================================================*/
    /* REQUESTS : MMU / PTE                               */
    /*====================================================*/

    assign pte_valid       = valid_in_pte;

    assign pte_write_en    = write_en &
                             valid_in_pte;

    assign pte_read_en     = read_en &
                             valid_in_pte;

    assign pte_address     = in_address;

    assign pte_write_data  = write_data;

    /*====================================================*/
    /* REQUESTS : AXI WRAPPER                             */
    /*====================================================*/

    assign axi_valid       = valid_in_axi;

    assign axi_write_en    = write_en &
                             valid_in_axi;

    assign axi_read_en     = read_en &
                             valid_in_axi;

    assign axi_address     = in_address;

    assign axi_write_data  = write_data;

    assign axi_byte_enable = byte_enable;

assign imem_address =
       in_address;

assign imem_write_data =
       write_data;

assign dmem_address =
       in_address;

assign dmem_write_data =
       write_data;

   
    

/*====================================================*/
/* RESPONSE MUXING                                    */
/*====================================================*/

 assign resp_valid =

           pte_read_valid  |
           pte_write_valid |

           axi_read_valid  |
           axi_write_valid |

           boot_write_resp |
           boot_read_resp;


/*----------------------------------------------------*/
/* READ RESPONSE PATH                                 */
/*----------------------------------------------------*/

assign read_data_out =

           pte_read_valid ? pte_read_data_out :

           axi_read_valid ? axi_read_data_out :

           (boot_read_resp && valid_in_imem) ?
               imem_read_data :

           (boot_read_resp && valid_in_dmem) ?
               dmem_read_data :

           32'h00000000;

assign read_resp =

           pte_read_valid ? pte_read_resp :

           axi_read_valid ? axi_read_resp :

           boot_read_resp ? 2'b00 :

           2'b00;

/*----------------------------------------------------*/
/* WRITE RESPONSE PATH                                */
/*----------------------------------------------------*/

assign write_resp =
           pte_write_valid ?
           pte_write_resp :
           axi_write_resp;

endmodule


