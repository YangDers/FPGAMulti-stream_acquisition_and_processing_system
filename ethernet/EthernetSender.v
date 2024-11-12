module EthernetSender (
   input wire clk,            // 时钟信号
   input wire rst_n,          // 复位信号，低电平有效
   input wire [7:0] data_in,  // 待发送的数据输入
   input wire valid_in,       // 数据输入有效信号
   input upper_ready,

   output reg tx_en,          // 发送使能信号
   output reg [7:0] tx_data,  // 发送的数据输出
   output wire tx_error,
   output reg tx_done,         // 数据包发送完成标志
   output reg ready,
   output reg require
);
   assign tx_error = 0;

   // 状态定义
   localparam IDLE = 5'd0;           // 空闲状态
   localparam READ_DATA = 5'd1;      // 缓存数据
   localparam PREAMBLE = 5'd2;       // 发送前导码
   localparam SFD = 5'd3;            // 发送帧起始分隔符
   localparam SEND_MAC = 5'd4;       // 发送目的和源MAC地址
   localparam SEND_LEN = 5'd5;      // 发送以太网帧类型
   localparam SEND_DATA = 5'd6;      // 发送数据
   localparam PAD = 5'd7;            // 填充数据（若数据长度不足）
   localparam CRC = 5'd8;            // 发送校验和
   localparam WAIT = 5'd9;

   reg [4:0] state;

   // 常量定义
   localparam [7:0] PREAMBLE_BYTE = 8'h55;   // 前导码字节
   localparam [7:0] SFD_BYTE = 8'hD5;        // 帧起始分隔符
   localparam [47:0] DEST_MAC = 48'hFF_FF_FF_FF_FF_FF;  // 目的MAC地址（广播地址）
   localparam [47:0] SRC_MAC = 48'hCA_36_9F_2B_47_D8;   // 源MAC地址

   // 数据帧的计数
   reg [15:0] byte_count;

   // 数据缓冲区
   reg [7:0] data_buf [0:1500];
   reg [15:0] data_len;

   // CRC校验计算模块实例化
   wire [31:0] crc_data, crc_next;
   wire [7:0] crc_next_t;
   reg crc_en;
   reg crc_clr;

   assign crc_next_t = crc_next[31:24];
   CRC32 crc_calculator (
      .clk(clk),
      .rst_n(rst_n),
      .data(tx_data),
      .crc_en(crc_en),
      .crc_clr(crc_clr),
      .crc_data(crc_data),
      .crc_next(crc_next)
   );

    // 状态机
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         state <= IDLE;
         byte_count <= 0;
         tx_en <= 0;
         tx_data <= 8'b0;
         tx_done <= 0;
         crc_en <= 0;
         ready <= 0;
      end else begin
         case (state)
               IDLE: begin
                  tx_en <= 0;
                  tx_done <= 0;
                  byte_count <= 0;
                  data_len <= 0;
                  crc_en <= 0;
                  ready <= 1;
                  if (valid_in) begin
                     data_buf[0] <= data_in;
                     data_len <= data_len + 1;
                     state <= READ_DATA;
                     require <= 1;
                  end
               end
               READ_DATA: begin
                  ready <= 0;
                  if(valid_in) begin
                     data_buf[data_len] <= data_in;
                     data_len<=data_len+1;
                  end
                  else begin
                     state<=WAIT;
                  end
               end
               WAIT: begin//等待上层模块就绪
                  if(upper_ready) begin
                     state<=PREAMBLE;
                     require<=0;
                  end
                  else;
               end
               PREAMBLE: begin
                  tx_en <= 1;
                  ready <= 0;
                  tx_data <= PREAMBLE_BYTE;
                  if (byte_count == 6) begin
                     state <= SFD;
                     byte_count <= 0;
                  end else begin
                     byte_count <= byte_count + 1;
                  end
               end
               SFD: begin
                  tx_data <= SFD_BYTE;
                  state <= SEND_MAC;
                  ready <= 0;
               end
               SEND_MAC: begin
                  crc_en <= 1;
                  ready <= 0;
                  case (byte_count)
                     0: tx_data <= DEST_MAC[47:40];
                     1: tx_data <= DEST_MAC[39:32];
                     2: tx_data <= DEST_MAC[31:24];
                     3: tx_data <= DEST_MAC[23:16];
                     4: tx_data <= DEST_MAC[15:8];
                     5: tx_data <= DEST_MAC[7:0];
                     6: tx_data <= SRC_MAC[47:40];
                     7: tx_data <= SRC_MAC[39:32];
                     8: tx_data <= SRC_MAC[31:24];
                     9: tx_data <= SRC_MAC[23:16];
                     10: tx_data <= SRC_MAC[15:8];
                     11: tx_data <= SRC_MAC[7:0];
                     default: tx_data <= 8'h00;
                  endcase
                  if (byte_count == 11) begin
                     state <= SEND_LEN;
                     byte_count <= 0;
                  end
                  else byte_count <= byte_count+1;
               end
               SEND_LEN: begin
                  ready <= 0;
                  tx_data <= (byte_count == 0) ? data_len[15:8] : data_len[7:0];
                  if (byte_count == 1) begin
                     state <= SEND_DATA;
                     byte_count <= 0;
                  end
                  else byte_count <= byte_count + 1;
               end
               SEND_DATA: begin
                  ready <= 0;
                  tx_data <= data_buf[byte_count];
                  if (byte_count == data_len - 1) begin
                     if(data_len>=46) state <= CRC;
                     else state <= PAD;
                     byte_count <= 0;
                  end else begin
                     byte_count <= byte_count + 1;
                  end
               end
               PAD: begin
                  ready <= 0;
                  tx_data <= 8'h00;
                  byte_count <= byte_count + 1;
                  if (byte_count >= 46 - data_len) begin
                     state <= CRC;
                     byte_count <= 0;
                  end
               end
               CRC: begin
                  ready <= 0;
                  crc_en <= 0;
                  tx_en <= 1'b1;
                  byte_count <= byte_count + 1'b1;
                  if(byte_count == 0)
                     tx_data <= {~crc_next_t[0], ~crc_next_t[1], ~crc_next_t[2],~crc_next_t[3],
                                 ~crc_next_t[4], ~crc_next_t[5], ~crc_next_t[6],~crc_next_t[7]};
                  else if(byte_count == 1)
                     tx_data <= {~crc_data[16], ~crc_data[17], ~crc_data[18],
                                 ~crc_data[19], ~crc_data[20], ~crc_data[21], 
                                 ~crc_data[22],~crc_data[23]};
                  else if(byte_count == 2) begin
                     tx_data <= {~crc_data[8], ~crc_data[9], ~crc_data[10],
                                 ~crc_data[11],~crc_data[12], ~crc_data[13], 
                                 ~crc_data[14],~crc_data[15]};                              
                  end
                  else if(byte_count == 3) begin
                     tx_data <= {~crc_data[0], ~crc_data[1], ~crc_data[2],~crc_data[3],
                                 ~crc_data[4], ~crc_data[5], ~crc_data[6],~crc_data[7]};  
                     tx_done <= 1'b1;
                     state <= IDLE;
                     byte_count <= 1'b0;
                  end   
                  else;
               end
         endcase
      end
   end

//发送完成信号及crc值复位信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        crc_clr <= 1'b0;
    end
    else begin
        crc_clr <= tx_done;
    end
end

endmodule
