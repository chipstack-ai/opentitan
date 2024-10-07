// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// FPV CSR read and write assertions auto-generated by `reggen` containing data structure
// Do Not Edit directly
// TODO: This automation currently only support register without HW write access

`include "prim_assert.sv"

`ifndef FPV_ON
  `define REGWEN_PATH tb.dut.u_reg
`else
  `define REGWEN_PATH aon_timer.u_reg
`endif

// Block: aon_timer
module aon_timer_csr_assert_fpv import tlul_pkg::*;
    import top_pkg::*;(
  input clk_i,
  input rst_ni,

  // tile link ports
  input tl_h2d_t h2d,
  input tl_d2h_t d2h
);

`ifdef UVM
  import uvm_pkg::*;
`endif

// Currently FPV csr assertion only support HRO registers.
`ifndef VERILATOR
`ifndef SYNTHESIS

  logic oob_addr_err;

  typedef struct packed {
    logic [TL_DW-1:0] wr_data;
    logic [TL_AW-1:0] addr;
    logic             wr_pending;
    logic             rd_pending;
  } pend_item_t;

  bit disable_sva;

  // mask register to convert byte to bit
  logic [TL_DW-1:0] a_mask_bit;

  assign a_mask_bit[7:0]   = h2d.a_mask[0] ? '1 : '0;
  assign a_mask_bit[15:8]  = h2d.a_mask[1] ? '1 : '0;
  assign a_mask_bit[23:16] = h2d.a_mask[2] ? '1 : '0;
  assign a_mask_bit[31:24] = h2d.a_mask[3] ? '1 : '0;

  // An index used for regwen, access_policy and exp_vals. These arrays all have one element per HRO
  // register, plus an extra dummy entry to represent "non-HRO registers" (avoiding out-of-bounds
  // accesses).
  bit [3:0] hro_idx;
  bit [5:0] normalized_addr;

  `ifdef FPV_ON
    // For FPV, we restrict the pend_trans array by giving its size a smaller upper bound. This
    // reduces the FPV runtime dramatically.
    localparam int PendTransLen = 11;

    // These two assumptions bound h2d.a_source and d2h.d_source for FPV because they are used as
    // indices for the array.
    `ASSUME_FPV(TlulSourceA_M, h2d.a_source >=  0 && h2d.a_source < PendTransLen, clk_i, !rst_ni)
    `ASSUME_FPV(TlulSourceD_M, d2h.d_source >=  0 && d2h.d_source < PendTransLen, clk_i, !rst_ni)
  `else
    localparam int PendTransLen = 2**TL_AIW;
  `endif

  pend_item_t [PendTransLen-1:0] pend_trans;

  // Indexes of pend_trans have a width that depends on the size of the array. These lines extract
  // just the bottom bits (so that the widths match).
  //
  // When in FPV mode, the TlulSource*_M assumptions above ensure that we aren't dropping any
  // nonzero bits. When not in FPV mode, this is a no-op: the a_source and d_source values are of
  // width TL_AIW and we extract that many bits.
  localparam int PendTransIdxWidth = $clog2(PendTransLen);
  logic [PendTransIdxWidth-1:0] a_source_idx, d_source_idx;

  assign a_source_idx = h2d.a_source[PendTransIdxWidth-1:0];
  assign d_source_idx = d2h.d_source[PendTransIdxWidth-1:0];

  // Map register address with hro_idx in exp_vals array.
  always_comb begin: decode_hro_addr_to_idx
    unique case (pend_trans[d_source_idx].addr)
      0: hro_idx <= 0;
      4: hro_idx <= 1;
      8: hro_idx <= 2;
      12: hro_idx <= 3;
      24: hro_idx <= 4;
      28: hro_idx <= 5;
      32: hro_idx <= 6;
      36: hro_idx <= 7;
      48: hro_idx <= 8;
      // If the register is not a HRO register, the write data will all update to this default idx.
      default: hro_idx <= 9;
    endcase
  end

  // store internal expected values for HW ReadOnly registers
  logic [TL_DW-1:0] exp_vals[10];

  // Word-align the incoming TLUL a_address to obtain the normalized address.
  assign normalized_addr = {h2d.a_address[5:2], 2'b0};

  // Assign regwen to registers. If the register does not have regwen, it will default to value 1.
  logic [9:0] regwen;
  assign regwen[0] = 1;
  assign regwen[1] = 1;
  assign regwen[2] = 1;
  assign regwen[3] = 1;
  assign regwen[4] = 1;
  assign regwen[5] = `REGWEN_PATH.wdog_regwen_qs;
  assign regwen[6] = `REGWEN_PATH.wdog_regwen_qs;
  assign regwen[7] = `REGWEN_PATH.wdog_regwen_qs;
  assign regwen[8] = 1;
  assign regwen[9] = 1;

  typedef enum bit {
    FpvDefault,
    FpvRw0c
  } fpv_reg_access_e;
  fpv_reg_access_e access_policy [10];

  // for write HRO registers, store the write data into exp_vals
  always_ff @(negedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
       oob_addr_err <= 1'b0;
       pend_trans <= '0;
       exp_vals[0] <= 'h0;
       access_policy[0] <= FpvDefault;
       exp_vals[1] <= 'h0;
       access_policy[1] <= FpvDefault;
       exp_vals[2] <= 'h0;
       access_policy[2] <= FpvDefault;
       exp_vals[3] <= 'h0;
       access_policy[3] <= FpvDefault;
       exp_vals[4] <= 'h1;
       access_policy[4] <= FpvRw0c;
       exp_vals[5] <= 'h0;
       access_policy[5] <= FpvDefault;
       exp_vals[6] <= 'h0;
       access_policy[6] <= FpvDefault;
       exp_vals[7] <= 'h0;
       access_policy[7] <= FpvDefault;
       exp_vals[8] <= 'h0;
       access_policy[8] <= FpvDefault;
       exp_vals[9] <= 'h0;
       access_policy[9] <= FpvDefault;
    end else begin
      oob_addr_err <= 1'b0;
      if (h2d.a_valid && d2h.a_ready) begin
        if ((normalized_addr inside {[0:52]})
           ) begin
          pend_trans[a_source_idx].addr <= normalized_addr;
          if (h2d.a_opcode inside {PutFullData, PutPartialData}) begin
            pend_trans[a_source_idx].wr_data <= h2d.a_data & a_mask_bit;
            pend_trans[a_source_idx].wr_pending <= 1'b1;
          end else if (h2d.a_opcode == Get) begin
            pend_trans[a_source_idx].rd_pending <= 1'b1;
          end
        end else begin
          oob_addr_err <= 1'b1;
        end
      end
      if (d2h.d_valid) begin
        if (pend_trans[d_source_idx].wr_pending == 1) begin
          if (!d2h.d_error && regwen[hro_idx]) begin
            if (access_policy[hro_idx] == FpvRw0c) begin
              // Assume FpvWr0c policy only has one field that is wr0c.
              exp_vals[hro_idx] <= exp_vals[hro_idx][0] == 0 ? 0 : pend_trans[d_source_idx].wr_data;
            end else begin
              exp_vals[hro_idx] <= pend_trans[d_source_idx].wr_data;
            end
          end
          pend_trans[d_source_idx].wr_pending <= 1'b0;
        end
        if (h2d.d_ready && pend_trans[d_source_idx].rd_pending == 1) begin
          pend_trans[d_source_idx].rd_pending <= 1'b0;
        end
      end
    end
  end

  // for read HRO registers, assert read out values by access policy and exp_vals
  `ASSERT(wkup_ctrl_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 6'h4 |->
         d2h.d_error ||
         (d2h.d_data & 'h1fff) == (exp_vals[1] & 'h1fff))

  `ASSERT(wkup_thold_hi_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 6'h8 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[2] & 'hffffffff))

  `ASSERT(wkup_thold_lo_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 6'hc |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[3] & 'hffffffff))

  `ASSERT(wdog_regwen_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 6'h18 |->
         d2h.d_error ||
         (d2h.d_data & 'h1) == (exp_vals[4] & 'h1))

  `ASSERT(wdog_ctrl_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 6'h1c |->
         d2h.d_error ||
         (d2h.d_data & 'h3) == (exp_vals[5] & 'h3))

  `ASSERT(wdog_bark_thold_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 6'h20 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[6] & 'hffffffff))

  `ASSERT(wdog_bite_thold_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 6'h24 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[7] & 'hffffffff))


  `ASSERT(TlulOOBAddrErr_A, oob_addr_err |-> s_eventually(d2h.d_valid && d2h.d_error))

  `ifdef UVM
    initial forever begin
      bit csr_assert_en;
      uvm_config_db#(bit)::wait_modified(null, "%m", "csr_assert_en");
      if (!uvm_config_db#(bit)::get(null, "%m", "csr_assert_en", csr_assert_en)) begin
        `uvm_fatal("csr_assert", "Can't find csr_assert_en")
      end
      disable_sva = !csr_assert_en;
    end
  `endif

`endif
`endif
endmodule

`undef REGWEN_PATH

