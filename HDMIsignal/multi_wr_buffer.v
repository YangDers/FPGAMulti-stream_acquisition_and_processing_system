module multi_wr_buffer(
   //global,������ddr3�ĳ�ʼ���źŵ���ȫ�ָ�λ�ź�
   input             rst_n,
   //д�������ź�
   //д���ź�1
   (*CLOCK_BUFFER_TYPE="BUFG"*)input             hdmi_clk1,
   input             vs_in1,
   input             de_in1,
   input             hs_in1,
   input   [31:0]    wr_data1,
   //д���ź�2
   (*CLOCK_BUFFER_TYPE="BUFG"*)input             hdmi_clk2,
   input             vs_in2,
   input             de_in2,
   input             hs_in2,
   input   [31:0]    wr_data2,
   //д���ź�3
   (*CLOCK_BUFFER_TYPE="BUFG"*)input             hdmi_clk3,
   input             vs_in3,
   input             de_in3,
   input             hs_in3,
   input   [31:0]    wr_data3,
   //д���ź�4
   (*CLOCK_BUFFER_TYPE="BUFG"*)input             hdmi_clk4,
   input             vs_in4,
   input             de_in4,
   input             hs_in4,
   input   [31:0]    wr_data4,
   input             clken,
   //��buffer���ж�����ddr���е��ź�
   (*CLOCK_BUFFER_TYPE="BUFG"*)input             axi_clk,
   //д-��ַͨ��
   output wire  [27:0]axi_awaddr           ,// input [27:0],row15+bank3+col10
   output reg  [3:0] axi_awlen            ,// input [3:0]
   input             axi_awready          ,// output�ӻ��ź�
   output reg        axi_awvalid          ,// input�����ź�
   //д-����ͨ��
   output    [255:0] axi_wdata            ,// input [255:0]
   input             axi_wready           ,// output�ӻ��ź�
   input             axi_wusero_last      ,// output
   //��ʶ�ź�
   output            frame_num1,
   output            frame_num2,
   output            frame_num3,
   output            frame_num4,
   //rd frame
   input [1:0]frame_num1_rdnow,
   input [1:0]frame_num2_rdnow,
   input [1:0]frame_num3_rdnow,
   input [1:0]frame_num4_rdnow,
   //��ͨ��Ԥ�� 0
   //single 1,2,3,4
   //ƴ�ӣ�6��ƴ��ģʽ��12(5) 13(6) 14(7) 23(8) 24(9) 34(10)
   input [7:0]modein
   );
   /*************************DEBUG�ź�*****************************/
   /***************************ͨ��ID*********************************/
   reg [2:0] ID/*synthesis PAP_MARK_DEBUG="1"*/;//axiʱ����
   wire [7:0]mode;
   assign mode=modein;
   /****************************����Ԥ��ȡ����**********************/
   reg prerd_start;
   reg prerd_stop;
   reg [3:0]burst_once_cnt;
   wire rd_en;
   assign rd_en=(axi_wready|prerd_start)&(~prerd_stop);
   /***************************��ͨ���ź�����***********************************/
   wire [255:0] rd_data1;
   wire [255:0] rd_data2;
   wire [255:0] rd_data3;
   wire [255:0] rd_data4;
   wire rden1;
   wire rden2;
   wire rden3;
   wire rden4;
   reg [27:0] addr1;
   reg [27:0] addr2;
   reg [27:0] addr3;
   reg [27:0] addr4;
   wire [9:0] level1;
   wire [9:0] level2;
   wire [9:0] level3;
   wire [9:0] level4;
   one2four rdenmaker(
      .ID(ID),
      .rst_n(rst_n),
      .pull_in(rd_en),
      .push_out1(rden1),
      .push_out2(rden2),
      .push_out3(rden3),
      .push_out4(rden4)
   );
   four2one#(
      .WIDTH(256)
   ) datamaker(
      .ID(ID),
      .rst_n(rst_n),
      .pull_in1(rd_data1),
      .pull_in2(rd_data2),
      .pull_in3(rd_data3),
      .pull_in4(rd_data4),
      .push_out(axi_wdata)
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
      .push_out(axi_awaddr)
   );
   /***************************��������***********************************/
   //����д�����
   //�ź�Դ1
   //1.�����֡���� 2.���de���� 3.���Կ�ʼ��д
   reg channel1_1d;
   reg channel1_2d;
   reg wr_vsyn_first1;
   always @(posedge hdmi_clk1 or negedge rst_n) begin
      if(!rst_n) begin
         wr_vsyn_first1<=0;
         channel1_1d<=0;
         channel1_2d<=0;
      end
      else begin
         channel1_1d<=channel_selcet[3];
         channel1_2d<=channel1_1d;
         if(channel1_2d==1)begin
            if(hdmiok1)
               wr_vsyn_first1<=1;
         end
         else if(channel1_2d==0)wr_vsyn_first1<=0;
      end
   end
   wire hdmiok1;
   HC_cnter cnt1(
      .clk(hdmi_clk1),
      .rst_n(rst_n),
      .vs(vs_in1),
      .hdmiok(hdmiok1)
   );
   wire wr_en1;
   assign  wr_en1=de_in1&&wr_vsyn_first1;//��ƽ���е�
   wr_buffer wb1(
      .wr_clk        (hdmi_clk1),                // input
      .wr_rst        (((~rst_n)|(~channel_selcet[3]))),                // input
      .wr_en         (wr_en1),                  // input
      .wr_data       (wr_data1),              // input [31:0]
      .wr_full       (),              // output
      .wr_water_level(),    // output [12:0]
      .almost_full   (),      // output
      .rd_clk        (axi_clk),                // input
      .rd_rst        (((~rst_n)|(~channel_selcet[3]))),                // input
      .rd_en         (rden1),                  // input
      .rd_data       (rd_data1),              // output [255:0]
      .rd_empty      (),            // output
      .rd_water_level(level1),    // output [9:0]
      .almost_empty  ()     // output
   );

   //�ź�Դ2
   //1.�����֡���� 2.���de���� 3.���Կ�ʼ��д
   reg wr_vsyn_first2;
   reg channel2_1d;
   reg channel2_2d;
   always @(posedge hdmi_clk2 or negedge rst_n) begin
      if(!rst_n) begin
         wr_vsyn_first2<=0;
         channel2_1d<=0;
         channel2_2d<=0;
      end
      else begin
         channel2_1d<=channel_selcet[2];
         channel2_2d<=channel2_1d;
         if(channel2_2d==1)begin
            if(hdmiok2)
               wr_vsyn_first2<=1;
         end
         else if(channel2_2d==0)wr_vsyn_first2<=0;
      end
   end
   wire hdmiok2;
   HC_cnter cnt2(
      .clk(hdmi_clk2),
      .rst_n(rst_n),
      .vs(vs_in2),
      .hdmiok(hdmiok2)
   );
   wire wr_en2;
   assign  wr_en2=de_in2&&wr_vsyn_first2;//��ƽ���е�
   wr_buffer wb2(
      .wr_clk        (hdmi_clk2),                // input
      .wr_rst        (((~rst_n)|(~channel_selcet[2]))),                // input
      .wr_en         (wr_en2),                  // input
      .wr_data       (wr_data2),              // input [31:0]
      .wr_full       (),              // output
      .wr_water_level(),    // output [12:0]
      .almost_full   (),      // output
      .rd_clk        (axi_clk),                // input
      .rd_rst        (((~rst_n)|(~channel_selcet[2]))),                // input
      .rd_en         (rden2),                  // input
      .rd_data       (rd_data2),              // output [255:0]
      .rd_empty      (),            // output
      .rd_water_level(level2),    // output [9:0]
      .almost_empty  ()     // output
   );

   //�ź�Դ3
   //1.�����֡���� 2.���de���� 3.���Կ�ʼ��д
   reg wr_vsyn_first3;
   reg channel3_1d;
   reg channel3_2d;
   always @(posedge hdmi_clk3 or negedge rst_n) begin
      if(!rst_n) begin
         wr_vsyn_first3<=0;
         channel3_1d<=0;
         channel3_2d<=0;
      end
      else begin
         channel3_1d<=channel_selcet[1];
         channel3_2d<=channel3_1d;
         if(channel3_2d==1)begin
            if(hdmiok3)
               wr_vsyn_first3<=1;
         end
         else if(channel3_2d==0)wr_vsyn_first3<=0;
      end
   end
   wire hdmiok3;
   HC_cnter cnt3(
      .clk(hdmi_clk3),
      .rst_n(rst_n),
      .vs(vs_in3),
      .hdmiok(hdmiok3)
   );
   wire wr_en3;
   assign  wr_en3=de_in3&&wr_vsyn_first3;//��ƽ���е�
   wr_buffer wb3(
      .wr_clk        (hdmi_clk3),                // input
      .wr_rst        (((~rst_n)|(~channel_selcet[1]))),                // input
      .wr_en         (wr_en3),                  // input
      .wr_data       (wr_data3),              // input [31:0]
      .wr_full       (),              // output
      .wr_water_level(),    // output [12:0]
      .almost_full   (),      // output
      .rd_clk        (axi_clk),                // input
      .rd_rst        (((~rst_n)|(~channel_selcet[1]))),                // input
      .rd_en         (rden3),                  // input
      .rd_data       (rd_data3),              // output [255:0]
      .rd_empty      (),            // output
      .rd_water_level(level3),    // output [9:0]
      .almost_empty  ()     // output
   );

   //�ź�Դ4
   //1.�����֡���� 2.���de���� 3.���Կ�ʼ��д
   reg wr_vsyn_first4;
   reg channel4_1d;
   reg channel4_2d;
   always @(posedge hdmi_clk4 or negedge rst_n) begin
      if(!rst_n) begin
         wr_vsyn_first4<=0;
         channel4_1d<=0;
         channel4_2d<=0;
      end
      else begin
         channel4_1d<=channel_selcet[0];
         channel4_2d<=channel4_1d;
         if(channel4_2d==1)begin
            if(hdmiok4)
               wr_vsyn_first4<=1;
         end
         else if(channel4_2d==0)wr_vsyn_first4<=0;
      end
   end
   wire hdmiok4;
   HC_cnter#(.MODE(1)) cnt4(
      .clk(hdmi_clk4),
      .rst_n(rst_n),
      .vs(vs_in4),
      .clken(clken),
      .hdmiok(hdmiok4)
   );
   wire wr_en4;
   assign  wr_en4=de_in4&&wr_vsyn_first4;//��ƽ���е�
   wr_buffer wb4(
      .wr_clk        (hdmi_clk4),                // input
      .wr_rst        (((~rst_n)|(~channel_selcet[0]))),// input
      .wr_en         (wr_en4),                  // input
      .wr_data       (wr_data4),              // input [31:0]
      .wr_full       (),              // output
      .wr_water_level(),    // output [12:0]
      .almost_full   (),      // output
      .rd_clk        (axi_clk),                // input
      .rd_rst        (((~rst_n)|(~channel_selcet[0]))),                // input
      .rd_en         (rden4),                  // input
      .rd_data       (rd_data4),              // output [255:0]
      .rd_empty      (),            // output
      .rd_water_level(level4),    // output [9:0]
      .almost_empty  ()     // output
   );
   /******************************************************************************************/
   //axi���ߴ������
   //״̬��
   //��֡����Ļ���ַ
   //ͻ������16�Σ�ÿ�δ�����������128��1֡Ҫ����16200��
   parameter DDR_addr_offset=28'd128;
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
   //0.�ȴ����ݴﵽ�������� 1.��ַ׼�� 2.����׼�� 3.��ַ����׼�� 4.���ݷ���
   parameter AXI_waiting_s   = 0;
   parameter AXI_addr_s      = 1;
   parameter AXI_Taddr_s     = 2;
   parameter AXI_Tdata_s     = 3;
   reg[3:0] axi_state;
   //�洢֡����¼��ͻ��������¼
   reg [1:0]   frame_num1;//0��1��2��֡����ָʾ����Ӧ��ȡ�ĵ�ַ��ͬ
   reg [13:0]  bur_num1;//ͻ��16200�Σ���0��ʼ���������һ֡

   reg [1:0]   frame_num2;
   reg [13:0]  bur_num2;

   reg [1:0]   frame_num3;
   reg [13:0]  bur_num3;

   reg [1:0]   frame_num4;
   reg [13:0]  bur_num4;
   //ID��ѡ�д�����¼
   reg [9:0]chosen_former;
   reg [3:0]channel_selcet;
   reg [3:0]channel_ok;
   always @(posedge axi_clk or negedge rst_n) begin
      if(!rst_n)begin
         frame_num1<=2'd0;
         bur_num1<=14'd0;
         frame_num2<=2'd0;
         bur_num2<=14'd0;
         frame_num3<=2'd0;
         bur_num3<=14'd0;
         frame_num4<=2'd0;
         bur_num4<=14'd0;
         prerd_start<=0;
         burst_once_cnt<=0;
         prerd_stop<=0;
         addr1<=0;
         addr2<=0;
         addr3<=0;
         addr4<=0;
         ID<=0;
         chosen_former<=0;
         channel_selcet<=4'b1100;
         channel_ok<=4'b0000;
         axi_state<=AXI_waiting_s;
      end
      else begin
         case (axi_state)
            AXI_waiting_s:begin
               if(channel_selcet==4'b1100)begin
                  //��ȡͨ���ٲã�����ʲô�������fifo��ȡ����д��ddr
                  //�ȸ�����ͨ��������ͨ��������1֡ͼ��֮�󣩣��ٸ�����ͨ��������������1֡ͼ��֮���л���
                  //ͨ����ʱ����
                  if(channel_ok[3]==1&&channel_ok[2]==1)begin
                     channel_selcet<=4'b0011;
                     channel_ok[3]<=0;
                     channel_ok[2]<=0;
                     bur_num1<=0;
                     bur_num2<=0;
                     chosen_former<=0;
                     ID<=0;
                  end
                  else if(level1>=32+(chosen_former<<4))begin
                     ID<=1;
                     chosen_former<=chosen_former+3;
                     if(chosen_former==12)chosen_former<=0;
                     axi_state<=AXI_addr_s;
                  end
                  else if(level2>=32)begin
                     ID<=2;
                     axi_state<=AXI_addr_s;
                  end
               end
               else if(channel_selcet==4'b0011)begin
                  if(channel_ok[1]==1&&channel_ok[0]==1)begin
                     channel_selcet<=4'b1100;
                     channel_ok[1]<=0;
                     channel_ok[0]<=0;
                     bur_num3<=0;
                     bur_num4<=0;
                     chosen_former<=0;
                     ID<=0;
                  end
                  else if(level3>=32+(chosen_former<<4))begin
                     ID<=3;
                     chosen_former<=chosen_former+3;
                     if(chosen_former==12)chosen_former<=0;
                     axi_state<=AXI_addr_s;
                  end
                  else if(level4>=32)begin
                     ID<=4;
                     axi_state<=AXI_addr_s;
                  end
               end
            end
            AXI_addr_s: begin
               case (ID)
                  1:begin
                     if(bur_num1==0)begin
                        axi_awlen<=4'b1111;
                        //����Ԥ��ȡһ��,��ǰһ�Ľ���
                        prerd_start<=1;
                        case (frame_num1)
                           0: addr1<=ADDR_1_BASE1;
                           1: addr1<=ADDR_1_BASE2;
                           2: addr1<=ADDR_1_BASE3;
                        endcase
                        axi_state<=AXI_Taddr_s;
                     end
                     else if(bur_num1<16200)begin
                        prerd_start<=1;
                        addr1<=addr1+DDR_addr_offset;
                        axi_awlen<=4'b1111;
                        axi_state<=AXI_Taddr_s;
                     end
                     else begin
                        channel_ok[3]<=1'b1;
                        bur_num1<=0;
                        frame_num1<=frame_num1+1;
                        if(frame_num1==2)
                           frame_num1<=0;
                        else if((frame_num1+1)==frame_num1_rdnow)frame_num1<=frame_num1+2;
                        axi_state<=AXI_addr_s;
                     end
                  end 
                  2:begin
                     if(bur_num2==0)begin
                        axi_awlen<=4'b1111;
                        //����Ԥ��ȡһ��,��ǰһ�Ľ���
                        prerd_start<=1;
                        case (frame_num2)
                           0: addr2<=ADDR_2_BASE1;
                           1: addr2<=ADDR_2_BASE2;
                           2: addr2<=ADDR_2_BASE3;
                        endcase
                        axi_state<=AXI_Taddr_s;
                     end
                     else if(bur_num2<16200)begin
                        prerd_start<=1;
                        addr2<=addr2+DDR_addr_offset;
                        axi_awlen<=4'b1111;
                        axi_state<=AXI_Taddr_s;
                     end
                     else begin
                        channel_ok[2]<=1'b1;
                        bur_num2<=0;
                        frame_num2<=frame_num2+1;
                        if(frame_num2==2)
                           frame_num2<=0;
                        else if((frame_num2+1)==frame_num2_rdnow)frame_num2<=frame_num2+2;
                        axi_state<=AXI_addr_s;
                     end
                  end
                  3:begin
                     if(bur_num3==0)begin
                        axi_awlen<=4'b1111;
                        //����Ԥ��ȡһ��,��ǰһ�Ľ���
                        prerd_start<=1;
                        case (frame_num3)
                           0: addr3<=ADDR_3_BASE1;
                           1: addr3<=ADDR_3_BASE2;
                           2: addr3<=ADDR_3_BASE3;
                        endcase
                        axi_state<=AXI_Taddr_s;
                     end
                     else if(bur_num3<16200)begin
                        prerd_start<=1;
                        addr3<=addr3+DDR_addr_offset;
                        axi_awlen<=4'b1111;
                        axi_state<=AXI_Taddr_s;
                     end
                     else begin
                        channel_ok[1]<=1'b1;
                        bur_num3<=0;
                        frame_num3<=frame_num3+1;
                        if(frame_num3==2)
                           frame_num3<=0;
                        else if((frame_num3+1)==frame_num3_rdnow)frame_num3<=frame_num3+2;
                        axi_state<=AXI_addr_s;
                     end
                  end
                  4:begin
                     if(bur_num4==0)begin
                        axi_awlen<=4'b1111;
                        //����Ԥ��ȡһ��,��ǰһ�Ľ���
                        prerd_start<=1;
                        case (frame_num4)
                           0: addr4<=ADDR_4_BASE1;
                           1: addr4<=ADDR_4_BASE2;
                           2: addr4<=ADDR_4_BASE3;
                        endcase
                        axi_state<=AXI_Taddr_s;
                     end
                     else if(bur_num4<16200)begin
                        prerd_start<=1;
                        addr4<=addr4+DDR_addr_offset;
                        axi_awlen<=4'b1111;
                        axi_state<=AXI_Taddr_s;
                     end
                     else begin
                        channel_ok[0]<=1'b1;
                        bur_num4<=0;
                        frame_num4<=frame_num4+1;
                        if(frame_num4==2)
                           frame_num4<=0;
                        else if((frame_num4+1)==frame_num4_rdnow)frame_num4<=frame_num4+2;
                        axi_state<=AXI_addr_s;
                     end
                  end
               endcase
            end
            AXI_Taddr_s: begin
               //����Ԥ��ȡһ��
               prerd_start<=0;
               axi_awvalid<=1;
               if(axi_awvalid&&axi_awready)begin
                  axi_awvalid<=0;
                  axi_state<=AXI_Tdata_s;
               end
            end
            AXI_Tdata_s: begin
               //���ݿ�ʼȡ��
               //fifo��readyͬʱ���ߣ����ݿ�ʼ����
               //�μ�fifo rden�ź�
               if(axi_wusero_last)begin
                  //����ͻ��������ɣ��������һλ
                  case (ID)
                     1: bur_num1<=bur_num1+1;
                     2: bur_num2<=bur_num2+1;
                     3: bur_num3<=bur_num3+1;
                     4: bur_num4<=bur_num4+1;
                  endcase
                  axi_state<=AXI_waiting_s;
               end
               if(axi_wready&burst_once_cnt==14)begin
                  prerd_stop<=1;
                  burst_once_cnt<=burst_once_cnt+1;
               end
               else if(axi_wready&burst_once_cnt==15)begin
                  prerd_stop<=0;
                  burst_once_cnt<=0;
               end
               else if(axi_wready) begin
                  burst_once_cnt<=burst_once_cnt+1;
               end
            end
         endcase
      end
   end
endmodule