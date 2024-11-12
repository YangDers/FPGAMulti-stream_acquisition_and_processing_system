module chooser3_1(
   input clk_50m,
   input rgmii_clk,
   input rst_n,

   input button0,
   input button1,
   input button2,
   input [7:0] mac_tx_data_mode0,
   input mac_tx_data_valid_mode0,
   input [7:0] mac_tx_data_mode1,
   input mac_tx_data_valid_mode1,
   input [7:0] mac_tx_data_mode2,
   input mac_tx_data_valid_mode2,

   output reg [7:0] mac_tx_data,
   output reg mac_tx_data_valid,
   //debug
   output trig0/* synthesis PAP_MARK_DEBUG="true" */,
   output trig1/* synthesis PAP_MARK_DEBUG="true" */,
   output trig2/* synthesis PAP_MARK_DEBUG="true" */,
   output [2:0] channel_open_dbg
   );
   wire trig0,trig1,trig2;
   reg [1:0] channel_open;
   assign channel_open_dbg = channel_open;
   buttontrig u0(
      .clk(clk_50m),
      .button(button0),
      .trig(trig0)
   );
   always @(posedge clk_50m) begin
      if(~rst_n) begin
         channel_open <= 2'b00;
      end
      else begin
         if(trig0) begin
            if(channel_open==2'b10)
               channel_open <= 2'b00;
            else 
               channel_open <= channel_open + 1;
         end
      end
   end
   always @(posedge rgmii_clk) begin
      if(~rst_n) begin
         mac_tx_data <= 0;
         mac_tx_data_valid <= 0;
      end
      else begin
         if(channel_open==2'b00) begin
            mac_tx_data <= mac_tx_data_mode0;
            mac_tx_data_valid <= mac_tx_data_valid_mode0;
         end
         else if(channel_open==2'b01) begin
            mac_tx_data <= mac_tx_data_mode1;
            mac_tx_data_valid <= mac_tx_data_valid_mode1;
         end
         else if(channel_open==2'b10) begin
            mac_tx_data <= mac_tx_data_mode1;
            mac_tx_data_valid <= mac_tx_data_valid_mode1;
         end
         else;
      end
   end
endmodule