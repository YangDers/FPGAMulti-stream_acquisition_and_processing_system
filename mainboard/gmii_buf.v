`default_nettype wire
`timescale 1ns / 1ps
module gmii_buf(
//gmii_rx
    //ch0
    input                       gmii_rx_clk      ,
    input                       rx_rstn          ,
    input  [7:0]                gmii_rxd         ,
    input                       gmii_rx_dv       ,
    input                       gmii_rx_er       ,
//gmii_tx
    //ch0
    input                       gmii_tx_clk      ,   
    output  [7:0]               gmii_txd         ,
    output                      gmii_tx_en       ,
    output                      gmii_tx_er       
);


wire  [9:0]  wr_data/* synthesis PAP_MARK_DEBUG="true" */;
wire         wr_en/* synthesis PAP_MARK_DEBUG="true" */;
wire         rd_empty/* synthesis PAP_MARK_DEBUG="true" */;
wire  [9:0]  rd_data/* synthesis PAP_MARK_DEBUG="true" */;
wire         rd_en/* synthesis PAP_MARK_DEBUG="true" */;
reg          rd_en_d1;
reg          rd_en_d2;
reg          rx_rstn_d1;
reg          tx_rstn;

always  @(posedge gmii_tx_clk)begin
    rx_rstn_d1 <= rx_rstn ;
    tx_rstn <= rx_rstn_d1 ;
end

always  @(posedge gmii_tx_clk)begin
    rd_en_d1 <= rd_en    ;
    rd_en_d2 <= rd_en_d1 ;
end

assign wr_data = {gmii_rx_dv,gmii_rxd,gmii_rx_er} ;
assign wr_en   =  gmii_rx_dv ;
assign  rd_en = ~rd_empty ;
fifo4gmii inst (
  //wr
  .wr_clk       ( gmii_rx_clk     ),// input
  .wr_rst       (~rx_rstn         ),// input 
  .wr_data      ( wr_data           ),// input [9:0]
  .wr_en        ( wr_en             ),// input
  .wr_full      (                     ),// output
  .almost_full  (                     ),// output
  //rd
  .rd_clk       ( gmii_tx_clk     ),// input
  .rd_rst       (~tx_rstn         ),// input 
  .rd_data      ( rd_data           ),// output [9:0]
  .rd_en        ( rd_en             ),// input
  .rd_empty     ( rd_empty          ),// output
  .almost_empty (                     ) // output
);
assign {gmii_tx_en,gmii_txd,gmii_tx_er} =  rd_en_d1?rd_data:10'h0;
endmodule

