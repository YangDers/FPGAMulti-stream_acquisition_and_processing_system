module Q2S_Arbiter(
//input
//clk & rst
   input             clk,
   input             rst_n,
//data&request&grant
   //ch0
   input [7:0]       ch0_data,
   input             ch0_datavalid,
   input             ch0_error,
   input             ch0_request,
   input             ch0_last,
   output reg        ch0_grant,
   //ch1
   input [7:0]       ch1_data,
   input             ch1_datavalid,
   input             ch1_error,
   input             ch1_request,
   input             ch1_last,
   output reg        ch1_grant,
   //ch2
   input [7:0]       ch2_data,
   input             ch2_datavalid,
   input             ch2_error,
   input             ch2_request,
   input             ch2_last,
   output reg        ch2_grant,
   //ch3
   input [7:0]       ch3_data,
   input             ch3_datavalid,
   input             ch3_error,
   input             ch3_request,
   input             ch3_last,
   output reg        ch3_grant,

//EthernetSender
   input             sender_ready,
   output reg [7:0]  send_data,
   output reg        send_datav,
   output reg        send_error,


//debug
   output [4:0]      arbiter_state
   );
   localparam     JUDGE_CH0 = 0;
   localparam     PRE_CH0 = 1;
   localparam     SEND_CH0 = 2;
   localparam     JUDGE_CH1 = 3;
   localparam     PRE_CH1 = 4;
   localparam     SEND_CH1 = 5;
   localparam     JUDGE_CH2 = 6;
   localparam     PRE_CH2 = 7;
   localparam     SEND_CH2 = 8;
   localparam     JUDGE_CH3 = 9;
   localparam     PRE_CH3 = 10;
   localparam     SEND_CH3 = 11;

   reg   [4:0]       state;
   reg   [3:0]       wait_cnt;
   
   //缓存数据
   // reg   [7:0]       ch0_data_d        ,ch1_data_d       ,ch2_data_d       ,ch3_data_d;
   // reg               ch0_datav_d       ,ch1_datav_d      ,ch2_datav_d      ,ch3_datav_d;
   // always@(posedge clk) begin
   //    if(~rst_n) begin
   //       ch0_data_d <= 0;
   //       ch1_data_d <= 0;
   //       ch2_data_d <= 0;
   //       ch3_data_d <= 0;
   //       ch0_datav_d <= 0;
   //       ch1_datav_d <= 0;
   //       ch2_datav_d <= 0;
   //       ch3_datav_d <= 0;
   //    end
   //    else begin
   //       ch0_data_d <= ch0_data;
   //       ch1_data_d <= ch1_data;
   //       ch2_data_d <= ch2_data;
   //       ch3_data_d <= ch3_data;
   //       ch0_datav_d <= ch0_datavalid;
   //       ch1_datav_d <= ch1_datavalid;
   //       ch2_datav_d <= ch2_datavalid;
   //       ch3_datav_d <= ch3_datavalid;
   //    end
   // end
   reg ch0_last_d,ch1_last_d,ch2_last_d,ch3_last_d;
   always@(posedge clk) begin
      if(~rst_n) begin
         ch0_last_d<=0;
         ch1_last_d<=0;
         ch2_last_d<=0;
         ch3_last_d<=0;
      end
      else begin
         ch0_last_d<=ch0_last;
         ch1_last_d<=ch1_last;
         ch2_last_d<=ch2_last;
         ch3_last_d<=ch3_last;
      end
   end
   always@(posedge clk) begin
      if(~rst_n) begin
         state <= 0;
         send_data <= 0;
         send_datav <= 0;
         ch0_grant <= 0;
         ch1_grant <= 0;
         ch2_grant <= 0;
         ch3_grant <= 0;
      end
      else begin
         case(state) 
         JUDGE_CH0: begin
            if(sender_ready) begin
               if(ch0_request) begin
                  ch0_grant <= 1;
                  send_data <= 0;
                  send_datav <= 0;
                  send_error <= 0;
                  state <= PRE_CH0;
               end
               else begin
                  ch0_grant <= 0;
                  send_data <= 0;
                  send_datav <= 0;
                  send_error <= 0;
                  state<= JUDGE_CH1;
               end
            end
            else begin//do nothing
               ch0_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state<= JUDGE_CH0;
            end
         end
         PRE_CH0: begin
            if(ch0_datavalid) begin
               ch0_grant <= 0;
               send_data <= ch0_data;
               send_datav <= ch0_datavalid;
               send_error <= ch0_error;
               state <= SEND_CH0;
            end
            else begin  //do nothing
               ch0_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state<= PRE_CH0;
            end
         end
         SEND_CH0: begin
            if(ch0_last_d) begin
               ch0_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state <= JUDGE_CH1;
            end
            else begin //do nothing
               ch0_grant <= 0;
               send_data <= ch0_data;
               send_datav <= ch0_datavalid;
               send_error <= ch0_error;
               state <= SEND_CH0;
            end
         end
         JUDGE_CH1: begin
            if(sender_ready) begin
               if(ch1_request) begin
                  ch1_grant <= 1;
                  send_data <= 0;
                  send_datav <= 0;
                  send_error <= 0;
                  state <= PRE_CH1;
               end
               else begin
                  ch1_grant <= 0;
                  send_data <= 0;
                  send_datav <= 0;
                  send_error <= 0;
                  state<= JUDGE_CH2;
               end
            end
            else begin//do nothing
               ch1_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state<= JUDGE_CH1;
            end
         end
         PRE_CH1: begin
            if(ch1_datavalid) begin
               ch1_grant <= 0;
               send_data <= ch1_data;
               send_datav <= ch1_datavalid;
               send_error <= ch1_error;
               state <= SEND_CH1;
            end
            else begin  //do nothing
               ch1_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state<= PRE_CH1;
            end
         end
         SEND_CH1: begin
            if(ch1_last_d) begin
               ch1_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state <= JUDGE_CH2;
            end
            else begin //do nothing
               ch1_grant <= 0;
               send_data <= ch1_data;
               send_datav <= ch1_datavalid;
               send_error <= ch1_error;
               state <= SEND_CH1;
            end
         end
         JUDGE_CH2: begin
            if(sender_ready) begin
               if(ch2_request) begin
                  ch2_grant <= 1;
                  send_data <= 0;
                  send_datav <= 0;
                  send_error <= 0;
                  state <= PRE_CH2;
               end
               else begin
                  ch2_grant <= 0;
                  send_data <= 0;
                  send_datav <= 0;
                  send_error <= 0;
                  state<= JUDGE_CH3;
               end
            end
            else begin//do nothing
               ch2_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state<= JUDGE_CH2;
            end
         end
         PRE_CH2: begin
            if(ch2_datavalid) begin
               ch2_grant <= 0;
               send_data <= ch2_data;
               send_datav <= ch2_datavalid;
               send_error <= ch2_error;
               state <= SEND_CH2;
            end
            else begin  //do nothing
               ch2_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state <= PRE_CH2;
            end
         end
         SEND_CH2: begin
            if(ch2_last_d) begin
               ch2_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state <= JUDGE_CH3;
            end
            else begin //do nothing
               ch2_grant <= 0;
               send_data <= ch2_data;
               send_datav <= ch2_datavalid;
               send_error <= 0;
               state <= SEND_CH2;
            end
         end
         JUDGE_CH3: begin
            if(sender_ready) begin
               if(ch3_request) begin
                  ch3_grant <= 1;
                  send_data <= 0;
                  send_datav <= 0;
                  send_error <= 0;
                  state <= PRE_CH3;
               end
               else begin
                  ch3_grant <= 0;
                  send_data <= 0;
                  send_datav <= 0;
                  send_error <= 0;
                  state<= JUDGE_CH0;
               end
            end
            else begin//do nothing
               ch3_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state<= JUDGE_CH3;
            end
         end
         PRE_CH3: begin
            if(ch3_datavalid) begin
               ch3_grant <= 0;
               send_data <= ch3_data;
               send_datav <= ch3_datavalid;
               send_error <= ch3_error;
               state <= SEND_CH3;
            end
            else begin  //do nothing
               ch3_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state<= PRE_CH3;
            end
         end
         SEND_CH3: begin
            if(ch3_last_d) begin
               ch3_grant <= 0;
               send_data <= 0;
               send_datav <= 0;
               send_error <= 0;
               state <= JUDGE_CH0;
            end
            else begin //do nothing
               ch3_grant <= 0;
               send_data <= ch3_data;
               send_datav <= ch3_datavalid;
               send_error <= ch3_error;
               state <= SEND_CH3;
            end
         end
         endcase
      end
   end
   assign arbiter_state = state;
endmodule