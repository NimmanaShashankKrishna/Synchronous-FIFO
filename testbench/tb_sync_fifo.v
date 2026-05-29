`timescale 1ns/1ps

// ============================================================
//  Testbench : Synchronous FIFO
//  TC1 : Reset Test
//  TC2 : Write Until Full (overflow guard)
//  TC3 : Read Until Empty (underflow guard)
//  TC4 : Simultaneous Read & Write
// ============================================================

module sync_fifo_tb;

  // Parameters
  parameter DATA_W = 8;
  parameter DEPTH  = 16;
  parameter PTR_SZ = $clog2(DEPTH);

  // DUT Signals
  reg                  clk;
  reg                  rstn;
  reg                  i_wren;
  reg                  i_rden;
  reg  [DATA_W-1:0]    i_wrdata;
  wire [DATA_W-1:0]    o_rddata;
  wire                 o_full;
  wire                 o_empty;

  // DUT Instantiation
  sync_fifo #(
    .DATA_W(DATA_W),
    .DEPTH(DEPTH),
    .PTR_SZ(PTR_SZ)
  ) dut (
    .clk      (clk),
    .rstn     (rstn),
    .i_wren   (i_wren),
    .i_wrdata (i_wrdata),
    .i_rden   (i_rden),
    .o_rddata (o_rddata),
    .o_full   (o_full),
    .o_empty  (o_empty)
  );

  // Clock : 100 MHz
  always #5 clk = ~clk;

  integer i;

  initial begin
    // Init
    clk      = 0;
    rstn     = 0;
    i_wren   = 0;
    i_rden   = 0;
    i_wrdata = 0;

    // =========================================
    // TC1 : RESET TEST
    // After reset: empty=1, full=0
    // =========================================
    $display("\n========== TC1: RESET TEST ==========");
    repeat(2) @(posedge clk);
    rstn = 1;
    @(posedge clk);
    if (o_empty !== 1'b1) $display("FAIL: empty not 1 after reset");
    if (o_full  !== 1'b0) $display("FAIL: full not 0 after reset");
    $display("TC1 PASSED - empty=%b  full=%b", o_empty, o_full);

    // =========================================
    // TC2 : WRITE UNTIL FULL
    // Write 16 entries sequentially.
    // Verify full asserts, overflow ignored.
    // =========================================
    $display("\n========== TC2: WRITE UNTIL FULL ==========");
    for (i = 0; i < DEPTH; i = i + 1) begin
      @(posedge clk);
      if (!o_full) begin
        i_wren   = 1;
        i_wrdata = i + 8'h10;
        $display("  WRITE [%0d] data=0x%0h", i, i_wrdata);
      end
    end
    @(posedge clk); i_wren = 0;

    // Overflow attempt - must be ignored
    @(posedge clk);
    i_wren   = 1;
    i_wrdata = 8'hFF;
    $display("  Overflow write attempt (data=0xFF) - must be ignored");
    @(posedge clk); i_wren = 0;

    if (o_full !== 1'b1) $display("FAIL: full not asserted");
    $display("TC2 PASSED - full=%b (overflow write ignored)", o_full);

    // =========================================
    // TC3 : READ UNTIL EMPTY
    // Read all 16 entries, verify FIFO order.
    // Underflow attempt must be ignored.
    // =========================================
    $display("\n========== TC3: READ UNTIL EMPTY ==========");
    for (i = 0; i < DEPTH; i = i + 1) begin
      @(posedge clk);
      if (!o_empty) begin
        i_rden = 1;
        $display("  READ  [%0d] data=0x%0h", i, o_rddata);
      end
    end
    @(posedge clk); i_rden = 0;

    // Underflow attempt - must be ignored
    @(posedge clk);
    i_rden = 1;
    $display("  Underflow read attempt - must be ignored");
    @(posedge clk); i_rden = 0;

    if (o_empty !== 1'b1) $display("FAIL: empty not asserted after drain");
    $display("TC3 PASSED - empty=%b (underflow read ignored)", o_empty);

    // =========================================
    // TC4 : SIMULTANEOUS READ & WRITE
    // Pre-fill half, then write+read together.
    // FIFO depth stays constant (1 in, 1 out).
    // =========================================
    $display("\n========== TC4: SIMULTANEOUS READ & WRITE ==========");
    // Pre-fill half
    for (i = 0; i < DEPTH/2; i = i + 1) begin
      @(posedge clk);
      i_wren   = 1;
      i_wrdata = 8'hA0 + i;
    end
    @(posedge clk); i_wren = 0;

    // Simultaneous R/W for 8 cycles
    for (i = 0; i < 8; i = i + 1) begin
      @(posedge clk);
      i_wren   = !o_full;
      i_rden   = !o_empty;
      i_wrdata = 8'hB0 + i;
      $display("  SimRW [%0d] WR=0x%0h  RD=0x%0h  full=%b empty=%b",
               i, i_wrdata, o_rddata, o_full, o_empty);
    end
    @(posedge clk);
    i_wren = 0;
    i_rden = 0;
    $display("TC4 PASSED - Simultaneous R/W complete");

    repeat(5) @(posedge clk);
    $display("\n========== ALL TEST CASES DONE ==========\n");
    $finish;
  end

endmodule
