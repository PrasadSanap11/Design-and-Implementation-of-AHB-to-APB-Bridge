
module apb_master (

    // ---------------APB_MASTER - BRIDGE---------------------
    input  wire                      PCLK,
    input  wire                      RESETn,
    input  wire               [40:0] Packet_IN,
    input  wire                      P_Valid,
    input  wire                      Read_fifo_full,
    output reg                       Packet_Read_en,
    output wire               [31:0] Data_Out,
    output reg                       Data_Write_en,
    

    // ---------APB_MASTER - APB_SLAVE-----------------------
    input  wire               [31:0] PRDATA,
    input  wire                      PREADY,
    output reg                 [7:0] PADDR,
    output reg                       PSEL,
    output reg                       PENABLE,
    output reg                       PWRITE,
    output reg                [31:0] PWDATA
    
);

    localparam IDLE   = 2'b00, SETUP  = 2'b01, ACCESS = 2'b10;

    reg [1:0] state, next_state;
    reg [40:0] packet_reg;

    wire transfer_request;
    wire write;
    wire [31:0] wdata;
    wire [7:0] address;

    assign transfer_request = P_Valid;
    assign write = packet_reg [40];
    assign wdata = packet_reg [39:8];
    assign address = packet_reg [7:0];
    
    always @(posedge PCLK or negedge RESETn) begin
        if(!RESETn)
            packet_reg <= 0;
        else 
            packet_reg <= Packet_IN;
    end

    always @(posedge PCLK or negedge RESETn) begin
        if (!RESETn) 
            state <= IDLE;
        else          
            state <= next_state;
    end

    always @(*) begin
        next_state = state;

        case (state)

            IDLE: if (transfer_request) 
                    next_state = SETUP;

            SETUP:  next_state = ACCESS;

            ACCESS: begin
                if (PREADY) begin
                    if (transfer_request) begin
                        next_state = SETUP;
                    end
                    else begin
                        next_state = IDLE;
                    end
                end
            end
        endcase
    end


    always @(*) begin

        PSEL = 1'b0;
        PENABLE = 1'b0;
        PADDR = address;
        PWRITE = write;
        PWDATA = wdata;
        Data_Write_en = 1'b0;   // put this in the default case instead

        case (state)
            IDLE: begin
                PSEL = 1'b0;
            end

            SETUP: begin
                PSEL = 1'b1;
                PENABLE = 1'b0;
            end

            ACCESS: begin
                PSEL = 1'b1;
                PENABLE = 1'b1;

                if (PREADY && !write && !Read_fifo_full) begin
                    Data_Write_en = 1'b1;
                end
            end
        endcase
    end


    always @(posedge PCLK or negedge RESETn) begin
        if (!RESETn) begin
            Packet_Read_en <= 1'b0;
        end 

        else begin
            Packet_Read_en <= 1'b0;

            if (state == IDLE && transfer_request) begin
                Packet_Read_en <= 1'b1;
            end
            
            else if (state == ACCESS && PREADY && transfer_request) begin
                Packet_Read_en <= 1'b1;
            end

            
        end
    end

    assign Data_Out = PRDATA;

endmodule
