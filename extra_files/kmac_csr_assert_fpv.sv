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
  `define REGWEN_PATH kmac.u_reg
`endif

// Block: kmac
module kmac_csr_assert_fpv import tlul_pkg::*;
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
  bit [5:0] hro_idx;
  bit [11:0] normalized_addr;

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
      4: hro_idx <= 0;
      8: hro_idx <= 1;
      12: hro_idx <= 2;
      24: hro_idx <= 3;
      32: hro_idx <= 4;
      44: hro_idx <= 5;
      48: hro_idx <= 6;
      52: hro_idx <= 7;
      56: hro_idx <= 8;
      60: hro_idx <= 9;
      64: hro_idx <= 10;
      68: hro_idx <= 11;
      72: hro_idx <= 12;
      76: hro_idx <= 13;
      80: hro_idx <= 14;
      84: hro_idx <= 15;
      88: hro_idx <= 16;
      92: hro_idx <= 17;
      96: hro_idx <= 18;
      100: hro_idx <= 19;
      104: hro_idx <= 20;
      108: hro_idx <= 21;
      112: hro_idx <= 22;
      116: hro_idx <= 23;
      120: hro_idx <= 24;
      124: hro_idx <= 25;
      128: hro_idx <= 26;
      132: hro_idx <= 27;
      136: hro_idx <= 28;
      140: hro_idx <= 29;
      144: hro_idx <= 30;
      148: hro_idx <= 31;
      152: hro_idx <= 32;
      156: hro_idx <= 33;
      160: hro_idx <= 34;
      164: hro_idx <= 35;
      168: hro_idx <= 36;
      172: hro_idx <= 37;
      176: hro_idx <= 38;
      180: hro_idx <= 39;
      184: hro_idx <= 40;
      188: hro_idx <= 41;
      192: hro_idx <= 42;
      196: hro_idx <= 43;
      200: hro_idx <= 44;
      204: hro_idx <= 45;
      208: hro_idx <= 46;
      212: hro_idx <= 47;
      216: hro_idx <= 48;
      220: hro_idx <= 49;
      // If the register is not a HRO register, the write data will all update to this default idx.
      default: hro_idx <= 50;
    endcase
  end

  // store internal expected values for HW ReadOnly registers
  logic [TL_DW-1:0] exp_vals[51];

  // Word-align the incoming TLUL a_address to obtain the normalized address.
  assign normalized_addr = {h2d.a_address[11:2], 2'b0};

  // Assign regwen to registers. If the register does not have regwen, it will default to value 1.
  logic [50:0] regwen;
  assign regwen[0] = 1;
  assign regwen[1] = 1;
  assign regwen[2] = 1;
  assign regwen[3] = 1;
  assign regwen[4] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[5] = 1;
  assign regwen[6] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[7] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[8] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[9] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[10] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[11] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[12] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[13] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[14] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[15] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[16] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[17] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[18] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[19] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[20] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[21] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[22] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[23] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[24] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[25] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[26] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[27] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[28] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[29] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[30] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[31] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[32] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[33] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[34] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[35] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[36] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[37] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[38] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[39] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[40] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[41] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[42] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[43] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[44] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[45] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[46] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[47] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[48] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[49] = `REGWEN_PATH.cfg_regwen_qs;
  assign regwen[50] = 1;

  typedef enum bit {
    FpvDefault,
    FpvRw0c
  } fpv_reg_access_e;
  fpv_reg_access_e access_policy [51];

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
       exp_vals[4] <= 'h0;
       access_policy[4] <= FpvDefault;
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
       exp_vals[10] <= 'h0;
       access_policy[10] <= FpvDefault;
       exp_vals[11] <= 'h0;
       access_policy[11] <= FpvDefault;
       exp_vals[12] <= 'h0;
       access_policy[12] <= FpvDefault;
       exp_vals[13] <= 'h0;
       access_policy[13] <= FpvDefault;
       exp_vals[14] <= 'h0;
       access_policy[14] <= FpvDefault;
       exp_vals[15] <= 'h0;
       access_policy[15] <= FpvDefault;
       exp_vals[16] <= 'h0;
       access_policy[16] <= FpvDefault;
       exp_vals[17] <= 'h0;
       access_policy[17] <= FpvDefault;
       exp_vals[18] <= 'h0;
       access_policy[18] <= FpvDefault;
       exp_vals[19] <= 'h0;
       access_policy[19] <= FpvDefault;
       exp_vals[20] <= 'h0;
       access_policy[20] <= FpvDefault;
       exp_vals[21] <= 'h0;
       access_policy[21] <= FpvDefault;
       exp_vals[22] <= 'h0;
       access_policy[22] <= FpvDefault;
       exp_vals[23] <= 'h0;
       access_policy[23] <= FpvDefault;
       exp_vals[24] <= 'h0;
       access_policy[24] <= FpvDefault;
       exp_vals[25] <= 'h0;
       access_policy[25] <= FpvDefault;
       exp_vals[26] <= 'h0;
       access_policy[26] <= FpvDefault;
       exp_vals[27] <= 'h0;
       access_policy[27] <= FpvDefault;
       exp_vals[28] <= 'h0;
       access_policy[28] <= FpvDefault;
       exp_vals[29] <= 'h0;
       access_policy[29] <= FpvDefault;
       exp_vals[30] <= 'h0;
       access_policy[30] <= FpvDefault;
       exp_vals[31] <= 'h0;
       access_policy[31] <= FpvDefault;
       exp_vals[32] <= 'h0;
       access_policy[32] <= FpvDefault;
       exp_vals[33] <= 'h0;
       access_policy[33] <= FpvDefault;
       exp_vals[34] <= 'h0;
       access_policy[34] <= FpvDefault;
       exp_vals[35] <= 'h0;
       access_policy[35] <= FpvDefault;
       exp_vals[36] <= 'h0;
       access_policy[36] <= FpvDefault;
       exp_vals[37] <= 'h0;
       access_policy[37] <= FpvDefault;
       exp_vals[38] <= 'h0;
       access_policy[38] <= FpvDefault;
       exp_vals[39] <= 'h0;
       access_policy[39] <= FpvDefault;
       exp_vals[40] <= 'h0;
       access_policy[40] <= FpvDefault;
       exp_vals[41] <= 'h0;
       access_policy[41] <= FpvDefault;
       exp_vals[42] <= 'h0;
       access_policy[42] <= FpvDefault;
       exp_vals[43] <= 'h0;
       access_policy[43] <= FpvDefault;
       exp_vals[44] <= 'h0;
       access_policy[44] <= FpvDefault;
       exp_vals[45] <= 'h0;
       access_policy[45] <= FpvDefault;
       exp_vals[46] <= 'h0;
       access_policy[46] <= FpvDefault;
       exp_vals[47] <= 'h0;
       access_policy[47] <= FpvDefault;
       exp_vals[48] <= 'h0;
       access_policy[48] <= FpvDefault;
       exp_vals[49] <= 'h0;
       access_policy[49] <= FpvDefault;
       exp_vals[50] <= 'h0;
       access_policy[50] <= FpvDefault;
    end else begin
      oob_addr_err <= 1'b0;
      if (h2d.a_valid && d2h.a_ready) begin
        if ((normalized_addr inside {[0:224]})
            || (normalized_addr inside {[1024: (1024+128*8)]})
            || (normalized_addr inside {[2048: (2048+512*8)]})
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
  `ASSERT(intr_enable_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'h4 |->
         d2h.d_error ||
         (d2h.d_data & 'h7) == (exp_vals[0] & 'h7))

  `ASSERT(entropy_period_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'h20 |->
         d2h.d_error ||
         (d2h.d_data & 'hffff03ff) == (exp_vals[4] & 'hffff03ff))

  `ASSERT(prefix_0_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hb4 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[39] & 'hffffffff))

  `ASSERT(prefix_1_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hb8 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[40] & 'hffffffff))

  `ASSERT(prefix_2_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hbc |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[41] & 'hffffffff))

  `ASSERT(prefix_3_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hc0 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[42] & 'hffffffff))

  `ASSERT(prefix_4_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hc4 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[43] & 'hffffffff))

  `ASSERT(prefix_5_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hc8 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[44] & 'hffffffff))

  `ASSERT(prefix_6_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hcc |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[45] & 'hffffffff))

  `ASSERT(prefix_7_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hd0 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[46] & 'hffffffff))

  `ASSERT(prefix_8_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hd4 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[47] & 'hffffffff))

  `ASSERT(prefix_9_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hd8 |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[48] & 'hffffffff))

  `ASSERT(prefix_10_rd_A, d2h.d_valid && pend_trans[d_source_idx].rd_pending &&
         pend_trans[d_source_idx].addr == 12'hdc |->
         d2h.d_error ||
         (d2h.d_data & 'hffffffff) == (exp_vals[49] & 'hffffffff))


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

