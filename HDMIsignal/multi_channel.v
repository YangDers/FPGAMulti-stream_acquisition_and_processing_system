module multi_channel#(
  parameter MEM_ROW_ADDR_WIDTH   = 15                           ,
  parameter MEM_COL_ADDR_WIDTH   = 10                           ,
  parameter MEM_BADDR_WIDTH      = 3                            ,
  parameter MEM_DQ_WIDTH         = 32                           ,
  parameter MEM_DM_WIDTH         = MEM_DQ_WIDTH/8               ,
  parameter MEM_DQS_WIDTH        = MEM_DQ_WIDTH/8               ,
  parameter CTRL_ADDR_WIDTH      = MEM_ROW_ADDR_WIDTH + MEM_BADDR_WIDTH + MEM_COL_ADDR_WIDTH
)(
   //global
   input                                  sys_clk         ,
   //fiber
   input             i_p_refckn_0,
   input             i_p_refckp_0,
   input             i_p_l2rxn,
   input             i_p_l2rxp,
   input             i_p_l3rxn,
   input             i_p_l3rxp,
   output            o_p_l2txn,
   output            o_p_l2txp,
   output            o_p_l3txn,
   output            o_p_l3txp,
   //uart
   input                                  uart_rx,
   //input signal
   (*CLOCK_BUFFER_TYPE="BUFG"*)input             pixclk_1,                            
   input             vs_1, 
   input             hs_1, 
   input             de_1,
   input     [7:0]   r_1, 
   input     [7:0]   g_1, 
   input     [7:0]   b_1,  

   (*CLOCK_BUFFER_TYPE="BUFG"*)input             pixclk_2,
   input             vs_2, 
   input             hs_2, 
   input             de_2,
   input     [7:0]   r_2, 
   input     [7:0]   g_2, 
   input     [7:0]   b_2,  

   (*CLOCK_BUFFER_TYPE="BUFG"*)input             pixclk_3,
   input             vs_3, 
   input             hs_3, 
   input             de_3,
   input     [7:0]   r_3, 
   input     [7:0]   g_3, 
   input     [7:0]   b_3, 
   output            rstn_out1,
   output            rstn_out2,
   output            rstn_out3,
   //output signal
   output                                 iic_tx_scl      ,//i2c
   inout                                  iic_tx_sda      ,//i2c
   output                                 iic_rx_scl      ,//i2c
   inout                                  iic_rx_sda      ,//i2c
   output                                 init_over       ,//输出芯片配置ok
   output                                 hdmiout/*synthesis PAP_MARK_DEBUG="1"*/,//pixclk   
   output                                 vs_out/*synthesis PAP_MARK_DEBUG="1"*/, 
   output                                 hs_out/*synthesis PAP_MARK_DEBUG="1"*/, 
   output                                 de_out/*synthesis PAP_MARK_DEBUG="1"*/,
   output                          [7:0]  r_out/*synthesis PAP_MARK_DEBUG="1"*/ , 
   output                          [7:0]  g_out/*synthesis PAP_MARK_DEBUG="1"*/ , 
   output                          [7:0]  b_out/*synthesis PAP_MARK_DEBUG="1"*/ ,
   //ddr3  signal
   output                                 pll_lock        , //ddr pll准备信号
   output                                 ddr_init_done   ,//ddr 初始化
   output reg                             heart_beat_led  ,//正常工作心跳信号

   output                                 mem_rst_n       ,//物理连接层                       
   output                                 mem_ck          ,//物理连接层
   output                                 mem_ck_n        ,//物理连接层
   output                                 mem_cke         ,//物理连接层
   output                                 mem_cs_n        ,//物理连接层
   output                                 mem_ras_n       ,//物理连接层
   output                                 mem_cas_n       ,//物理连接层
   output                                 mem_we_n        ,//物理连接层  
   output                                 mem_odt         ,//物理连接层
   output     [MEM_ROW_ADDR_WIDTH-1:0]    mem_a           ,//物理连接层   
   output     [MEM_BADDR_WIDTH-1:0]       mem_ba          ,//物理连接层   
   inout      [MEM_DQS_WIDTH-1:0]         mem_dqs         ,//物理连接层
   inout      [MEM_DQS_WIDTH-1:0]         mem_dqs_n       ,//物理连接层
   inout      [MEM_DQ_WIDTH-1:0]          mem_dq          ,//物理连接层
   output     [MEM_DM_WIDTH-1:0]          mem_dm           //物理连接层
   );
/*************************参数****************************/
   parameter TH_1S         = 27'd50_000_000;
/**************************串口****************************/
   wire [7:0] uart_data;
   wire rx_done;
   uart_rx#(
      .CLK_FRE(50),         //时钟频率，默认时钟频率为50MHz
      .DATA_WIDTH(8),       //有效数据位，缺省为8位
      .PARITY_ON(0),        //校验位，1为有校验位，0为无校验位，缺省为0
      .PARITY_TYPE(1),      //校验类型，1为奇校验，0为偶校验，缺省为偶校验
      .BAUD_RATE(9600)      //波特率，缺省为9600
    ) user_uart
    (
      .i_clk_sys(clk50M),      //系统时钟
      .i_rst_n(rst),        //全局异步复位,低电平有效
      .i_uart_rx(uart_rx),      //UART输入
      .o_uart_data(uart_data),    //UART接收数据
      .o_ld_parity(),    //校验位检验LED，高电平位为校验正确
      .o_rx_done(rx_done)       //UART数据接收完成标志
    );
/*************************时钟****************************/
   wire locked;
   wire rst;
   wire core_clk/*synthesis PAP_MARK_DEBUG="1"*/;//axi工作时钟
   wire cfg_clk;
   wire clk74M;
   wire clk_148M;
   wire clk50M;
   wire BUS_clk;
   total_pll pll_total (
      .clkin1(sys_clk),        // input
      .pll_lock(locked),      // output
      .clkout1(cfg_clk),      // output10M
      .clkout0(clk_148M),       // output148.5M
      .clkout2(clk74M),
      .clkout3(clk50M)
   );
   (*CLOCK_BUFFER_TYPE="BUFG"*)wire hdmiout;
   assign hdmiout=clk_148M;
   assign rst = locked;
/***********************DEBUG信号*****************************/
   wire [3:0]burst_once_cnt/*synthesis PAP_MARK_DEBUG="1"*/;
/*************************DDR3****************************/
   //ddr3时钟配置，复位逻辑
   //不用管
   //心跳信号，表示工作正常
   reg  [26:0]cnt;
   always@(posedge core_clk) begin
      if (!ddr_init_done)
         cnt <= 27'd0;
      else if ( cnt >= TH_1S )
         cnt <= 27'd0;
      else
         cnt <= cnt + 27'd1;
   end

   always @(posedge core_clk)
      begin
      if (!ddr_init_done)
         heart_beat_led <= 1'd1;
      else if ( cnt >= TH_1S )
         heart_beat_led <= ~heart_beat_led;
   end

//ddr3用户端口
   //写——地址通道
   wire [CTRL_ADDR_WIDTH-1:0]       my_axi_awaddr             /*synthesis PAP_MARK_DEBUG="1"*/;
   wire [3:0]                       my_axi_awlen              /*synthesis PAP_MARK_DEBUG="1"*/;
   wire                             my_axi_awready            /*synthesis PAP_MARK_DEBUG="1"*/;
   wire                             my_axi_awvalid            /*synthesis PAP_MARK_DEBUG="1"*/;
   //写——数据通道
   wire [MEM_DQ_WIDTH*8-1:0]        my_axi_wdata              /*synthesis PAP_MARK_DEBUG="1"*/;
   wire                             my_axi_wready             /*synthesis PAP_MARK_DEBUG="1"*/;
   wire                             my_axi_wusero_last        /*synthesis PAP_MARK_DEBUG="1"*/;
   //读——地址通道
   wire [CTRL_ADDR_WIDTH-1:0]       my_axi_araddr             /*synthesis PAP_MARK_DEBUG="1"*/;
   wire [3:0]                       my_axi_arlen              /*synthesis PAP_MARK_DEBUG="1"*/;
   wire                             my_axi_arready            /*synthesis PAP_MARK_DEBUG="1"*/;
   wire                             my_axi_arvalid            /*synthesis PAP_MARK_DEBUG="1"*/;
   //读——数据通道
   wire [MEM_DQ_WIDTH*8-1:0]        my_axi_rdata              /*synthesis PAP_MARK_DEBUG="1"*/;
   wire                             my_axi_rlast              /*synthesis PAP_MARK_DEBUG="1"*/;
   wire                             my_axi_rvalid             /*synthesis PAP_MARK_DEBUG="1"*/;

   ddr3_axi ddr3_test(
      //sys_interface
      .ref_clk                (sys_clk      ),
      .resetn                 (rst          ),// input
      .ddr_init_done          (ddr_init_done),// output
      .ddrphy_clkin           (core_clk     ),// output
      .pll_lock               (pll_lock     ),// output
      //axi_interface
      //用户端口
      //先发送地址，再收发数据
      //地址定义
      //ap信号究竟有什么影响，ap为1貌似快一些
      //突发传输的地址增加是怎么计算的，不能进行跨行burst，这不是问题了已经
      //ROW 15+BANK 3+COLUNM 10
      //写-地址通道
      .axi_awaddr             (my_axi_awaddr    ),// input [27:0]
      .axi_awuser_ap          (1'b0             ),// input
      .axi_awuser_id          (4'b0000          ),// input [3:0]
      .axi_awlen              (my_axi_awlen     ),// input [3:0]
      .axi_awready            (my_axi_awready   ),// output
      .axi_awvalid            (my_axi_awvalid   ),// input
      //写-数据通道
      .axi_wdata              (my_axi_wdata     ),// input [255:0]
      .axi_wstrb              (32'hffffffff     ),// input [31:0]
      .axi_wready             (my_axi_wready    ),// output
      .axi_wusero_id          (                 ),// output [3:0]不管
      .axi_wusero_last        (my_axi_wusero_last),// output
      //读-地址通道
      .axi_araddr             (my_axi_araddr    ),// input [27:0]
      .axi_aruser_ap          (1'b0             ),// input
      .axi_aruser_id          (4'b0000          ),// input [3:0]
      .axi_arlen              (my_axi_arlen     ),// input [3:0]
      .axi_arready            (my_axi_arready   ),// output
      .axi_arvalid            (my_axi_arvalid   ),// input
      //读-数据通道
      .axi_rdata              (my_axi_rdata     ),// output [255:0]
      .axi_rid                (                 ),// output [3:0]不管
      .axi_rlast              (my_axi_rlast     ),// output
      .axi_rvalid             (my_axi_rvalid    ),// output
      //debug_interface
      //这些都不用
      .apb_clk                (1'b0 ),
      .apb_rst_n              (1'b1 ),
      .apb_sel                (1'b0 ),
      .apb_enable             (1'b0 ),
      .apb_addr               (8'd0 ),
      .apb_write              (1'b0 ),
      .apb_ready              (     ),
      .apb_wdata              (16'd0),
      .apb_rdata              (     ),
      .apb_int                (     ),
      .debug_data             (     ),
      .debug_slice_state      (     ),
      .debug_calib_ctrl       (     ),
      .ck_dly_set_bin         (     ),
      .force_ck_dly_en        (1'b0 ),
      .force_ck_dly_set_bin   (8'h05),
      .dll_step               (     ),
      .dll_lock               (     ),
      .init_read_clk_ctrl     (2'b0 ),
      .init_slip_step         (4'b0 ), 
      .force_read_clk_ctrl    (1'b0 ),  
      .ddrphy_gate_update_en  (1'b0 ),
      .update_com_val_err_flag(     ),
      .rd_fake_stop           (1'b0 ),
      //hard_interface
      //硬件连接层
      .mem_rst_n              (mem_rst_n),
      .mem_ck                 (mem_ck   ),
      .mem_ck_n               (mem_ck_n ),
      .mem_cke                (mem_cke  ),
      .mem_cs_n               (mem_cs_n ),
      .mem_ras_n              (mem_ras_n),
      .mem_cas_n              (mem_cas_n),
      .mem_we_n               (mem_we_n ),
      .mem_odt                (mem_odt  ),
      .mem_a                  (mem_a    ),
      .mem_ba                 (mem_ba   ),
      .mem_dqs                (mem_dqs  ),
      .mem_dqs_n              (mem_dqs_n),
      .mem_dq                 (mem_dq   ),
      .mem_dm                 (mem_dm   )
   );
/**********************实际输入***************************/
      //1
   wire [1:0]frame_num1;
   wire [31:0]wr_data1;
   assign wr_data1={8'b00000000,r_1,g_1,b_1};
   //2
   wire [1:0]frame_num2;
   wire [31:0]wr_data2;
   assign wr_data2={8'b00000000,r_2,g_2,b_2};
   //3
   wire [1:0]frame_num3;
   wire [31:0]wr_data3;
   assign wr_data3={8'b00000000,r_3,g_3,b_3};
   //4
   wire [1:0]frame_num4;
   wire pixclk_4;
   wire vs_4;
   wire de_4;
   wire clken;
   wire [7:0] r_4;
   wire [7:0] g_4;
   wire [7:0] b_4;
   fiber_hdmi_in f2hget(
      .rstn(rst),
      .hdmi_fake(pixclk_4),
      .vs_fake(vs_4),
      .de_fake(de_4),
      .rout(r_4),
      .gout(g_4),
      .bout(b_4),
      .clken(clken),
      .clk(sys_clk),
      .i_p_refckn_0  (i_p_refckn_0),
      .i_p_refckp_0  (i_p_refckp_0),
      .i_p_l2rxn     (i_p_l2rxn),
      .i_p_l2rxp     (i_p_l2rxp),
      .i_p_l3rxn     (i_p_l3rxn),
      .i_p_l3rxp     (i_p_l3rxp),
      .o_p_l2txn     (o_p_l2txn),
      .o_p_l2txp     (o_p_l2txp),
      .o_p_l3txn     (o_p_l3txn),
      .o_p_l3txp     (o_p_l3txp)
   );
   wire [31:0]wr_data4;
   assign wr_data4={8'b00000000,r_4,g_4,b_4};
///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
   multi_wr_buffer wrmulti(
      //global,可以用ddr3的初始化信号当成全局复位信号
      .rst_n(ddr_init_done&&init_over),
      //写入的相关信号
      //1
      .hdmi_clk1    (pixclk_1),
      .vs_in1       (vs_1)    ,
      .hs_in1       (hs_1)    ,
      .de_in1       (de_1)    ,
      .wr_data1     (wr_data1),
      //2
      .hdmi_clk2    (pixclk_2) ,
      .vs_in2       (vs_2)     ,
      .hs_in2       (hs_2)     ,
      .de_in2       (de_2)     ,
      .wr_data2     (wr_data2) ,
      //3
      .hdmi_clk3    (pixclk_3) ,
      .vs_in3       (vs_3)     ,
      .hs_in3       (hs_3)     ,
      .de_in3       (de_3)     ,
      .wr_data3     (wr_data3) ,
      //4
      .hdmi_clk4    (pixclk_4),
      .vs_in4       (vs_4),
      .hs_in4       ()    ,
      .de_in4       (de_4&clken),
      .wr_data4     (wr_data4)  ,
      .clken(clken),
      //axi控制信号
      .axi_clk            (core_clk)     ,
      //写-地址通道
      .axi_awaddr         (my_axi_awaddr) ,// output [27:0],row15+bank3+col10
      .axi_awlen          (my_axi_awlen) ,// output [3:0]
      .axi_awready        (my_axi_awready) ,// input从机信号
      .axi_awvalid        (my_axi_awvalid) ,// output主机信号
      //写-数据通道
      .axi_wdata          (my_axi_wdata) ,// output [255:0]
      .axi_wready         (my_axi_wready) ,// input从机信号
      .axi_wusero_last    (my_axi_wusero_last) ,// input
      //标识信号
      .frame_num1          (frame_num1),
      .frame_num2          (frame_num2),
      .frame_num3          (frame_num3),
      .frame_num4          (frame_num4),
      //rd
      .frame_num1_rdnow(frame_num1_rdnow),
      .frame_num2_rdnow(frame_num2_rdnow),
      .frame_num3_rdnow(frame_num3_rdnow),
      .frame_num4_rdnow(frame_num4_rdnow),
      .modein(0)
   );
//////////////////////////////////////////////////////////////////
   //配置输出芯片，MS7200
   reg [15:0]rst_cnt;
   always @(posedge cfg_clk or negedge locked)
   begin
      if(!locked)
         rst_cnt <= 16'd0;
      else
      begin
         if(rst_cnt == 16'h2710)
            rst_cnt <= rst_cnt;
         else
            rst_cnt <= rst_cnt + 1'b1;
      end
   end
   wire rst_1ms=(rst_cnt == 16'h2710)?1:0;

   //配置HDMI IN3 和HDMI OUT
    msout_in3 ms72xx_ctl(
        .clk(cfg_clk),              // input
        .rst_n(rst_1ms),          // input
        .init_over(init_over_1),  // output
        .iic_scl(iic_tx_scl),      // output
        .iic_sda(iic_tx_sda)       // inout
    );
     //配置HDMI_IN1 和HDMI_IN2
    msin1_in2 ms7200_double_crtl(
        .clk(cfg_clk),              // input
        .rst_n(init_over_1&rst_1ms),          // input
        .init_over(init_over_2),  // output
        .iic_scl(iic_rx_scl),      // output
        .iic_sda(iic_rx_sda)       // inout
    );
    //需要插入四路hdmi进行初始化
    wire init_over_1;
    wire init_over_2;
    assign init_over=init_over_2;
    assign rstn_out1=rst_1ms;
    assign rstn_out2=rst_1ms;
    assign rstn_out3=rst_1ms;
/***********************输出**************************/
   //输出时序产生
   //1080p60系统参数
   parameter V_FP = 12'd4;         //场前沿
   parameter V_BP = 12'd36;        //场后沿
   parameter V_SYNC = 12'd5;       //场同步信号
   parameter V_ACT = 12'd1080;     //场有效数据
   parameter H_FP = 12'd88;        //行前沿
   parameter H_BP = 12'd148;       //行后沿
   parameter H_SYNC = 12'd44;      //行同步信号
   parameter H_ACT = 12'd1920;     //行有效数据
   wire [11:0]hcnt;
   wire [11:0]vcnt;
   vtc_ctl#(
      .H_SYNC(H_SYNC)               , //行同步信号
      .H_BACK_PORCH(H_BP)         , //行后沿
      .H_ACTIVE(H_ACT)             , //行有效数据
      .H_FRONT_PORCH(H_FP)        , //行前沿
      .V_SYNC(V_SYNC)               , //场同步信号
      .V_BACK_PORCH(V_BP)         , //场后沿
      .V_ACTIVE(V_ACT)             , //场有效信号
      .V_FRONT_PORCH(V_FP)         //场前沿
   ) hdmi_out
   (
      .clk     (hdmiout),
      .rst_n   (init_over),
      .vs_out  (vs_out),
      .hs_out  (hs_out),
      .de_out  (de_out),
      .de_out_pre  (de_out_pre),//1031控制器修改
      .hcnt(hcnt),
      .vcnt(vcnt)
   );
   wire de_out_pre;
   //输出ddr控制
   //复位信号产生
   reg [3:0]rst_outputcnt;
   wire rst_output;
   wire [31:0]rd_data_single/*synthesis PAP_MARK_DEBUG="1"*/;
   wire [31:0]rd_data_multi/*synthesis PAP_MARK_DEBUG="1"*/;
   assign rst_output=(rst_outputcnt==4'b1111)?1:0;
   always@(*)begin
      if(!init_over)rst_outputcnt=0;
      else begin
         if(frame_num1==1)rst_outputcnt[0]=1;
         if(frame_num2==1)rst_outputcnt[1]=1;
         if(frame_num3==1)rst_outputcnt[2]=1;
         if(frame_num4==1)rst_outputcnt[3]=1;
      end      
   end
   ///读出数据,数据产生器,显示位置选择
   wire [31:0] dataout/*synthesis PAP_MARK_DEBUG="1"*/;
   wire mode_2a_ok;
   datamux rgbout(
      .mode(modeout),
      .rd_data_multi(rd_data_multi),
      .rd_data_single(rd_data_single),
      .hcnt(hcnt),
      .vcnt(vcnt),
      .mode_2a_ok(mode_2a_ok),
      .dataout(dataout)
   );
   specialeffect spc(
      .hdmiclk(hdmiout),
      .rst_n(rst_output),
      .data(dataout),
      .hcnt(hcnt),
      .vcnt(vcnt),
      .spec_choose(uart_data),
      .rxdone(rx_done),
      .r_out(r_out),
      .g_out(g_out),
      .b_out(b_out)
   );
   //rdbuffer相关参数
   wire [1:0] frame_num1_rdnow/*synthesis PAP_MARK_DEBUG="1"*/;
   wire [1:0] frame_num2_rdnow/*synthesis PAP_MARK_DEBUG="1"*/;
   wire [1:0] frame_num3_rdnow/*synthesis PAP_MARK_DEBUG="1"*/;
   wire [1:0] frame_num4_rdnow/*synthesis PAP_MARK_DEBUG="1"*/;
   wire [7:0]modeout/*synthesis PAP_MARK_DEBUG="1"*/;
   //读出控制器
   multi_rd_buffer rdmulti(
      //global,，当fram_num第一次不为0的时候可以开始
      .rst_n            (rst_output),
      //读出的相关信号，使用hdmi时序控制器产生
      .hdmi_clk         (hdmiout),  
      .vs_in            (vs_out),
      .hs_in            (hs_out),
      .de_in            (de_out_pre),
      .rd_data_single          (rd_data_single),
      .rd_data_multi          (rd_data_multi),
      .mode_2a_ok             (mode_2a_ok),
      //ddr控制相关信号
      //从ddr读到fifo当中
      .axi_clk           (core_clk),
      //读-地址通道
      .axi_araddr        (my_axi_araddr)    ,// input [27:0]数据地址
      .axi_arlen         (my_axi_arlen)    ,// input [3:0]突发长度
      .axi_arready       (my_axi_arready)    ,// output从机准备信号
      .axi_arvalid       (my_axi_arvalid)    ,// input主机准备信号
      //读-数据通道
      .axi_rdata         (my_axi_rdata)   ,// output [255:0]读出数据
      .axi_rlast         (my_axi_rlast)   ,// output读出最后一位
      .axi_rvalid        (my_axi_rvalid)   , // output从机准备信号
      //ddr存储指示
      .frame_num_already1   (frame_num1)     ,    //0，1，2三帧代号指示，对应读取的地址不
      .frame_num_already2   (frame_num2)     , 
      .frame_num_already3   (frame_num3)     , 
      .frame_num_already4   (frame_num4)     , 
      //rd
      .frame_num1_rdnow(frame_num1_rdnow),
      .frame_num2_rdnow(frame_num2_rdnow),
      .frame_num3_rdnow(frame_num3_rdnow),
      .frame_num4_rdnow(frame_num4_rdnow),
      .modein(uart_data),
      .modeout(modeout)
   );
endmodule