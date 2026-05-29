// ============================================================
//  Synchronous FIFO
//  - Single clock domain
//  - Parameterized DATA_WIDTH and DEPTH
//  - Active-low reset (rstn)
//  - Full / Empty flag generation via counter
// ============================================================

module sync_fifo
#(
  parameter DATA_W = 8,
  parameter DEPTH  = 16,
  parameter PTR_SZ = $clog2(DEPTH)
)
(
  input                    clk,
  input                    rstn,
  input                    i_wren,
  input  [DATA_W-1:0]      i_wrdata,
  input                    i_rden,
  output reg [DATA_W-1:0]  o_rddata,
  output wire              o_full,
  output wire              o_empty
);

  // ---- Internal Memory ----
  reg [DATA_W-1:0]  fifo_mem [DEPTH-1:0];

  // ---- Pointers ----
  reg [PTR_SZ-1:0]  wptr;
  reg [PTR_SZ-1:0]  rdptr;

  // ---- Occupancy Counter ----
  reg [PTR_SZ-1:0]  cntr;

  // ---- Full / Empty Flags ----
  assign o_full  = (cntr == DEPTH - 1);
  assign o_empty = (cntr == 0);

  // ---- Counter Logic ----
  always @(posedge clk or negedge rstn) begin
    if (!rstn)
      cntr <= {PTR_SZ{1'b0}};
    else begin
      if (i_wren && !i_rden && !o_full)
        cntr <= cntr + 1;
      else if (i_rden && !i_wren && !o_empty)
        cntr <= cntr - 1;
    end
  end

  // ---- Write Logic ----
  always @(posedge clk or negedge rstn) begin
    if (!rstn)
      wptr <= {PTR_SZ{1'b0}};
    else if (!o_full && i_wren) begin
      fifo_mem[wptr] <= i_wrdata;
      wptr           <= wptr + 1'b1;
    end
  end

  // ---- Read Logic ----
  always @(posedge clk or negedge rstn) begin
    if (!rstn)
      rdptr <= {PTR_SZ{1'b0}};
    else if (i_rden && !o_empty) begin
      o_rddata <= fifo_mem[rdptr];
      rdptr    <= rdptr + 1'b1;
    end
  end

endmodule
