module CMD_Trigger(
   input          clk,
   input          rst_n,

   input          ready,

   input          trig0,
   input          trig1,
   input          trig2,
   input          trig3,
   input          trig4,
   input          trig5,
   input          trig6,
   input          trig7,

   output reg [7:0]   cmd_code,
   output reg        cmd_codev
   );
   wire rst0,rst1,rst2,rst3,rst4,rst5,rst6,rst7;
   reg trig0_d,trig1_d,trig2_d,trig3_d,trig4_d,trig5_d,trig6_d,trig7_d;
   reg triggered[7:0];
   reg [7:0] rst;
   assign rst0 = rst[0];
   assign rst1 = rst[1];
   assign rst2 = rst[2];
   assign rst3 = rst[3];
   assign rst4 = rst[4];
   assign rst5 = rst[5];
   assign rst6 = rst[6];
   assign rst7 = rst[7];

   // 对于trig0的检测
always @(posedge clk) begin
    if (rst0|(~rst_n)) begin
        triggered[0] <= 0;
    end
    else begin
        trig0_d <= trig0;
        if (trig0 & (~trig0_d)) begin
            triggered[0] <= 1;
        end
    end
end

// 对于trig1的检测
always @(posedge clk) begin
    if (rst1|(~rst_n)) begin
        triggered[1] <= 0;
    end
    else begin
        trig1_d <= trig1;
        if (trig1 & (~trig1_d)) begin
            triggered[1] <= 1;
        end
    end
end

// 对于trig2的检测
always @(posedge clk) begin
    if (rst2|(~rst_n)) begin
        triggered[2] <= 0;
    end
    else begin
        trig2_d <= trig2;
        if (trig2 & (~trig2_d)) begin
            triggered[2] <= 1;
        end
    end
end

// 对于trig3的检测
always @(posedge clk) begin
    if (rst3|(~rst_n)) begin
        triggered[3] <= 0;
    end
    else begin
        trig3_d <= trig3;
        if (trig3 & (~trig3_d)) begin
            triggered[3] <= 1;
        end
    end
end

// 对于trig4的检测
always @(posedge clk) begin
    if (rst4|(~rst_n)) begin
        triggered[4] <= 0;
    end
    else begin
        trig4_d <= trig4;
        if (trig4 & (~trig4_d)) begin
            triggered[4] <= 1;
        end
    end
end

// 对于trig5的检测
always @(posedge clk) begin
    if (rst5|(~rst_n)) begin
        triggered[5] <= 0;
    end
    else begin
        trig5_d <= trig5;
        if (trig5 & (~trig5_d)) begin
            triggered[5] <= 1;
        end
    end
end

// 对于trig6的检测
always @(posedge clk) begin
    if (rst6|(~rst_n)) begin
        triggered[6] <= 0;
    end
    else begin
        trig6_d <= trig6;
        if (trig6 & (~trig6_d)) begin
            triggered[6] <= 1;
        end
    end
end

// 对于trig7的检测
always @(posedge clk) begin
    if (rst7|(~rst_n)) begin
        triggered[7] <= 0;
    end
    else begin
        trig7_d <= trig7;
        if (trig7 & (~trig7_d)) begin
            triggered[7] <= 1;
        end
    end
end


   parameter cmd0 = 16'hCA11;
   parameter cmd1 = 16'hCA22;
   parameter cmd2 = 16'hCA33;
   parameter cmd3 = 16'hCA44;
   parameter cmd4 = 16'hCA55;
   parameter cmd5 = 16'hCA66;
   parameter cmd6 = 16'hCA77;
   parameter cmd7 = 16'hCA88;
   wire [15:0] cmd [7:0];
   assign cmd[0] = cmd0;
   assign cmd[1] = cmd1;
   assign cmd[2] = cmd2;
   assign cmd[3] = cmd3;
   assign cmd[4] = cmd4;
   assign cmd[5] = cmd5;
   assign cmd[6] = cmd6;
   assign cmd[7] = cmd7;

   localparam IDLE = 0;
   localparam JUDGE = 1;
   localparam SEND0 = 2;
   localparam SEND1 = 3;

   reg [3:0] cnt;
   reg [1:0] state;
   always@(posedge clk) begin
      if(~rst_n) begin
         cnt<=0;
         rst[7:0] <= 0;

         cmd_code <= 0;
         cmd_codev <= 0;
         state <= IDLE;
      end
      else begin
         case(state)
            IDLE: begin
               cmd_codev <= 0;
               cmd_code <= 0;
               if(ready) begin
                  state <= JUDGE;
               end
               else;
            end
            JUDGE: begin
               if(triggered[cnt]) begin
                  state <= SEND0;
                  rst[cnt] <= 1;
               end
               else begin
                  state <= IDLE;
                  cnt <= (cnt==7)?0:(cnt+1);
               end
            end
            SEND0: begin
               cmd_codev <= 1;
               cmd_code <= cmd[cnt][15:8];
               state <= SEND1;
               rst[cnt] <= 0;
            end
            SEND1: begin
               cmd_codev <= 1;
               cmd_code <= cmd[cnt][7:0];
               state <= IDLE;
               cnt <= (cnt==7)?0:(cnt+1);
            end
         endcase
      end
   end

endmodule