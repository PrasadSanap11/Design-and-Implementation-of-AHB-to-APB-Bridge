module async_fifo #(
     parameter DATASIZE = 41,
     parameter ADDRSIZE = 4)
     
     (input [DATASIZE-1:0] wdata,
      input winc, wclk, wrst_n,
      input rinc, rclk, rrst_n,
      output reg [DATASIZE-1:0] rdata,
      output reg wfull,
      output reg rempty
      );
 
     wire [ADDRSIZE-1:0] waddr;
     wire [ADDRSIZE-1:0] raddr;
     reg  [ADDRSIZE:0]   wptr;
     reg  [ADDRSIZE:0]   rptr;
     reg  [ADDRSIZE:0]   wq2_rptr;
     reg  [ADDRSIZE:0]   rq2_wptr;
     reg  [ADDRSIZE:0]   wq1_rptr;
     wire                wclken;
     wire                rclken;
     reg  [ADDRSIZE:0]   rq1_wptr;
     reg  [ADDRSIZE:0]   rbin;
     wire [ADDRSIZE:0]   rgray_next;
     wire [ADDRSIZE:0]   rbin_next;
     reg  [ADDRSIZE:0]   wbin;
     wire [ADDRSIZE:0]   wgray_next;
     wire [ADDRSIZE:0]   wbin_next;
     
     localparam DEPTH = 1<<ADDRSIZE;
     wire wfull_val;
     wire rempty_val;
     reg [DATASIZE-1:0] mem [0:DEPTH-1];
   
     always @(posedge rclk or negedge rrst_n) begin
     if (!rrst_n)
        {rbin, rptr} <= 0;
     else begin
        rbin <= rbin_next;
        rptr <= rgray_next;
     end
    end
   
     assign raddr = rbin[ADDRSIZE-1:0];
     assign rbin_next = rbin + (rinc & ~rempty);
     assign rgray_next = (rbin_next>>1) ^ rbin_next;
     
     assign rempty_val = (rgray_next == rq2_wptr);
       
     always @(posedge rclk or negedge rrst_n) begin
     if (!rrst_n)
        rempty <= 1'b1;
     else
        rempty <= rempty_val;
    end
   
     always @(posedge wclk or negedge wrst_n)begin
        if (!wrst_n)
            {wbin, wptr} <= 0;
     else begin
        wbin <= wbin_next;
        wptr <= wgray_next;
     end
    end
   
     assign waddr = wbin[ADDRSIZE-1:0];
     assign wbin_next = wbin + (winc & ~wfull);
     assign wgray_next = (wbin_next>>1) ^ wbin_next;
     
    assign wfull_val = (wgray_next=={~wq2_rptr[ADDRSIZE:ADDRSIZE-1],wq2_rptr[ADDRSIZE-2:0]});
     
     always @(posedge wclk or negedge wrst_n) begin
     if (!wrst_n)
        wfull <= 1'b0;
     else
        wfull <= wfull_val;
    end
   
    always @(posedge wclk or negedge wrst_n)
 if (!wrst_n)
    {wq2_rptr,wq1_rptr} <= 0;
 else
    {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
   
     always @(posedge rclk or negedge rrst_n)
     if (!rrst_n)
        {rq2_wptr,rq1_wptr} <= 0;
     else
        {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};
       
       
     assign wclken = winc & ~wfull;  // Write clock enable when write is valid and FIFO is not full
    assign rclken = rinc & ~rempty;
       
     always @(posedge rclk)
     if (rclken && !rempty)
        rdata <= mem[raddr];
   
     always @(posedge wclk)
     if (wclken && !wfull)
        mem[waddr] <= wdata;
     
endmodule