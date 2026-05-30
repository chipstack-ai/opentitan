// EdnEntropyRequestAndHandshake testbench for OpenTitan AES
// - Generates clocks/resets
// - Triggers AES PRNG reseed via TL-UL write to AES_TRIGGER
// - Handshakes EDN: waits for edn_o.edn_req, asserts edn_i.edn_ack and provides edn_i.edn_bus
// - Includes watchdog timeout to avoid long simulations

`timescale 1ns/1ps

module tb_aes_edn_handshake;
  import aes_pkg::*;
  import aes_reg_pkg::*;
  import tlul_pkg::*;
  import edn_pkg::*;
  import prim_alert_pkg::*;
  import lc_ctrl_pkg::*;
  import keymgr_pkg::*;

  // Clocks and resets
  logic clk_i;
  logic clk_edn_i;
  logic rst_ni;
  logic rst_shadowed_ni;
  logic rst_edn_ni;

  // DUT I/O
  prim_mubi_pkg::mubi4_t                     idle_o;
  lc_ctrl_pkg::lc_tx_t                       lc_escalate_en_i;
  edn_pkg::edn_req_t                         edn_o;
  edn_pkg::edn_rsp_t                         edn_i;
  keymgr_pkg::hw_key_req_t                   keymgr_key_i;
  tlul_pkg::tl_h2d_t                         tl_i;
  tlul_pkg::tl_d2h_t                         tl_o;
  prim_alert_pkg::alert_rx_t [aes_reg_pkg::NumAlerts-1:0] alert_rx_i;
  prim_alert_pkg::alert_tx_t [aes_reg_pkg::NumAlerts-1:0] alert_tx_o;

  // Clock generation: 100MHz nominal
  initial clk_i = 0;
  always #5 clk_i = ~clk_i; // 10ns period

  // EDN clock: same frequency, independent phase
  initial clk_edn_i = 0;
  always #5 clk_edn_i = ~clk_edn_i;

  // DUT instance
  aes dut (
    .clk_i,
    .rst_ni,
    .rst_shadowed_ni,
    .idle_o,
    .lc_escalate_en_i,
    .clk_edn_i,
    .rst_edn_ni,
    .edn_o,
    .edn_i,
    .keymgr_key_i,
    .tl_i,
    .tl_o,
    .alert_rx_i,
    .alert_tx_o
  );

  // Watchdog timeout
  localparam int unsigned WD_CYCLES = 200000; // 2ms at 100MHz
  int unsigned wd_cnt;
  initial begin
    wd_cnt = 0;
    forever begin
      @(posedge clk_i);
      wd_cnt++;
      if (wd_cnt == WD_CYCLES) begin
        $error("Watchdog timeout: test did not complete in %0d cycles", WD_CYCLES);
        $finish;
      end
    end
  end

  // Drive defaults and reset sequence
  initial begin
    // Defaults
    rst_ni = 1'b0;
    rst_shadowed_ni = 1'b0;
    rst_edn_ni = 1'b0;
    lc_escalate_en_i = lc_ctrl_pkg::LC_TX_DEFAULT; // Off
    keymgr_key_i = keymgr_pkg::HW_KEY_REQ_DEFAULT;
    edn_i = edn_pkg::EDN_RSP_DEFAULT; // edn_ack=0, edn_fips=0, edn_bus=0
    tl_i = tlul_pkg::TL_H2D_DEFAULT;  // d_ready=1 by default

    // Initialize alert RX lines to defaults
    for (int i = 0; i < aes_reg_pkg::NumAlerts; i++) begin
      alert_rx_i[i] = prim_alert_pkg::ALERT_RX_DEFAULT;
    end

    // Hold reset for some cycles
    repeat (10) @(posedge clk_i);
    rst_ni = 1'b1;
    rst_shadowed_ni = 1'b1;
    rst_edn_ni = 1'b1;

    // Wait a few cycles after reset for stabilization
    repeat (20) @(posedge clk_i);

    // Trigger PRNG reseed to cause EDN request
    tl_write32(aes_reg_pkg::AES_TRIGGER_OFFSET, 32'h0000_0008); // bit3: prng_reseed

    // Wait for EDN request and perform handshake
    edn_entropy_handshake();

    $display("EDN entropy handshake sequence completed. Test PASS.");
    #20; // small delay before finish
    $finish;
  end

  // Task: Perform EDN handshake when edn_o.edn_req asserts
  task automatic edn_entropy_handshake();
    bit saw_req;
    // Wait for request on EDN clock domain
    saw_req = 0;
    fork
      begin : wait_req
        // Wait with timeout to avoid hang
        int unsigned wait_cycles = 0;
        while (!saw_req && wait_cycles < WD_CYCLES/2) begin
          @(posedge clk_edn_i);
          if (edn_o.edn_req) saw_req = 1;
          wait_cycles++;
        end
        if (!saw_req) begin
          $error("Timeout waiting for edn_o.edn_req assertion");
          disable do_handshake;
        end
      end
    join_none

    // Once request observed, drive ack and bus data until request deasserts
    begin : do_handshake
      // Provide changing data pattern across cycles
      int unsigned cnt = 0;
      int unsigned ack_cycles = 0;
      int unsigned ack_cycles_max = 5000; // bound EDN handshake service window
      // Wait until request is seen
      wait (saw_req);
      // Provide entropy and ack for several cycles or until req drops
      edn_i.edn_ack = 1'b1;
      edn_i.edn_fips = 1'b0;
      while (edn_o.edn_req && (ack_cycles < ack_cycles_max)) begin
        @(posedge clk_edn_i);
        edn_i.edn_bus = edn_pkg::ENDPOINT_BUS_WIDTH'(32'hA5A50000 | cnt[15:0]);
        cnt++;
        ack_cycles++;
      end
      if (edn_o.edn_req) begin
        $error("EDN request did not deassert within %0d EDN cycles", ack_cycles_max);
      end
      // Drop ack after request deasserts
      @(posedge clk_edn_i);
      edn_i.edn_ack = 1'b0;
    end
  endtask

  // Simple TL-UL 32-bit write (PutFullData)
  task automatic tl_write32(input logic [aes_reg_pkg::BlockAw-1:0] addr,
                            input logic [31:0] data);
    // Prepare request
    tlul_pkg::tl_h2d_t req;
    req = tlul_pkg::TL_H2D_DEFAULT;
    req.a_valid   = 1'b1;
    req.a_opcode  = tlul_pkg::PutFullData;
    req.a_param   = '0;
    req.a_size    = top_pkg::TL_SZW'(2); // 4 bytes
    req.a_source  = '0;
    req.a_address = top_pkg::TL_AW'(addr);
    req.a_mask    = {top_pkg::TL_DBW{1'b1}}; // full mask
    req.a_data    = data;
    req.a_user    = tlul_pkg::TL_A_USER_DEFAULT;
    // Compute integrity fields
    req.a_user.data_intg = tlul_pkg::get_data_intg(req.a_data);
    req.a_user.cmd_intg  = tlul_pkg::get_cmd_intg(req);

    // Drive request until accepted
    do begin
      @(posedge clk_i);
      tl_i <= req;
    end while (!tl_o.a_ready);

    // Deassert a_valid on next cycle
    @(posedge clk_i);
    req.a_valid = 1'b0;
    tl_i <= req;

    // Wait for response
    wait (tl_o.d_valid);
    // Basic checks: AccessAck, no error
    if (tl_o.d_opcode !== tlul_pkg::AccessAck || tl_o.d_error !== 1'b0) begin
      $error("TL-UL write unexpected response: d_opcode=%0d d_error=%0b", tl_o.d_opcode, tl_o.d_error);
    end
    // One more cycle to settle
    @(posedge clk_i);
  endtask

endmodule
