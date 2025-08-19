module ahb_slave (
    // -----------AHB_MASTER - AHB_SLAVE-------------
    input  wire                  HCLK,
    input  wire                  RESETn,
    input  wire                  HSEL,
    input  wire            [7:0] HADDR,
    input  wire           [31:0] HWDATA,
    input  wire                  HWRITE,
    input  wire            [1:0] HTRANS,

    output reg            [31:0] HRDATA,
    output wire                  HREADYOUT,

    // ----------AHB_SLAVE - BRIDGE------------------- 
    input  wire                    Bridge_Ready,
    input  wire             [31:0] Bridge_Rd_Data,
    input  wire                    Bridge_Rd_Valid,
    output reg              [40:0] Packet_Out,
    output reg                     H_Valid
);


    localparam IDLE  = 2'b00, ACTIVE = 2'b01, WAIT   = 2'b10;

    reg [1:0] state, next_state;
    reg [7:0] haddr_reg;
    reg       hwrite_reg;
    wire      transfer_request;

    assign transfer_request = HSEL && HTRANS[1];

    assign HREADYOUT = (state != WAIT);

    always @(posedge HCLK or negedge RESETn) begin
        if (!RESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (transfer_request)
                    next_state = ACTIVE;
            end
            ACTIVE: begin
                next_state = WAIT;
            end
            WAIT: begin
                if (hwrite_reg && Bridge_Ready)
                    next_state = IDLE;
                else if (!hwrite_reg && Bridge_Rd_Valid)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    always @(posedge HCLK or negedge RESETn) begin
        if (!RESETn) begin
            haddr_reg    <= {8{1'b0}};
            hwrite_reg   <= 1'b0;
            Packet_Out   <= {41{1'b0}};
            H_Valid      <= 1'b0;
            HRDATA       <= {32{1'b0}};
        end
        else begin
            case (state)
                IDLE: begin
                    H_Valid <= 1'b0;
                    if (transfer_request) begin
                        haddr_reg  <= HADDR;
                        hwrite_reg <= HWRITE;
                    end
                end
                ACTIVE: begin
                    Packet_Out <= {hwrite_reg, HWDATA, haddr_reg};
                    H_Valid    <= 1'b1;
                end
                WAIT: begin
                    H_Valid <= 1'b0;
                    HRDATA <= Bridge_Rd_Data;
                end
            endcase
        end
    end

endmodule
