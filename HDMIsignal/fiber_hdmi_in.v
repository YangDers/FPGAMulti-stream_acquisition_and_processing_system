module fiber_hdmi_in(
   input             rstn,//低电平复位信号
   //hdmi out
   output hdmi_fake,
   output vs_fake,
   output de_fake,
   output rout,
   output gout,
   output bout,
   output clken,
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
   //hdmi接收
   hssttop trans(
      .clk(clk),
      .nRst(rstn),
      .tx_data(),
      .rx_data(rx_data),
      .tx_ready(),
      .rx_valid(rx_valid),
      .hsst_tx_clk(),
      .hsst_rx_clk(hdmi_fake),
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
   wire hdmi_fake;
   wire [23:0] rx_data;
   wire [7:0] rout;
   wire [7:0] gout;
   wire [7:0] bout;
   wire vs_fake;
   wire de_fake;
   wire clken;
   assign vs_fake=rx_data[23];
   assign de_fake=rx_data[15];
   assign clken=rx_data[7];
   assign rout={rx_data[22:16],1'b0};
   assign gout={rx_data[14:8],1'b0};
   assign bout={rx_data[6:0],1'b0};
endmodule