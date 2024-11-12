module fiber_hdmi_out(
   input             rstn,//低电平复位信号
   //hdmi接口
   input             hdmi_clk,
   input             vs,
   input             hs,
   input             de,
   input             [7:0]r,
   input             [7:0]g,
   input             [7:0]b,
   //fiber接口 配置速率为6G
   input             clk,//50Mfreeclk//lane2 发射//lane3 接收
   input             i_p_refckn_0,
   input             i_p_refckp_0,
   input             i_p_l2rxn,
   input             i_p_l2rxp,
   input             i_p_l3rxn,
   input             i_p_l3rxp,
   output            o_p_l2txn,
   output            o_p_l2txp,
   output            o_p_l3txn,
   output            o_p_l3txp
   );
   //hdmi数据流伪装
   wire [23:0]wr_data;
   assign wr_data={vs,r[7:1],de,g[7:1],1'b0,b[7:1]};
   wire [12:0]rd_water_level;
   wire fullfit ;
   //fifo 24datawidth 12addrwidth
   hsst_buffer buff (
      .wr_clk(hdmi_clk),                // input
      .wr_rst(~rstn&~tx_ready),                // input
      .wr_en(~fullfit),                  // input
      .wr_data(wr_data),              // input [23:0]
      .wr_full(),              // output
      .almost_full(fullfit),      // output
      .rd_clk(hdmi_fake),                // input
      .rd_rst(~rstn&~tx_ready),                // input
      .rd_en(rden),                  // input
      .rd_data(tx_data),              // output [23:0]
      .rd_empty(),            // output
      .rd_water_level(rd_water_level),    // output [10:0]
      .almost_empty()     // output
   );
   wire rden;//记录是否从fifo读了数据
   assign rden=(rd_water_level>=4)?1:0;
   
   //hsst 数据流发射
   wire [23:0] tx_data;
   wire hdmi_fake;
   wire tx_ready;
   hssttop trans(
      .clk(clk),
      .nRst(rstn),
      .tx_data({tx_data[23:8],rden,tx_data[6:0]}),
      .rx_data(),
      .tx_ready(tx_ready),
      .rx_valid(),
      .hsst_tx_clk(hdmi_fake),
      .hsst_rx_clk(),
      .i_p_refckn_0(i_p_refckn_0),
      .i_p_refckp_0(i_p_refckp_0),
      .i_p_l2rxn(i_p_l2rxn),
      .i_p_l2rxp(i_p_l2rxp),
      .i_p_l3rxn(i_p_l3rxn),
      .i_p_l3rxp(i_p_l3rxp),
      .o_p_l2txn(o_p_l2txn),
      .o_p_l2txp(o_p_l2txp),
      .o_p_l3txn(o_p_l3txn),
      .o_p_l3txp(o_p_l3txp)
   );
endmodule