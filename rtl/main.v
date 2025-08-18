module main (
    
    input  wire                      HCLK,
    input  wire                      PCLK,
    input  wire                      RESETn,
    input  wire                      HSEL,
    input  wire                [7:0] HADDR,
    input  wire               [31:0] HWDATA,
    input  wire                      HWRITE,
    input  wire                [1:0] HTRANS,
    output wire               [31:0] HRDATA,
    output wire                      HREADYOUT
    
);


    // --- Wires between AHB_SLAVE and BRIDGE ---
    wire               [40:0] ahb_packet;
    wire                      h_valid;
    wire                      bridge_ready;
    wire               [31:0] read_data;
    wire                      read_data_valid;

    // --- Wires between BRIDGE and APB_MASTER ---
    wire               [40:0] apb_packet;
    wire                      p_valid;
    wire                      apb_read_en;
    wire               [31:0] apb_data;
    wire                      apb_write_en;
    wire                      fifo_full;

    // --- Wires between APB_MASTER and APB_SLAVE ---
    wire                [7:0] paddr;
    wire                      psel;
    wire                      penable;
    wire                      pwrite;
    wire               [31:0] pwdata;
    wire               [31:0] prdata;
    wire                      pready;


    
    ahb_slave u_ahb_slave (
        .HCLK(HCLK), .RESETn(RESETn), .HSEL(HSEL), 
        .HADDR(HADDR), .HWDATA(HWDATA),
        .HWRITE(HWRITE), .HTRANS(HTRANS),
        .HRDATA(HRDATA), .HREADYOUT(HREADYOUT),
        .Packet_Out (ahb_packet),  
        .H_Valid (h_valid),
        .Bridge_Ready (bridge_ready),
        .Bridge_Rd_Data (read_data),
        .Bridge_Rd_Valid (read_data_valid)
    );

    
    bridge u_bridge (
        .HCLK (HCLK), .RESETn (RESETn),
        .Packet_IN (ahb_packet),
        .H_Valid (h_valid),
        .Bridge_Ready (bridge_ready),
        .Bridge_Rd_Data (read_data),
        .Bridge_Rd_Valid (read_data_valid),
        .PCLK (PCLK),
        .Packet_out (apb_packet),
        .P_Valid (p_valid),
        .Packet_Read_en (apb_read_en),
        .Data_IN (apb_data),
        .Data_Write_en (apb_write_en),
        .Read_fifo_full (fifo_full)
    );


    apb_master u_apb_master (
        .PCLK(PCLK), .RESETn(RESETn),
        .Packet_IN (apb_packet),
        .P_Valid (p_valid),
        .Packet_Read_en (apb_read_en),
        .Data_Out (apb_data),
        .Data_Write_en (apb_write_en),
        .Read_fifo_full(fifo_full),
        .PADDR (paddr), .PSEL (psel), .PENABLE (penable),
        .PWRITE (pwrite), .PWDATA (pwdata),
        .PRDATA (prdata), .PREADY (pready)
    );


    apb_slave u_apb_memory (
        .PCLK(PCLK), .RESETn(RESETn),
        .PADDR(paddr), .PSEL(psel), .PENABLE(penable),
        .PWRITE(pwrite), .PWDATA(pwdata),
        .PRDATA(prdata), .PREADY(pready)
    );

endmodule
