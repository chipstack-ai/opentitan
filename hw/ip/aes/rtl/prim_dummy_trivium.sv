// Lightweight, simulation-friendly replacement for prim_trivium/prim_bivium
// Provides the same interface, avoiding complex constructs that some parsers flag as errors.

`include "prim_assert.sv"

module prim_trivium import prim_trivium_pkg::*;
#(
  parameter bit          BiviumVariant = 0,
  parameter int unsigned OutputWidth = 64,
  parameter bit          StrictLockupProtection = 1,
  parameter seed_type_e  SeedType = SeedTypeStateFull,
  parameter int unsigned PartialSeedWidth = PartialSeedWidthDefault,
  localparam int unsigned StateWidth = BiviumVariant ? BiviumStateWidth : TriviumStateWidth,
  parameter trivium_lfsr_seed_t RndCnstTriviumLfsrSeed = RndCnstTriviumLfsrSeedDefault,
  localparam logic [StateWidth-1:0] StateSeed = RndCnstTriviumLfsrSeed[StateWidth-1:0]
) (
  input  logic                        clk_i,
  input  logic                        rst_ni,
  input  logic                        en_i,
  input  logic                        allow_lockup_i,
  input  logic                        seed_en_i,
  output logic                        seed_done_o,
  output logic                        seed_req_o,
  input  logic                        seed_ack_i,
  input  logic [KeyIvWidth-1:0]       seed_key_i,
  input  logic [KeyIvWidth-1:0]       seed_iv_i,
  input  logic [StateWidth-1:0]       seed_state_full_i,
  input  logic [PartialSeedWidth-1:0] seed_state_partial_i,
  output logic [OutputWidth-1:0]      key_o,
  output logic                        err_o
);
  logic [StateWidth-1:0] state_q, state_d;
  logic [StateWidth-1:0] seed_concat;
  assign seed_concat = (SeedType == SeedTypeKeyIv) ? {seed_key_i, seed_iv_i, {(StateWidth-2*KeyIvWidth){1'b0}}} :
                       (SeedType == SeedTypeStateFull) ? seed_state_full_i :
                       {{(StateWidth-PartialSeedWidth){1'b0}}, seed_state_partial_i};

  // Simple LFSR-like update
  always_comb begin
    state_d = state_q;
    if (en_i) begin
      state_d = {state_q[StateWidth-2:0], state_q[StateWidth-1] ^ state_q[2] ^ state_q[5] ^ state_q[7]};
    end
    key_o = state_q[OutputWidth-1:0];
  end

  // Seed handshake: request when seed_en_i, accept when acked and load provided seed.
  assign seed_req_o  = seed_en_i;
  assign seed_done_o = seed_en_i & seed_ack_i;

  // Lockup not modeled; never error in this stub.
  assign err_o = 1'b0;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= StateSeed;
    end else begin
      if (seed_en_i && seed_ack_i) begin
        state_q <= seed_concat ^ StateSeed;
      end else begin
        state_q <= state_d;
      end
    end
  end
endmodule

