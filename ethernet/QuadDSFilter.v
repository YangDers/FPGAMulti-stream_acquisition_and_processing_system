//四路数据流过滤器
module QuadDSFilter(
//input
    input                       rst_n                ,
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
    output  [7:0]               filtdata            ,
    output                      filtdatav           ,
    output  [7:0]               buf_data            ,
    output                      buf_datav           ,
    output                      request_dbg         ,
    output                      grant_dbg           ,
    output  [7:0]               send_data_dbg       ,
    output                      send_datav_dbg      ,
    output                      fifo_water_level    ,
    output  [4:0]               arbiter_state_dbg   
   );

   wire [7:0]       ch0_filtd           ,ch1_filtd          ,ch2_filtd          ,ch3_filtd;
   wire [7:0]       ch0_buf_data        ,ch1_buf_data       ,ch2_buf_data       ,ch3_buf_data;
   wire             ch0_filtdv          ,ch1_filtdv         ,ch2_filtdv         ,ch3_filtdv;
   wire             ch0_buf_datav       ,ch1_buf_datav      ,ch2_buf_datav      ,ch3_buf_datav;
   wire             ch0_grant           ,ch1_grant          ,ch2_grant          ,ch3_grant;
   wire             ch0_request         ,ch1_request        ,ch2_request        ,ch3_request;
   wire             sender_ready;
   wire [7:0]       send_data           ,send_datav;

   IP_Filter ip_filter_u10ch0 (
    .gmii_clk(ch0_gmii_rx_clk),    // 时钟信号
    .valid(ch0_gmii_rx_dv),          // 数据有效标志
    .data(ch0_gmii_rxd),            // 8位数据输入
    .error(ch0_gmii_rx_er),          // 错误信号
    .rstn(ch0_rx_rstn),            // 复位信号，低电平有效

    .o_valid(ch0_filtdv),      // 输出数据有效标志
    .o_data(ch0_filtd),        // 8位数据输出
    .done(),            // 完成标志
    .match()           // 匹配标志
);
   IP_Filter ip_filter_u10ch1 (
    .gmii_clk(ch1_gmii_rx_clk),    // 时钟信号
    .valid(ch1_gmii_rx_dv),          // 数据有效标志
    .data(ch1_gmii_rxd),            // 8位数据输入
    .error(ch1_gmii_rx_er),          // 错误信号
    .rstn(ch1_rx_rstn),            // 复位信号，低电平有效

    .o_valid(ch1_filtdv),      // 输出数据有效标志
    .o_data(ch1_filtd),        // 8位数据输出
    .done(),            // 完成标志
    .match()           // 匹配标志
);
   IP_Filter ip_filter_u10ch2 (
    .gmii_clk(ch2_gmii_rx_clk),    // 时钟信号
    .valid(ch2_gmii_rx_dv),          // 数据有效标志
    .data(ch2_gmii_rxd),            // 8位数据输入
    .error(ch2_gmii_rx_er),          // 错误信号
    .rstn(ch2_rx_rstn),            // 复位信号，低电平有效

    .o_valid(ch2_filtdv),      // 输出数据有效标志
    .o_data(ch2_filtd),        // 8位数据输出
    .done(),            // 完成标志
    .match()           // 匹配标志
);
   IP_Filter ip_filter_u10ch3 (
    .gmii_clk(ch3_gmii_rx_clk),    // 时钟信号
    .valid(ch3_gmii_rx_dv),          // 数据有效标志
    .data(ch3_gmii_rxd),            // 8位数据输入
    .error(ch3_gmii_rx_er),          // 错误信号
    .rstn(ch3_rx_rstn),            // 复位信号，低电平有效

    .o_valid(ch3_filtdv),      // 输出数据有效标志
    .o_data(ch3_filtd),        // 8位数据输出
    .done(),            // 完成标志
    .match()           // 匹配标志
);

//缓存数据+跨时钟域
packet_buf buf_u10ch0(
    .in_clk(ch0_gmii_rx_clk),
    .out_clk(upper_gmii_clk),
    .rst_n(rst_n),

    .data_in(ch0_filtd),
    .valid_in(ch0_filtdv),

    .sender_ready(ch0_grant),
    .data_out(ch0_buf_data),
    .valid_out(ch0_buf_datav),
    .tx_request(ch0_request),

    .fifo_water_level(fifo_water_level)
);
packet_buf buf_u10ch1(
    .in_clk(ch1_gmii_rx_clk),
    .out_clk(upper_gmii_clk),
    .rst_n(rst_n),

    .data_in(ch1_filtd),
    .valid_in(ch1_filtdv),
    .sender_ready(ch1_grant),

    .data_out(ch1_buf_data),
    .valid_out(ch1_buf_datav),
    .tx_request(ch1_request)
);
packet_buf buf_u10ch2(
    .in_clk(ch2_gmii_rx_clk),
    .out_clk(upper_gmii_clk),
    .rst_n(rst_n),

    .data_in(ch2_filtd),
    .valid_in(ch2_filtdv),

    .sender_ready(ch2_grant),
    .data_out(ch2_buf_data),
    .valid_out(ch2_buf_datav),
    .tx_request(ch2_request)
);
packet_buf buf_u10ch3(
    .in_clk(ch3_gmii_rx_clk),
    .out_clk(upper_gmii_clk),
    .rst_n(rst_n),

    .data_in(ch3_filtd),
    .valid_in(ch3_filtdv),

    .sender_ready(ch3_grant),
    .data_out(ch3_buf_data),
    .valid_out(ch3_buf_datav),
    .tx_request(ch3_request)
);

Q2S_Arbiter u_Q2S_Arbiter (
    // Clock and Reset
    .clk            (upper_gmii_clk),            // Connect to the system clock
    .rst_n          (rst_n),          // Connect to the system reset (active low)

    // Channel 0
    .ch0_data       (ch0_buf_data),       // [7:0] Input data for channel 0
    .ch0_datavalid  (ch0_buf_datav),  // Data valid signal for channel 0
    .ch0_request    (ch0_request),    // Request signal for channel 0
    .ch0_grant      (ch0_grant),      // Grant signal output for channel 0

    // Channel 1
    .ch1_data       (ch1_buf_data),       // [7:0] Input data for channel 1
    .ch1_datavalid  (ch1_buf_datavalid),  // Data valid signal for channel 1
    .ch1_request    (ch1_request),    // Request signal for channel 1
    .ch1_grant      (ch1_grant),      // Grant signal output for channel 1

    // Channel 2
    .ch2_data       (ch2_buf_data),       // [7:0] Input data for channel 2
    .ch2_datavalid  (ch2_buf_datavalid),  // Data valid signal for channel 2
    .ch2_request    (ch2_request),    // Request signal for channel 2
    .ch2_grant      (ch2_grant),      // Grant signal output for channel 2

    // Channel 3
    .ch3_data       (ch3_buf_data),       // [7:0] Input data for channel 3
    .ch3_datavalid  (ch3_buf_datavalid),  // Data valid signal for channel 3
    .ch3_request    (ch3_request),    // Request signal for channel 3
    .ch3_grant      (ch3_grant),      // Grant signal output for channel 3

    // Ethernet Sender Interface
    .sender_ready   (sender_ready),   // Ethernet sender ready signal
    .send_data      (send_data),      // [7:0] Data to be sent to Ethernet sender
    .send_datav     (send_datav),      // Data valid signal for Ethernet sender

    .arbiter_state  (arbiter_state_dbg)
);

EthernetSender sender(
    .clk(upper_gmii_clk),            // 时钟信号
    .rst_n(rst_n),          // 复位信号，低电平有效
    .data_in(send_data),  // 待发送的数据输入
    .valid_in(send_datav),       // 数据输入有效信号

    .tx_en(upper_gmii_tx_en),          // 发送使能信号
    .tx_data(upper_gmii_txd),  // 发送的数据输出
    .tx_error(upper_gmii_tx_er),
    .tx_done(),         // 数据包发送完成标志

    .ready(sender_ready)
);
//debug
    assign filtdata = ch1_filtd;
    assign filtdatav = ch1_filtdv;
    assign buf_data = ch1_buf_data;
    assign buf_datav = ch1_buf_datav;
    assign request_dbg = ch1_request;
    assign grant_dbg = ch1_grant;
    assign send_data_dbg = send_data;
    assign send_datav_dbg = send_datav;
endmodule