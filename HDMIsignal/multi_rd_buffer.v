module multi_rd_buffer(
   //global,，当fram_num第一次不为0的时候可以开始
   input             rst_n,
   //读出的相关信号，使用hdmi时序控制器产生
   (*CLOCK_BUFFER_TYPE="BUFG"*)input             hdmi_clk,
   input             vs_in,
   input             de_in,
   input             hs_in,
   output   [31:0]   rd_data_single,
   output   [31:0]   rd_data_multi,
   input    mode_2a_ok,
   //ddr控制相关信号
   //从ddr读到fifo当中
   (*CLOCK_BUFFER_TYPE="BUFG"*)input             axi_clk,
   //读-地址通道
   output wire[27:0]  axi_araddr           ,// input [27:0]数据地址
   output reg[3:0]   axi_arlen             ,// input [3:0]突发长度
   input             axi_arready           ,// output从机准备信号
   output reg        axi_arvalid           ,// input主机准备信号
   //读-数据通道
   input    [255:0]  axi_rdata             ,// output [255:0]读出数据
   input             axi_rlast             ,// output读出最后一位
   input             axi_rvalid            , // output从机准备信号
   //ddr存储指示
   input    [1:0]    frame_num_already1 /*synthesis PAP_MARK_DEBUG="1"*/    ,     //0，1，2三帧代号指示，对应读取的地址不同
   input    [1:0]    frame_num_already2 /*synthesis PAP_MARK_DEBUG="1"*/    ,     //0，1，2三帧代号指示，对应读取的地址不同
   input    [1:0]    frame_num_already3 /*synthesis PAP_MARK_DEBUG="1"*/    ,     //0，1，2三帧代号指示，对应读取的地址不同
   input    [1:0]    frame_num_already4 /*synthesis PAP_MARK_DEBUG="1"*/    ,     //0，1，2三帧代号指示，对应读取的地址不同
   //rd frame
   output frame_num1_rdnow/*synthesis PAP_MARK_DEBUG="1"*/,
   output frame_num2_rdnow/*synthesis PAP_MARK_DEBUG="1"*/,
   output frame_num3_rdnow/*synthesis PAP_MARK_DEBUG="1"*/,
   output frame_num4_rdnow/*synthesis PAP_MARK_DEBUG="1"*/,
   //mode
   //四通道预览 0
   //single 1,2,3,4
   //拼接，6种拼接模式，12(5) 13(6) 14(7) 23(8) 24(9) 34(10)
   input [7:0]modein,
   output reg[7:0]modeout
   );
/*************************DEBUG信号*****************************/
/////////////////////////////////////////////////////////////////

/***************************ID*********************************/
   reg [2:0] ID/*synthesis PAP_MARK_DEBUG="1"*/;
   reg [7:0]mode;
   reg [7:0] modein_1d;
   always @(posedge axi_clk or negedge rst_n) begin
      if(!rst_n)begin
         modein_1d<=0;
      end
      else begin
         modein_1d<=modein;
      end
   end
   wire mode_group1;
   wire mode_group2;
   wire mode_group3;
   wire mode_group4;
   assign mode_group1=(modein_1d>=0&&modein_1d<=10)?1:0;
   assign mode_group2=(mode>=1&&mode<=10)?1:0;
   assign mode_group3=(mode==0||(mode>=5&&mode<=10))?1:0;
   assign mode_group4=(mode>=1&&mode<=4)?1:0;

   wire level_multi_ju;
   wire level_single_ju;
   assign level_multi_ju=level_multi<=13'd4032&&(mode==0||(mode>=5&&mode<=10));
   assign level_single_ju=level_single<=10'd480&&(mode>=1&&mode<=4);

   wire leftup;
   wire leftdown;
   wire rightup;
   wire rightdown;
   assign leftup=(bur_num_multi_x>=14'd0&&bur_num_multi_x<=14'd14)&&(bur_num_multi_y>=14'd0&&bur_num_multi_y<=(14'd539-addr_yshift));
   assign leftdown=(bur_num_multi_x>=14'd0&&bur_num_multi_x<=14'd14)&&(bur_num_multi_y>=14'd540-addr_yshift);
   assign rightup=(bur_num_multi_x>=14'd15&&bur_num_multi_x<=14'd29)&&(bur_num_multi_y>=14'd0&&bur_num_multi_y<=(14'd539-addr_yshift));
   assign rightdown=(bur_num_multi_x>=14'd15&&bur_num_multi_x<=14'd29)&&(bur_num_multi_y>=14'd540-addr_yshift);
/***************************多通道信号***************************/
   wire wren_single;
   wire wren_multi;
   reg [27:0] addr1/*synthesis PAP_MARK_DEBUG="1"*/;
   reg [27:0] addr2/*synthesis PAP_MARK_DEBUG="1"*/;
   reg [27:0] addr3/*synthesis PAP_MARK_DEBUG="1"*/;
   reg [27:0] addr4/*synthesis PAP_MARK_DEBUG="1"*/;
   wire [9:0] level_single/*synthesis PAP_MARK_DEBUG="1"*/;
   wire [12:0] level_multi/*synthesis PAP_MARK_DEBUG="1"*/;
   mux1to2 wrenmaker(
      .mode(mode),
      .rst_n(rst_n),
      .pullin(axi_rvalid),
      .push_out1(wren_multi),
      .push_out2(wren_single)
   );
   four2one#(
      .WIDTH(28)
   )addrmaker(
      .ID(ID),
      .rst_n(rst_n),
      .pull_in1(addr1),
      .pull_in2(addr2),
      .pull_in3(addr3),
      .pull_in4(addr4),
      .push_out(axi_araddr)
   );
//////////////////////////////////////////////////////////
   //存储帧数记录，突发次数记录
   wire [1:0]   frame_num1;//0，1，2三帧代号指示，对应读取的地址不同
   reg [1:0]   frame_num1_rdnow;
   reg [13:0]  bur_num1;//突发16200次，从0开始，传输完成一帧

   wire [1:0]   frame_num2;
   reg [1:0]   frame_num2_rdnow;
   reg [13:0]  bur_num2;

   wire [1:0]   frame_num3;
   reg [1:0]   frame_num3_rdnow;
   reg [13:0]  bur_num3;

   wire [1:0]   frame_num4;
   reg [1:0]   frame_num4_rdnow;
   reg [13:0]  bur_num4;

   assign frame_num1=(frame_num_already1==0)?2:(frame_num_already1-1);
   assign frame_num2=(frame_num_already2==0)?2:(frame_num_already2-1);
   assign frame_num3=(frame_num_already3==0)?2:(frame_num_already3-1);
   assign frame_num4=(frame_num_already4==0)?2:(frame_num_already4-1);
   /************************************************************/
   //ddr控制方面
   parameter DDR_addr_offset     =28'b0000_0000_0000_0000_0000_1000_0000;
   parameter DDR_addr_offset_line=28'b0000_0000_0000_0000_0111_1000_0000;
   parameter ADDR_1_BASE1=28'b0000_0000_0000_0000_0000_0000_0000;
   parameter ADDR_1_BASE2=28'b0000_0001_1111_1010_0100_0000_0000;
   parameter ADDR_1_BASE3=28'b0000_0011_1111_0100_1000_0000_0000;

   parameter ADDR_2_BASE1=28'b0001_0000_0000_0000_0000_0000_0000;
   parameter ADDR_2_BASE2=28'b0001_0001_1111_1010_0100_0000_0000;
   parameter ADDR_2_BASE3=28'b0001_0011_1111_0100_1000_0000_0000;

   parameter ADDR_3_BASE1=28'b0010_0000_0000_0000_0000_0000_0000;
   parameter ADDR_3_BASE2=28'b0010_0001_1111_1010_0100_0000_0000;
   parameter ADDR_3_BASE3=28'b0010_0011_1111_0100_1000_0000_0000;

   parameter ADDR_4_BASE1=28'b0011_0000_0000_0000_0000_0000_0000;
   parameter ADDR_4_BASE2=28'b0011_0001_1111_1010_0100_0000_0000;
   parameter ADDR_4_BASE3=28'b0011_0011_1111_0100_1000_0000_0000;

   wire [27:0] addr_shift;
   wire [13:0]addr_bur_shift;
   wire [13:0] addr_yshift;
   assign addr_shift =mode==0?384000:0;
   assign addr_bur_shift=mode==0?1500:0;
   assign addr_yshift=mode==0?100:0;
   //ddr控制状态机
   //0.等待fifo可以写入 1.准备地址 2.发送地址 3.读取并存储数据
   parameter AXI_waiting_s =4'd0;
   parameter AXI_addr_s    =4'd1;
   parameter AXI_Raddr_s   =4'd2;
   parameter AXI_Rdata_s   =4'd3;
   parameter RESTING       =4'd4;
   reg[3:0] axi_state/*synthesis PAP_MARK_DEBUG="1"*/;
   wire [13:0] bur_shift;
   reg [13:0] bur_num_multi_x;//一直加就行
   reg [13:0] bur_num_multi_y;//x每次记到30就加一次
   reg multi_rst;
   reg single_rst;
   assign bur_shift=(mode_group3)?8100:16200;
   always@(posedge axi_clk or negedge rst_n)begin
      if(!rst_n)begin
         bur_num1<=0;
         bur_num2<=0;
         bur_num3<=0;
         bur_num4<=0;
         frame_num1_rdnow<=3;
         frame_num2_rdnow<=3;
         frame_num3_rdnow<=3;
         frame_num4_rdnow<=3;
         addr1<=0;
         addr2<=0;
         addr3<=0;
         addr4<=0;
         bur_num_multi_x<=0;
         bur_num_multi_y<=0;
         ID<=0;
         mode<=0;
         axi_arlen<=4'b1111;
         multi_rst<=0;
         single_rst<=0;
         axi_state<=AXI_waiting_s;
      end
      else begin 
         case (axi_state)
         RESTING:begin
            bur_num1<=0;
            bur_num2<=0;
            bur_num3<=0;
            bur_num4<=0;
            frame_num1_rdnow<=3;
            frame_num2_rdnow<=3;
            frame_num3_rdnow<=3;
            frame_num4_rdnow<=3;
            ID<=0;
            if(hdmiok2d)begin//fixed(cannot change)
               axi_state<=AXI_waiting_s;
               multi_rst<=1;
               single_rst<=1;
            end 
         end
         AXI_waiting_s:begin
            //拼接模式下，写入拼接FIFO
            //每寻址1920个像素点，切换一次基地址
            //跨行寻址，每寻址1920之后，地址偏移1920个再进行寻址
            multi_rst<=0;
            single_rst<=0;
            if(bur_num_multi_x==14'd30)begin
               bur_num_multi_x<=14'd0;
               bur_num_multi_y<=bur_num_multi_y+1;
               if(mode==0&&bur_num_multi_y==14'd880)begin
                  bur_num_multi_y<=14'd0;
                  if(mode_group1)
                     mode<=modein_1d;
                  axi_state<=RESTING;
               end
               else if(bur_num_multi_y==14'd1080)begin//fixed(cannot change)
                  bur_num_multi_y<=14'd0;
                  if(mode_group1)
                     mode<=modein_1d;
                  axi_state<=RESTING;
               end 
            end
            else if(level_multi_ju||level_single_ju)begin
               if(leftup)begin
                  //左上
                  case (mode)
                     0,1,5,6,7:  ID<=1;
                     2,8,9:      ID<=2;
                     3,10:       ID<=3;
                     4:          ID<=4; 
                  endcase
               axi_state<=AXI_addr_s;
               end
               if(leftdown) begin
                  //左下
                  case (mode)
                     1,5,6,7:    ID<=1;
                     2,8,9:      ID<=2;
                     0,3,10:     ID<=3;
                     4:          ID<=4; 
                  endcase
               axi_state<=AXI_addr_s;
               end
               if(rightup)begin
                  //右上
                  case (mode)
                     1:          ID<=1; 
                     0,2,5:      ID<=2; 
                     3,6,8:      ID<=3; 
                     4,7,9,10:   ID<=4; 
                  endcase
               axi_state<=AXI_addr_s;
               end  
               if(rightdown) begin
                  //右下
                  case (mode)
                     1:          ID<=1; 
                     2,5:        ID<=2; 
                     3,6,8:      ID<=3; 
                     4,7,9,10,0: ID<=4; 
                  endcase
               axi_state<=AXI_addr_s;
               end
            end
         end
         AXI_addr_s:begin
            case (ID)
               1: begin
                  if(bur_num1==0)begin
                     frame_num1_rdnow<=frame_num1;
                     case (frame_num1)
                        0: addr1<=ADDR_1_BASE1+addr_shift;
                        1: addr1<=ADDR_1_BASE2+addr_shift;
                        2: addr1<=ADDR_1_BASE3+addr_shift;
                     endcase
                     axi_state<=AXI_Raddr_s;
                  end
                  else if(bur_num1<bur_shift-addr_bur_shift)begin
                     addr1<=addr1+DDR_addr_offset;
                     axi_state<=AXI_Raddr_s;
                  end
                  else begin
                     bur_num1<=0;
                     axi_state<=AXI_addr_s;
                  end
               end
               2:begin
                  if(bur_num2==0)begin
                     frame_num2_rdnow<=frame_num2;
                     case (frame_num2)
                        0: addr2<=ADDR_2_BASE1+addr_shift;
                        1: addr2<=ADDR_2_BASE2+addr_shift;
                        2: addr2<=ADDR_2_BASE3+addr_shift;
                     endcase
                     axi_state<=AXI_Raddr_s;
                  end
                  else if(bur_num2<bur_shift-addr_bur_shift)begin
                     addr2<=addr2+DDR_addr_offset;
                     axi_state<=AXI_Raddr_s;
                  end
                  else begin
                     bur_num2<=0;
                     axi_state<=AXI_addr_s;
                  end
               end
               3:begin
                  if(bur_num3==0)begin
                     frame_num3_rdnow<=frame_num3;
                     case (frame_num3)
                        0: addr3<=ADDR_3_BASE1;
                        1: addr3<=ADDR_3_BASE2;
                        2: addr3<=ADDR_3_BASE3;
                     endcase
                     axi_state<=AXI_Raddr_s;
                  end
                  else if(bur_num3<bur_shift)begin
                     addr3<=addr3+DDR_addr_offset;
                     axi_state<=AXI_Raddr_s;
                  end
                  else begin
                     bur_num3<=0;
                     axi_state<=AXI_addr_s;
                  end
               end
               4:begin
                  if(bur_num4==0)begin
                     frame_num4_rdnow<=frame_num4;
                     case (frame_num4)
                        0: addr4<=ADDR_4_BASE1;
                        1: addr4<=ADDR_4_BASE2;
                        2: addr4<=ADDR_4_BASE3;
                     endcase
                     axi_state<=AXI_Raddr_s;
                  end
                  else if(bur_num4<bur_shift)begin
                     addr4<=addr4+DDR_addr_offset;
                     axi_state<=AXI_Raddr_s;
                  end
                  else begin
                     bur_num4<=0;
                     axi_state<=AXI_addr_s;
                  end
               end
               default:axi_state<=AXI_addr_s;
            endcase
         end
         AXI_Raddr_s:begin
            axi_arvalid<=1;
            if(axi_arvalid&&axi_arready)begin
               axi_arvalid<=0;
               axi_state<=AXI_Rdata_s;
            end
         end
         AXI_Rdata_s:begin
            //数据开始写入fifo
            //fifo和valid同时拉高，数据开始传输
            //参见fifo wren信号
            if(axi_rlast)begin
               bur_num_multi_x<=bur_num_multi_x+1;
               if(mode_group3)begin
                  if(bur_num_multi_x==14)begin
                     case (ID)
                        1: addr1<=addr1+DDR_addr_offset_line;
                        2: addr2<=addr2+DDR_addr_offset_line;
                        3: addr3<=addr3+DDR_addr_offset_line;
                        4: addr4<=addr4+DDR_addr_offset_line;
                     endcase
                  end
                  else if(bur_num_multi_x==29)begin
                     case (ID)
                        1: addr1<=addr1+DDR_addr_offset_line;
                        2: addr2<=addr2+DDR_addr_offset_line;
                        3: addr3<=addr3+DDR_addr_offset_line;
                        4: addr4<=addr4+DDR_addr_offset_line;
                     endcase
                  end
               end
               case (ID)
                  1:bur_num1<=bur_num1+1;
                  2:bur_num2<=bur_num2+1;
                  3:bur_num3<=bur_num3+1;
                  4:bur_num4<=bur_num4+1;
               endcase
               axi_state<=AXI_waiting_s;
            end
         end
         endcase
      end
   end
   rd_buffer rd_single (
      .wr_clk(axi_clk),         // input
      .wr_rst(~rst_n|single_rst),         // input
      .wr_en(wren_single),      // input
      .wr_data(axi_rdata),    // input [255:0]
      .wr_full(),              // output
      .wr_water_level(level_single),    // output [9:0]
      .almost_full(),          // output
      .rd_clk(hdmi_clk),      // input
      .rd_rst(~rst_n|single_rst),        // input
      .rd_en(rd_en_single),           // input
      .rd_data(rd_data_single),       // output [31:0]
      .rd_empty(),            // output
      .rd_water_level(),    // output [12:0]
      .almost_empty() // output
   );
   wire[127:0]data_multi;
   assign data_multi={axi_rdata[223:192],axi_rdata[159:128],axi_rdata[95:64],axi_rdata[31:0]};
   rd_buffer_multi rd_multi (
      .wr_clk(axi_clk),         // input
      .wr_rst(~rst_n|multi_rst),         // input
      .wr_en(wren_multi),      // input
      .wr_data(data_multi),    // input [127:0]
      .wr_full(),              // output
      .wr_water_level(level_multi),    // output [11:0]
      .almost_full(),          // output
      .rd_clk(hdmi_clk),      // input
      .rd_rst(~rst_n|multi_rst),        // input
      .rd_en(rd_en_multi_real),           // input
      .rd_data(rd_data_multi),       // output [31:0]
      .rd_empty(),            // output
      .rd_water_level(),    // output [12:0]
      .almost_empty() // output
   );
   //fifo读出
   //读出时机
   wire rd_en_multi;
   assign rd_en_multi_real=rd_en_multi&mode_2a_ok;
   wire rd_vsyn_first;
   reg rd_vsyn;
   wire rd_en/*synthesis PAP_MARK_DEBUG="1"*/;
   reg vs_1d;
   always @(posedge hdmi_clk or negedge rst_n) begin
      if(!rst_n) vs_1d<=0;
      else vs_1d<=vs_in;
   end
   assign rd_vsyn_first=(~vs_1d)&vs_in;
   always @(*) begin
      if(!rst_n)rd_vsyn=0;
      else if(rd_vsyn_first==1)rd_vsyn=1;
   end
   assign rd_en=de_in&rd_vsyn&(~hdmiok);
   mux1to2 rdenmaker(
      .mode(modeout),
      .rst_n(rst_n),
      .pullin(rd_en),
      .push_out1(rd_en_multi),
      .push_out2(rd_en_single)
   );
   reg hdmiok1d;
   reg hdmiok2d;
   always @(posedge axi_clk or negedge rst_n) begin
      if(!rst_n)begin
         hdmiok1d<=0;
         hdmiok2d<=0;
      end
      else begin
         hdmiok1d<=hdmiok;
         hdmiok2d<=hdmiok1d;
      end
   end
   wire hdmiok/*synthesis PAP_MARK_DEBUG="1"*/;
   always @(posedge hdmiok or negedge rst_n) begin
      if(!rst_n)begin
         modeout<=0;
      end
      else begin
         modeout<=mode;
      end
   end
   HC_cnter hdmiokmaker(
      .clk(hdmi_clk),
      .rst_n(rst_n),
      .vs(vs_in),
      .hdmiok(hdmiok)
   );
endmodule