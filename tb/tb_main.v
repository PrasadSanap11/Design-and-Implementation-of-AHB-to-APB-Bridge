`timescale 1ns / 1ps

module tb_main;

    reg                  HCLK, PCLK;
    reg                  RESETn;
    reg                  HSEL;
    reg            [7:0] HADDR;
    reg           [31:0] HWDATA;
    reg                  HWRITE;
    reg            [1:0] HTRANS;

    wire          [31:0] HRDATA;
    wire                 HREADYOUT;

    integer i;
    integer k;
    reg [7:0]addr;
    reg [31:0]data;
    
    reg [7:0] mem_addr [9:0];
    reg [31:0] mem_data [9:0];
    reg [31:0] mem_hrdata [9:0];
    
    main dut (
        .HCLK(HCLK), .PCLK(PCLK), .RESETn(RESETn), .HSEL(HSEL), 
        .HADDR(HADDR), .HWDATA(HWDATA), .HWRITE(HWRITE), 
        .HTRANS(HTRANS), .HRDATA(HRDATA), .HREADYOUT(HREADYOUT)
    );

    initial begin
        HCLK = 0;
        PCLK = 0;
    end

    always #5 HCLK = ~HCLK;
    always #10 PCLK = ~PCLK;
    
    task write_trans;
        input [7:0]haddr;
        input [31:0]hwdata;
        begin
            @(posedge HCLK);
            $display("\n[%0t] Starting AHB Write to 0x%h", $time, haddr);
            while (!HREADYOUT) begin  // wait for the slave to get ready
                @(posedge HCLK);
            end
            HTRANS = 2'b10; 
            HWRITE = 1'b1;
            HADDR  = haddr;
            
            @(posedge HCLK);  
            HWDATA = hwdata;
            $display("Data = %0h", hwdata);
            HTRANS = 2'b00;
            
            while (!HREADYOUT) begin  // wait for the slave to get ready
                @(posedge HCLK);
            end
            @(posedge HCLK);
        end
        endtask
        
        task read_trans;
            input [7:0]haddr;
        begin
            @(posedge HCLK);
            $display("\n[%0t] Starting AHB Read from 0x%h.", $time, haddr);
            while (!HREADYOUT) begin
                @(posedge HCLK);
            end
            HTRANS = 2'b10; 
            HWRITE = 1'b0; 
            HADDR  = haddr;
            
            @(posedge HCLK);
            HTRANS = 2'b00;
            @(posedge HCLK);
            #10; // Race condition create for storing the hrdata in the memory of testbench
            while (!HREADYOUT) begin
                @(posedge HCLK);
            end
            mem_hrdata[k] = HRDATA;
        end
    endtask
    
    initial begin
        $display("-----------------------------------------");
        $display("%0t Testbench Started.", $time);
        $display("-----------------------------------------");

        
        HSEL = 1'b1; HADDR = 0; HWDATA = 0; HWRITE = 1'b0;
        HTRANS = 2'b00; RESETn = 1'b0;
       // k=0;
        #40;
        RESETn = 1'b1;
        
        
        for (i=0; i<10; i=i+1) begin
            
            addr = $random % 256;
            mem_addr[i] = addr;
            data = $random;
            mem_data[i] = data;
            write_trans(addr,data);
            
        end
        #600;   // just for representation of waveform
        for (k=0; k<10; k=k+1) begin
            read_trans(mem_addr[k]);
//            mem_hrdata[i] = HRDATA;
        end
        
        for (i=0; i<10; i=i+1) begin
            if(mem_hrdata [i] == mem_data[i])
                $display("The READ DATA is CORRECT!!");
        end
        
        
        #500;
        $finish;
    end

endmodule