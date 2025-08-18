
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


    reg                      [7:0] haddr_reg;
    reg                            hwrite_reg;
    reg                            trans_active_reg;
    reg                            wait_bridge;
//    reg                            catch_hrdata;
    wire                           transfer_request;

    assign transfer_request = HSEL && HTRANS[1];

    assign HREADYOUT = !trans_active_reg;

    always @(posedge HCLK or negedge RESETn) begin
        if (!RESETn) begin
            haddr_reg           <= {8{1'b0}};
            hwrite_reg          <= 1'b0;
            trans_active_reg    <= 1'b0;
        end 

        else begin 
            if (HSEL && HTRANS[1] && (!wait_bridge)) begin
                haddr_reg           <= HADDR;
                hwrite_reg          <= HWRITE;
            end
        
            if (!wait_bridge) begin
                trans_active_reg <= transfer_request;  // take the transfer when not waiting
            end
        end
    end


    always @(posedge HCLK or negedge RESETn) begin
        if (!RESETn) begin
            Packet_Out   <= {41{1'b0}};
            H_Valid <= 1'b0;
            wait_bridge <= 1'b0;
        end 
        else begin
            if (transfer_request && !wait_bridge) begin
                Packet_Out   <= {hwrite_reg, HWDATA, haddr_reg}; // packet form
                H_Valid <= 1'b1;
                wait_bridge <= 1'b1;
            end

            if (H_Valid && Bridge_Ready) begin
                H_Valid <= 1'b0;
            end

            if (wait_bridge) begin
                if (hwrite_reg && Bridge_Ready) begin
                    wait_bridge <= 1'b0;
                end

                else if (!hwrite_reg && Bridge_Rd_Valid) begin
                    wait_bridge <= 1'b0;
                end
            end
        end
    end

//    always @(posedge HCLK or negedge RESETn) begin
//        if (!RESETn) begin
//            catch_hrdata <= 1'b0;
//        end 

//        else begin

//            if (Bridge_Rd_Valid) begin
//                catch_hrdata <= 1'b1;
//            end 

//            else begin
//                catch_hrdata <= 1'b0;
//            end
//        end
//    end
    
    always @(posedge HCLK or negedge RESETn) begin
        if(!RESETn)
            HRDATA <= {32{1'b0}};
        else 
            HRDATA <= Bridge_Rd_Data;
    end

endmodule