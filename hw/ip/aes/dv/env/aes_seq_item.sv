// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0


class aes_seq_item extends uvm_sequence_item;
  `uvm_object_utils(aes_seq_item)

  aes_item_type_e  item_type;
  bit [1:0] operation;

  ///////////////////////////////////////
  //  Control Knobs                    //
  ///////////////////////////////////////

  // set if this item contains valid information
  bit             valid                = 0;
  // 0: auto mode 1: manual start
  bit             manual_op;
  // 0: output data cannot be overwritten

  // lenth of plaintext / cypher (max is 128b/16b per block)
  // used to mask bits that are not part of the data vector
  bit [3:0]       data_len            = 0;
  // key len 0: 128, 1: 192, 2: 256 3: NOT VALID
  bit [2:0]       key_len;
  // 256 bit key (8x32 bit) in two shares, key = share0 ^ share1
  bit [7:0][31:0] key [2];
  // which fields of the key is valid
  bit [7:0]       key_vld [2]          = '{8'b0, 8'b0};
  // randomized data to add to queue
  bit [3:0][31:0] iv;
  // indicate if the initialization vector is valid
  bit [3:0]       iv_vld;
  aes_mode_e      mode;
  bit [2:0]       reseed_rate;

  // Optional randomization enables (kept off by default for compatibility)
  bit             randomize_operation_en = 0;
  bit             randomize_key_len_en   = 0;
  bit             randomize_data_len_en  = 0;

  bit             en_b2b_transactions  = 1;
  int             b2b_pct              = 80;

  // percentage of items that will// clear one or more registers
  int             clear_reg_pct = 0;

  // clear registers with random data
  bit             clear_reg_w_rand = 0;

  ///////////////////////////////////////
  // Fixed variables                   //
  ///////////////////////////////////////

  // indicate which words has data
  bit [3:0]       data_in_vld         = 4'b0;
  // indicate which words has data
  bit [3:0]       data_out_vld        = 4'b0;
  // data out was cleared and will not match output from DUT
  bit             data_was_cleared    = 0;


  // used by the checker
  bit [3:0][31:0] data_out            ='0;
  // set if data should be fixed and not randomized
  bit             fixed_data          = 0;
  // if set unused key bytes will be forced to 0 - controlled from test
  bit             key_mask            = 1;

  // indicate message start  in manual mode
  bit             start_item       = 0;
  // indicate a message was split in two with this item.
  bit             split_item       = 0;
  // use sideload
  bit                          sideload_en;


  ///////////////////////////////////////
  // Randomizable variables            //
  ///////////////////////////////////////

  // used by the checker
  rand  bit [3:0][31:0]             data_in;

  // Optional randomized selectors for additional coverage
  rand  bit [1:0]                   operation_rand;
  rand  bit [2:0]                   key_len_rand;
  rand  bit [3:0]                   data_len_rand;
  rand  int unsigned                data_pattern_sel;
  rand  int unsigned                iv_pattern_sel;

  // back to back
  rand bit                          do_b2b;

  // bit to select if we clear 1 or more regs
  rand int                          clr_reg_dist_select;

  // this is only used to program dut in illegal mode
  rand bit [$bits(aes_mode_e) -1:0] aes_mode;

  // clear reg vector
  // [3] output data
  // [2] input data
  // [1] IV
  // [0] key
  rand clear_t                      clear_reg;

  // Additional constraints to improve coverage (gated by enable knobs)
  // Randomize operation with equal ENC/DEC distribution when enabled
  constraint operation_rand_c {
    if (randomize_operation_en) {
      operation_rand dist { AES_ENC :/ 50,
                            AES_DEC :/ 50 };
    }
  }

  // Randomize key length across 128/192/256 when enabled
  constraint key_len_rand_c {
    if (randomize_key_len_en) {
      key_len_rand dist { 3'b001 :/ 33,
                          3'b010 :/ 33,
                          3'b100 :/ 34 };
    }
  }

  // Randomize data length with bias to edge cases when enabled
  constraint data_len_rand_c {
    if (randomize_data_len_en) {
      data_len_rand dist { 4'd0  :/ 3,   // full block
                           4'd1  :/ 3,   // single byte
                           4'd15 :/ 3,   // all but one byte
                           [4'd2:4'd14] :/ 7 };
    }
  }

  // Select corner-case patterns occasionally for data and IV
  constraint data_pattern_sel_c { data_pattern_sel dist { 0 :/ 5,  // all zeros
                                                          1 :/ 5,  // all ones
                                                          2 :/ 5,  // 0xAA/0x55
                                                          3 :/ 5,  // ascending bytes
                                                          4 :/ 80  // fully random
                                                        };}
  constraint iv_pattern_sel_c   { iv_pattern_sel   dist { 0 :/ 5,
                                                          1 :/ 5,
                                                          2 :/ 5,
                                                          3 :/ 5,
                                                          4 :/ 80
                                                        };}

  constraint aes_mode_c {
   // force to be !onehot
    if (mode == AES_NONE) {
      !($countones(aes_mode) == 1);
    } else {
      aes_mode == mode;
    }
  }

  constraint aes_clear_reg_c {
    solve clr_reg_dist_select before clear_reg;
    clr_reg_dist_select dist { 0     :/ (100 - clear_reg_pct),
                               [1:2] :/ clear_reg_pct
                             };

    clr_reg_dist_select == 0 ->            clear_reg == 0;
    clr_reg_dist_select == 1 ->            $countones(clear_reg) > 1;
    clr_reg_dist_select == 2 -> clear_reg dist {     1  :/ clear_reg_pct/2,
                                                     2  :/ clear_reg_pct/2
                                                };

  }

  constraint back2back_c {
    if (en_b2b_transactions) {
      do_b2b dist { 0 :/ (100-b2b_pct),
                    1 :/ b2b_pct };
    } else {
      do_b2b == 0;
    };
  }


  function new( string name="aes_sequence_item");
    super.new(name);
  endfunction


  function void post_randomize();
    bit [3:0]           index;
    bit [127:0]         tmp_data;
    `uvm_info(`gfn, $sformatf("Key Mask %b", key_mask), UVM_LOW)

    // Optionally apply randomized knobs to main fields
    if (randomize_operation_en) operation = operation_rand;
    if (randomize_key_len_en)   key_len   = key_len_rand;
    if (randomize_data_len_en)  data_len  = data_len_rand;

    // Apply corner-case patterns to data_in while keeping random as default
    unique case (data_pattern_sel)
      0: begin
        data_in = '0;
      end
      1: begin
        data_in = '1;
      end
      2: begin
        // Alternate 0xAA / 0x55 across words
        for (int i = 0; i < 4; i++) begin
          data_in[i] = (i % 2 == 0) ? 32'hAAAA_AAAA : 32'h5555_5555;
        end
      end
      3: begin
        // Ascending byte values across 128b
        for (int i = 0; i < 16; i++) begin
          data_in[i[3:2]][i[1:0]*8 +: 8] = 8'(i);
        end
      end
      default: begin
        // leave randomized value as-is
      end
    endcase

    // Apply corner-case patterns to IV with same selector scheme
    unique case (iv_pattern_sel)
      0: begin
        iv = '{default: 32'h0};
      end
      1: begin
        iv = '{default: 32'hFFFF_FFFF};
      end
      2: begin
        for (int i = 0; i < 4; i++) begin
          iv[i] = (i % 2 == 0) ? 32'hAAAA_AAAA : 32'h5555_5555;
        end
      end
      3: begin
        for (int i = 0; i < 16; i++) begin
          iv[i[3:2]][i[1:0]*8 +: 8] = 8'(i);
        end
      end
      default: begin
        // leave as-is
      end
    endcase
    if (key_mask) begin
      case (key_len)
        3'b001: begin
          key[0][7:4] = 32'h00000000;
          key[1][7:4] = 32'h00000000;
        end
        3'b010: begin
          key[0][7:6] = 32'h00000000;
          key[1][7:6] = 32'h00000000;
        end
        default: begin
        end
      endcase // case (key_len)
    end


    // mask unused data bits
    if (data_len != 0) begin
      for (int i=data_len; i<16; i++) begin
        data_in[i[3:2]][i[1:0]*8+7 -:8] = 8'd0;
      end
    end
  endfunction // post_randomize

  // function to detect if all datafields
  // have been updated.
  function bit data_in_valid();
    `uvm_info(`gfn, $sformatf("\n\t ----| Checking if ALL data is updated %4b", data_in_vld)
              , UVM_FULL)

    return &data_in_vld;
  endfunction // data_in_valid

  // function to detect if all datafields
  // have been updated.
  function bit data_out_valid();
    `uvm_info(`gfn, $sformatf("\n\t ----| Checking if ALL data is valid  %4b", data_out_vld)
      , UVM_FULL)

    return &data_out_vld;
  endfunction // data_in_valid

  // if ret_clean = 0
  // return 1 only of all registers have been written
  // if ret_clean = 1
  // return 1 if all or none of the registers have been written
  // if clear is set the register will be reset
  function bit key_clean(bit ret_clean, bit clear);
    `uvm_info(`gfn, $sformatf("\n\t ----| Key status %b %b", key_vld[0], key_vld[1]), UVM_MEDIUM)
    if (clear) begin
      if (clear_reg_w_rand) begin
        key = '{default: {8{$urandom()}}};
      end else begin
        key = '{default: '0};
      end
      key_vld[0] = '0;
      key_vld[1] = '0;
    end

    if (ret_clean) begin
      return ((&key_vld[0] && &key_vld[1]) || ~(|key_vld[0] || |key_vld[1]));
    end else begin
      return (&key_vld[0] && &key_vld[1]);
    end
  endfunction // key_clean

  // if ret_clean = 0
  // return 1 only of all registers have been written
  // if ret_celan = 1
  // return 1 if all or none of the registers have been written
  function bit iv_clean(bit ret_clean, bit clear);
    `uvm_info(`gfn, $sformatf("\n\t ----| IV status %b ", iv_vld), UVM_MEDIUM)
    if (clear) begin
      if (clear_reg_w_rand) begin
        iv = {4{$urandom()}};
      end else begin
        iv = '0;
      end
        iv_vld = '0;
    end

    if (ret_clean) begin
      return  ((&iv_vld) || ~(|iv_vld));
    end else begin
      return &iv_vld;
    end
  endfunction

  // bases on the AES mode
  // function will return 1 if this is the start of a new message
  function bit message_start();
    case(mode)
      AES_ECB: begin
        `uvm_info(`gfn, $sformatf("return key vld(%b, %b) %b",
                   key_vld[0], key_vld[1], &key_vld[0] && &key_vld[1]), UVM_MEDIUM)
        return (&key_vld[0] && &key_vld[1]);
      end
      AES_CBC: begin
        `uvm_info(`gfn, $sformatf("return key vld(%b, %b) %b AND iv (%b) &%b",
                   key_vld[0], key_vld[1], (&key_vld[0] && &key_vld[1]), iv_vld, &iv_vld), UVM_MEDIUM)
        return ((&key_vld[0] && &key_vld[1]) && &iv_vld);
      end
      AES_CFB: begin
        `uvm_info(`gfn, $sformatf("return key vld(%b, %b) %b AND iv (%b) &%b a",
                   key_vld[0], key_vld[1], (&key_vld[0] && &key_vld[1]), iv_vld, &iv_vld), UVM_MEDIUM)
        return ((&key_vld[0] && &key_vld[1]) && &iv_vld);
      end
      AES_OFB: begin
        `uvm_info(`gfn, $sformatf("return key vld(%b, %b) %b AND iv (%b) &%b",
                   key_vld[0], key_vld[1], (&key_vld[0] && &key_vld[1]), iv_vld, &iv_vld), UVM_MEDIUM)
        return ((&key_vld[0] && &key_vld[1]) && &iv_vld);
      end
      AES_CTR: begin
        `uvm_info(`gfn, $sformatf("return key vld(%b, %b) %b AND iv (%b) &%b",
                   key_vld[0], key_vld[1], (&key_vld[0] && &key_vld[1]), iv_vld, &iv_vld), UVM_MEDIUM)
        return ((&key_vld[0] && &key_vld[1]) && &iv_vld);
      end
      default: begin
        // only happen in illegal cases so always return "not start"
        return 0;
      end
    endcase // case (mode)
  endfunction // message_start

  function void clean_data_in();
    if (clear_reg_w_rand) begin
      data_in = {4{$urandom()}};
    end else begin
      data_in = '0;
    end
    data_in_vld = '0;
  endfunction // clean_data_in


  function void clean();
    data_in_vld  = '0;
    iv_vld       = '0;
    key_vld      = '{default: '0};
    data_out_vld = '0;
    start_item   =  0;
  endfunction // clean


  virtual function void do_copy(uvm_object rhs);
    aes_seq_item rhs_;

    `downcast(rhs_,rhs)
    super.do_copy(rhs);
    item_type        = rhs_.item_type;
    operation        = rhs_.operation;
    mode             = rhs_.mode;
    data_in          = rhs_.data_in;
    data_in_vld      = rhs_.data_in_vld;
    key              = rhs_.key;
    key_len          = rhs_.key_len;
    key_vld          = rhs_.key_vld;
    iv               = rhs_.iv;
    iv_vld           = rhs_.iv_vld;
    data_out         = rhs_.data_out;
    data_len         = rhs_.data_len;
    manual_op        = rhs_.manual_op;
    clear_reg_w_rand = rhs_.clear_reg_w_rand;
    key_mask         = rhs_.key_mask;
    aes_mode         = rhs_.aes_mode;
    do_b2b           = rhs_.do_b2b;
    clear_reg        = rhs_.clear_reg;
    start_item       = rhs_.start_item;
    split_item       = rhs_.split_item;
    data_was_cleared = rhs_.data_was_cleared;
    sideload_en      = rhs_.sideload_en;
    reseed_rate      = rhs_.reseed_rate;
    // Copy optional randomization enable knobs to preserve behavior
    randomize_operation_en = rhs_.randomize_operation_en;
    randomize_key_len_en   = rhs_.randomize_key_len_en;
    randomize_data_len_en  = rhs_.randomize_data_len_en;
  endfunction // copy


  // do compare //
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);

    aes_seq_item rhs_;

    `downcast(rhs_,rhs)
    return(super.do_compare(rhs,comparer) &&
           (operation == rhs_.operation) &&
           (mode      == rhs_.mode) &&
           (data_in   == rhs_.data_in) &&
           (key       == rhs_.key) &&
           (data_out  == rhs_.data_out) );
  endfunction // compare


  // convert to string //
  virtual function string convert2string();
    string str;
    str = super.convert2string();
    str = {str,  $psprintf("\n\t ----| AES SEQUENCE ITEM                                  |----\t ")
           };
    str = {str,  $psprintf("\n\t ----| Item Type:    \t %s                          |----\t ",
                          item_type.name()) };
    str = {str,  $psprintf("\n\t ----| AES Mode:    \t %s                          |----\t ",
                          mode.name()) };
    str = {str,  $psprintf("\n\t ----| Operation:    \t %s                          |----\t ",
                           operation == AES_ENC ? "AES_ENC" :
                           operation == AES_DEC ? "AES_DEC" : "INVALID")};
    str = {str,  $psprintf("\n\t ----| Key len:    \t %s  \t(%3b)                           |----\t ",
                          (key_len==3'b001) ? "128b" : (key_len == 3'b010) ? "192b" : "256b", key_len)};
    str = {str,  $psprintf("\n\t ----| Key Share 0: \t ")};
    for (int i=0; i <8; i++) begin
      str = {str, $psprintf("%h ",key[0][i])};
    end
    str = {str,  $psprintf("\n\t ----| Key Share 1: \t ") };
    for (int i=0; i <8; i++) begin
      str = {str, $psprintf("%h ",key[1][i])};
    end
    str = {str,  $sformatf("\n\t ----| Initializaion vector:         \t ")};
    for (int i=0; i <4; i++) begin
      str = {str, $sformatf("%h ",iv[i])};
    end
    str = {str,  $psprintf("\n\t ----| key_mask: \t %d |----\t  \t", key_mask)};
    str = {str,  $psprintf("\n\t ----| Data Length: \t %d |----\t  \t", data_len)};
    str = {str,  $psprintf("\n\t ----| Input data:  \t %h |----\t ", data_in)};
    str = {str,  $psprintf("\n\t ----| Output data: \t %h |----\t ", data_out)};
    str = {str,  $psprintf("\n\t") };

    return str;
  endfunction // conver2string

  virtual function string bytes2string();
    string str="\n\t ----| data_out: ";
    for(int i=0; i<4; i++) begin
      str = {str, $psprintf("%h", data_out[i][31:0])};
    end
    return str;
  endfunction
endclass
