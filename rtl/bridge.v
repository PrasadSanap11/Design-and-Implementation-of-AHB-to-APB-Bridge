module bridge (

    // -------------AHB_SLAVE - BRIDGE-----------------
    input  wire                      HCLK,
    input  wire                      RESETn,
    input  wire [40:0]               Packet_IN,
    input  wire                      H_Valid,
    output reg                       Bridge_Ready,  // !full flag
    output wire [31:0]               Bridge_Rd_Data,    
    output reg                       Bridge_Rd_Valid, // !empty flag

    // -------------APB_MASTER - BRIDGE----------------
    input  wire                      PCLK,
    input  wire                      Packet_Read_en,
    input  wire [31:0]               Data_IN,
    input  wire                      Data_Write_en,
    output wire [40:0]               Packet_out,
    output reg                       P_Valid,
    output wire                      Read_fifo_full
);

    
    wire wr_fifo_full;
    wire wr_fifo_empty;
    wire rd_fifo_empty;

    
    async_fifo #(
        .DATASIZE(41),
        .ADDRSIZE(4)
    ) WRITE_FIFO (
        .wdata (Packet_IN),
        .winc (H_Valid),
        .wclk (HCLK),
        .wrst_n (RESETn),
        .wfull (wr_fifo_full),
        .rdata (Packet_out),
        .rinc (Packet_Read_en),
        .rclk (PCLK),
        .rrst_n (RESETn),
        .rempty (wr_fifo_empty)
    );

    
    async_fifo #(
        .DATASIZE(32),
        .ADDRSIZE(4)
    ) READ_FIFO (
        .wdata (Data_IN),
        .winc (Data_Write_en),
        .wclk (PCLK),
        .wrst_n (RESETn),
        .wfull (Read_fifo_full),
        .rdata (Bridge_Rd_Data),
        .rinc (!rd_fifo_empty), // Always read from response FIFO if not empty
        .rclk (HCLK),
        .rrst_n (RESETn),
        .rempty (rd_fifo_empty)
    );

     always @(posedge HCLK or negedge RESETn) begin
         if(!RESETn) begin
             Bridge_Ready <= 0;
             P_Valid <= 0;
             Bridge_Rd_Valid <= 0;
         end else begin
             Bridge_Ready <= !wr_fifo_full;
             P_Valid <= !wr_fifo_empty;
             Bridge_Rd_Valid <= !rd_fifo_empty;
         end
     end

endmodule