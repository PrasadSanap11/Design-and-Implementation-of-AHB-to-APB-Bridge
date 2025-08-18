module apb_slave (

       input  wire          PCLK,
       input  wire          RESETn,
       input  wire          PWRITE,
       input  wire          PSEL,
       input  wire          PENABLE,
       input  wire    [7:0] PADDR,
       input  wire   [31:0] PWDATA,
       output reg           PREADY,
       output reg    [31:0] PRDATA

    );

  reg [2:0] wait_count = 0;
 
  reg [31:0] mem [255:0];   //  memeory size is 1KB


 always @(posedge PCLK or negedge RESETn)begin

    if(!RESETn) begin
        PREADY <= 1;
        PRDATA <= 32'b0;
        wait_count <= 2'b00;      
    end

    else begin
   
        if(PSEL == 1)begin
                   
            if(PENABLE == 1) begin
                     
                if (wait_count < 2) begin
                    PREADY <= 0;                
                    wait_count <= wait_count + 1;   
                end
                else begin

                    if(PWRITE == 1) begin
                        mem[PADDR] <= PWDATA;
                        PREADY <= 1;
                    end
                    else if(PWRITE == 0) begin                    
                        PRDATA <= mem[PADDR];
                        PREADY <= 1;
                    end
                end
            end   // end of penable

            else begin
                PREADY <= 0;
                wait_count <= 0;
            end
        end //  end of PSEL
        
        else begin
            PREADY <= 1;
            wait_count <= 0;
        end
    end  
       
    end
       
endmodule