//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Sat Oct 31 11:37:34 2026
//Host        : Administrator running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (GMX_A_CTRL_tri_o,
    GMX_A_I2C_scl_io,
    GMX_A_I2C_sda_io,
    GMX_A_STATUS_tri_i,
    M2_PCIE_REFCLK_SOM_N_0,
    M2_PCIE_REFCLK_SOM_P_0,
    PAC1944_I2C_scl_io,
    PAC1944_I2C_sda_io,
    c0_ddr4_act_n,
    c0_ddr4_adr,
    c0_ddr4_ba,
    c0_ddr4_bg,
    c0_ddr4_ck_c,
    c0_ddr4_ck_t,
    c0_ddr4_cke,
    c0_ddr4_cs_n,
    c0_ddr4_dm_n,
    c0_ddr4_dq,
    c0_ddr4_dqs_c,
    c0_ddr4_dqs_t,
    c0_ddr4_odt,
    c0_ddr4_reset_n,
    c0_sys_clk_clk_n,
    c0_sys_clk_clk_p,
    capture_rx_clk,
    capture_rx_data,
    capture_rx_fval,
    capture_rx_lval);
  output [14:0]GMX_A_CTRL_tri_o;
  inout GMX_A_I2C_scl_io;
  inout GMX_A_I2C_sda_io;
  input [31:0]GMX_A_STATUS_tri_i;
  input M2_PCIE_REFCLK_SOM_N_0;
  input M2_PCIE_REFCLK_SOM_P_0;
  inout PAC1944_I2C_scl_io;
  inout PAC1944_I2C_sda_io;
  output c0_ddr4_act_n;
  output [16:0]c0_ddr4_adr;
  output [1:0]c0_ddr4_ba;
  output [0:0]c0_ddr4_bg;
  output [0:0]c0_ddr4_ck_c;
  output [0:0]c0_ddr4_ck_t;
  output [0:0]c0_ddr4_cke;
  output [0:0]c0_ddr4_cs_n;
  inout [7:0]c0_ddr4_dm_n;
  inout [63:0]c0_ddr4_dq;
  inout [7:0]c0_ddr4_dqs_c;
  inout [7:0]c0_ddr4_dqs_t;
  output [0:0]c0_ddr4_odt;
  output c0_ddr4_reset_n;
  input c0_sys_clk_clk_n;
  input c0_sys_clk_clk_p;
  input capture_rx_clk;
  input [191:0]capture_rx_data;
  input capture_rx_fval;
  input capture_rx_lval;

  wire [14:0]GMX_A_CTRL_tri_o;
  wire GMX_A_I2C_scl_i;
  wire GMX_A_I2C_scl_io;
  wire GMX_A_I2C_scl_o;
  wire GMX_A_I2C_scl_t;
  wire GMX_A_I2C_sda_i;
  wire GMX_A_I2C_sda_io;
  wire GMX_A_I2C_sda_o;
  wire GMX_A_I2C_sda_t;
  wire [31:0]GMX_A_STATUS_tri_i;
  wire M2_PCIE_REFCLK_SOM_N_0;
  wire M2_PCIE_REFCLK_SOM_P_0;
  wire PAC1944_I2C_scl_io;
  wire PAC1944_I2C_sda_io;
  wire c0_ddr4_act_n;
  wire [16:0]c0_ddr4_adr;
  wire [1:0]c0_ddr4_ba;
  wire [0:0]c0_ddr4_bg;
  wire [0:0]c0_ddr4_ck_c;
  wire [0:0]c0_ddr4_ck_t;
  wire [0:0]c0_ddr4_cke;
  wire [0:0]c0_ddr4_cs_n;
  wire [7:0]c0_ddr4_dm_n;
  wire [63:0]c0_ddr4_dq;
  wire [7:0]c0_ddr4_dqs_c;
  wire [7:0]c0_ddr4_dqs_t;
  wire [0:0]c0_ddr4_odt;
  wire c0_ddr4_reset_n;
  wire c0_sys_clk_clk_n;
  wire c0_sys_clk_clk_p;
  wire capture_rx_clk;
  wire [191:0]capture_rx_data;
  wire capture_rx_fval;
  wire capture_rx_lval;

  IOBUF GMX_A_I2C_scl_iobuf
       (.I(GMX_A_I2C_scl_o),
        .IO(GMX_A_I2C_scl_io),
        .O(GMX_A_I2C_scl_i),
        .T(GMX_A_I2C_scl_t));
  IOBUF GMX_A_I2C_sda_iobuf
       (.I(GMX_A_I2C_sda_o),
        .IO(GMX_A_I2C_sda_io),
        .O(GMX_A_I2C_sda_i),
        .T(GMX_A_I2C_sda_t));
  design_1 design_1_i
       (.GMX_A_CTRL_tri_o(GMX_A_CTRL_tri_o),
        .GMX_A_I2C_scl_i(GMX_A_I2C_scl_i),
        .GMX_A_I2C_scl_o(GMX_A_I2C_scl_o),
        .GMX_A_I2C_scl_t(GMX_A_I2C_scl_t),
        .GMX_A_I2C_sda_i(GMX_A_I2C_sda_i),
        .GMX_A_I2C_sda_o(GMX_A_I2C_sda_o),
        .GMX_A_I2C_sda_t(GMX_A_I2C_sda_t),
        .GMX_A_STATUS_tri_i(GMX_A_STATUS_tri_i),
        .M2_PCIE_REFCLK_SOM_N_0(M2_PCIE_REFCLK_SOM_N_0),
        .M2_PCIE_REFCLK_SOM_P_0(M2_PCIE_REFCLK_SOM_P_0),
        .PAC1944_I2C_scl_io(PAC1944_I2C_scl_io),
        .PAC1944_I2C_sda_io(PAC1944_I2C_sda_io),
        .c0_ddr4_act_n(c0_ddr4_act_n),
        .c0_ddr4_adr(c0_ddr4_adr),
        .c0_ddr4_ba(c0_ddr4_ba),
        .c0_ddr4_bg(c0_ddr4_bg),
        .c0_ddr4_ck_c(c0_ddr4_ck_c),
        .c0_ddr4_ck_t(c0_ddr4_ck_t),
        .c0_ddr4_cke(c0_ddr4_cke),
        .c0_ddr4_cs_n(c0_ddr4_cs_n),
        .c0_ddr4_dm_n(c0_ddr4_dm_n),
        .c0_ddr4_dq(c0_ddr4_dq),
        .c0_ddr4_dqs_c(c0_ddr4_dqs_c),
        .c0_ddr4_dqs_t(c0_ddr4_dqs_t),
        .c0_ddr4_odt(c0_ddr4_odt),
        .c0_ddr4_reset_n(c0_ddr4_reset_n),
        .c0_sys_clk_clk_n(c0_sys_clk_clk_n),
        .c0_sys_clk_clk_p(c0_sys_clk_clk_p),
        .capture_rx_clk(capture_rx_clk),
        .capture_rx_data(capture_rx_data),
        .capture_rx_fval(capture_rx_fval),
        .capture_rx_lval(capture_rx_lval));
endmodule
