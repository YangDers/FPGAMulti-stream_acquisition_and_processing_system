module Buf_NetStream(
   input                rst_n,

   input                gmii_clk_in,
   input [7:0]          gmii_data_in,
   input                gmii_valid_in,
   input                gmii_error_in,

   input                gmii_clk_out,
   output reg [7:0]     gmii_data_out,
   output reg           gmii_valid_out,
   output reg           gmii_error_out,
   output reg           last,

   input                grant,
   output               request, 

   //debug
   output [1:0]         buf_rx_state_dbg,
   output [1:0]         buf_tx_state_dbg,
   output [10:0]        buf_wr_data,
   output [10:0]        buf_rd_data,
   output [7:0]         l_data_dbg
   );

   //debug
   assign buf_rx_state_dbg = rx_state;
   assign buf_tx_state_dbg = tx_state;
   assign buf_wr_data = wr_data;
   assign buf_rd_data = rd_data;
   assign l_data_dbg = l_data;

   wire [9:0]        packed_data;
   reg [9:0]         packed_data_d0;
   assign packed_data = {gmii_data_in,gmii_valid_in,gmii_error_in};
   //移位寄存器缓存数据
   always@(posedge gmii_clk_in) begin
      if(~rst_n) begin
         packed_data_d0 <= 0;
      end
      else begin
         packed_data_d0 <= packed_data;
      end
   end

   localparam IDLE = 0;
   localparam WAIT = 1;
   localparam WR = 2;
   localparam RD = 2;
   
   reg [1:0]      rx_state    ,tx_state;
   reg            wr_en       ,rd_en;
   reg [10:0]     wr_data;
   wire [10:0]    rd_data;
   wire [7:0]     l_data;
   wire           l_valid     ,l_error       ,l_last;
   //状态机读取数据
   always@(posedge gmii_clk_in) begin
      if(~rst_n) begin
         rx_state <= IDLE;
         wr_en <= 0;
         wr_data <= 0;
      end
      else begin
         case(rx_state)
            IDLE: begin
               wr_en <= 1'b0;
               wr_data <= 0;
               if(gmii_valid_in) begin
                  rx_state <= WAIT;
               end
               else;
            end
            WAIT: begin
               if(gmii_valid_in) begin
                  rx_state <= WR;
                  wr_data <= {packed_data_d0,1'b0};
                  wr_en <= 1'b1;
               end
               else begin
                  rx_state <= IDLE;
                  wr_data <= {packed_data_d0,1'b1};
                  wr_en <= 1'b1;
               end
            end
            WR: begin
               if(gmii_valid_in) begin
                  rx_state <= WR;
                  wr_data <= {packed_data_d0,1'b0};
                  wr_en <= 1'b1;
               end
               else begin
                  rx_state <= IDLE;
                  wr_data <= {packed_data_d0,1'b1};
                  wr_en <= 1'b1;
               end
            end
         endcase
      end
   end

   Eth_buf inst (
      .wr_clk(gmii_clk_in),                // input
      .wr_rst(~rst_n),                // input
      .wr_en(wr_en),                  // input
      .wr_data(wr_data),              // input [10:0]
      .wr_full(),              // output
      .almost_full(),      // output

      .rd_clk(gmii_clk_out),                // input
      .rd_rst(~rst_n),                // input
      .rd_en(rd_en),                  // input
      .rd_data(rd_data),              // output [10:0]
      .rd_empty(rd_empty),            // output
      .almost_empty()     // output
   );
   assign request = ~rd_empty;
   assign {l_data,l_valid,l_error,l_last} = rd_data;
   always@(posedge gmii_clk_out) begin
      if(~rst_n) begin
         tx_state <= IDLE;
         rd_en <= 0;
         gmii_data_out <= 8'd0;
         gmii_valid_out <= 0;
         gmii_error_out <= 0;
         last <= 0;
      end
      else begin
         case(tx_state)
            IDLE: begin
               gmii_data_out <= 8'd0;
               gmii_valid_out <= 0;
               gmii_error_out <= 0;
               last <= 0;
               if(grant) begin
                  rd_en <= 1;
                  tx_state <= WAIT;
               end
               else begin
                  rd_en <= 0;
               end
            end
            WAIT: begin
               tx_state <= RD;
            end
            RD: begin
               gmii_data_out <= l_data;
               gmii_valid_out <= l_valid;
               gmii_error_out <= l_error;
               last <= l_last;
               if(l_last == 1) begin
                  tx_state <= IDLE;
               end
               else tx_state <= RD;
            end
         endcase
      end
   end

endmodule