module Eth_Q2S(
//input
    input                       rst_n                ,

    input                       ready                ,
   //ch0
    input                       ch0_gmii_rx_clk      ,
    input                       ch0_rx_rstn          ,
    input  [7:0]                ch0_gmii_rxd         ,
    input                       ch0_gmii_rx_dv       ,
    input                       ch0_gmii_rx_er       ,
    //ch1
    input                       ch1_gmii_rx_clk      ,
    input                       ch1_rx_rstn          ,
    input  [7:0]                ch1_gmii_rxd         ,
    input                       ch1_gmii_rx_dv       ,
    input                       ch1_gmii_rx_er       ,
    //ch2
    input                       ch2_gmii_rx_clk      ,
    input                       ch2_rx_rstn          ,
    input  [7:0]                ch2_gmii_rxd         ,
    input                       ch2_gmii_rx_dv       ,
    input                       ch2_gmii_rx_er       ,
    //ch3
    input                       ch3_gmii_rx_clk      ,
    input                       ch3_rx_rstn          ,
    input  [7:0]                ch3_gmii_rxd         ,
    input                       ch3_gmii_rx_dv       ,
    input                       ch3_gmii_rx_er       ,
//output
    input                       upper_gmii_clk       ,
    output [7:0]                upper_gmii_txd       ,
    output                      upper_gmii_tx_en     ,
    output                      upper_gmii_tx_er     ,

//debug
    output  [7:0]               data_dbg            ,
    output                      valid_dbg           ,
    output                      error_dbg           ,
    output                      request_dbg         ,
    output                      grant_dbg           ,
    output  [4:0]               arbiter_state_dbg   ,
    output [1:0]                buf_rx_state_dbg    ,
    output [1:0]                buf_tx_state_dbg    ,
    output [10:0]               buf_wr_data_dbg     ,
    output [10:0]               buf_rd_data_dbg     ,
    output [7:0]                l_data_dbg         
   );

   wire [7:0]     ch0_data       ,ch1_data         ,ch2_data         ,ch3_data;
   wire           ch0_valid      ,ch1_valid        ,ch2_valid        ,ch3_valid;
   wire           ch0_error      ,ch1_error        ,ch2_error        ,ch3_error;
   wire           ch0_last       ,ch1_last         ,ch2_last         ,ch3_last;
   //debug
   assign data_dbg = ch0_data;
   assign valid_dbg = ch0_valid;
   assign error_dbg = ch0_error;
   assign request_dbg = ch0_request;
   assign grant_dbg = ch0_grant;

   Buf_NetStream buf_ch0(
      .rst_n(rst_n),

      .gmii_clk_in(ch0_gmii_rx_clk),
      .gmii_data_in(ch0_gmii_rxd),
      .gmii_valid_in(ch0_gmii_rx_dv),
      .gmii_error_in(ch0_gmii_rx_er),

      .gmii_clk_out(upper_gmii_clk),
      .gmii_data_out(ch0_data),
      .gmii_valid_out(ch0_valid),
      .gmii_error_out(ch0_error),
      .last(ch0_last),

      .grant(ch0_grant),
      .request(ch0_request),

      .buf_tx_state_dbg(buf_tx_state_dbg),
      .buf_rx_state_dbg(buf_rx_state_dbg),
      .buf_wr_data(buf_wr_data_dbg),
      .buf_rd_data(buf_rd_data_dbg),
      .l_data_dbg(l_data_dbg)
   );
   Buf_NetStream buf_ch1(
      .rst_n(rst_n),

      .gmii_clk_in(ch1_gmii_rx_clk),
      .gmii_data_in(ch1_gmii_rxd),
      .gmii_valid_in(ch1_gmii_rx_dv),
      .gmii_error_in(ch1_gmii_rx_er),

      .gmii_clk_out(upper_gmii_clk),
      .gmii_data_out(ch1_data),
      .gmii_valid_out(ch1_valid),
      .gmii_error_out(ch1_error),
      .last(ch1_last),

      .grant(ch1_grant),
      .request(ch1_request)
   );
   Buf_NetStream buf_ch2(
      .rst_n(rst_n),

      .gmii_clk_in(ch2_gmii_rx_clk),
      .gmii_data_in(ch2_gmii_rxd),
      .gmii_valid_in(ch2_gmii_rx_dv),
      .gmii_error_in(ch2_gmii_rx_er),

      .gmii_clk_out(upper_gmii_clk),
      .gmii_data_out(ch2_data),
      .gmii_valid_out(ch2_valid),
      .gmii_error_out(ch2_error),
      .last(ch2_last),

      .grant(ch2_grant),
      .request(ch2_request)
   );
   Buf_NetStream buf_ch3(
      .rst_n(rst_n),

      .gmii_clk_in(ch3_gmii_rx_clk),
      .gmii_data_in(ch3_gmii_rxd),
      .gmii_valid_in(ch3_gmii_rx_dv),
      .gmii_error_in(ch3_gmii_rx_er),

      .gmii_clk_out(upper_gmii_clk),
      .gmii_data_out(ch3_data),
      .gmii_valid_out(ch3_valid),
      .gmii_error_out(ch3_error),
      .last(ch3_last),

      .grant(ch3_grant),
      .request(ch3_request)
   );

   Q2S_Arbiter arbiter(
      .clk(upper_gmii_clk),
      .rst_n(rst_n),

      .ch0_data(ch0_data),
      .ch0_datavalid(ch0_valid),
      .ch0_error(ch0_error),
      .ch0_request(ch0_request),
      .ch0_last(ch0_last),
      .ch0_grant(ch0_grant),

      .ch1_data(ch1_data),
      .ch1_datavalid(ch1_valid),
      .ch1_error(ch1_error),
      .ch1_request(ch1_request),
      .ch1_last(ch1_last),
      .ch1_grant(ch1_grant),

      .ch2_data(ch2_data),
      .ch2_datavalid(ch2_valid),
      .ch2_error(ch2_error),
      .ch2_request(ch2_request),
      .ch2_last(ch2_last),
      .ch2_grant(ch2_grant),

      .ch3_data(ch3_data),
      .ch3_datavalid(ch3_valid),
      .ch3_error(ch3_error),
      .ch3_request(ch3_request),
      .ch3_last(ch3_last),
      .ch3_grant(ch3_grant),

      .sender_ready(ready),
      .send_data(upper_gmii_txd),
      .send_datav(upper_gmii_tx_en),
      .send_error(upper_gmii_tx_er),

      .arbiter_state(arbiter_state_dbg)
   );
endmodule