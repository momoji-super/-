// 720p60 HDMI clocks. Parameters checked with TD 6.2 PLL Dependency.tcl.
// FIN=50 MHz, REF=1, N=29+187904819/2^28, VCO~=1485 MHz.
// No compensation; CLK0=VCO/20=74.25 MHz, CLK1=VCO/4=371.25 MHz.
`include "hdmi720_phy_pll_wrapper.v"
`timescale 1 ns / 100 fs 

module HDMI_PLL720
(
  input                         refclk,
  output                        clk0_out,
  output                        clk1_out,
  output                        lock,
  input                         reset
);
 

 


 
 


  hdmi720_phy_pll_wrapper
  #(
      .FBKCLK("VCO_PHASE0"),
      .FBKCLK_INT("VCO_PHASE0"),
      .FIN("50.000000000"),
      .REFCLK_DIV(1),
      .FBCLK_DIV(29),
      .CLKC0_ENABLE("ENABLE"),
      .CLKC0_DIV(20),
      .CLKC0_CPHASE(19),
      .CLKC0_FPHASE(0),
      .CLKC0_FPHASE_RSTSEL(0),
      .CLKC0_DUTY50("ENABLE"),
      .CLKC0_DUTY_INT(10),
      .CLKC1_ENABLE("ENABLE"),
      .CLKC1_DIV(4),
      .CLKC1_CPHASE(3),
      .CLKC1_FPHASE(0),
      .CLKC1_FPHASE_RSTSEL(0),
      .CLKC1_DUTY50("ENABLE"),
      .CLKC1_DUTY_INT(2),
      .PLL_USR_RST("ENABLE"),
      .PLL_FEED_TYPE("EXTERNAL"),
      .PLL_FASTLOOP("ENABLE"),
      .LPF_RES(0),
      .LPF_CAP(5),
      .ICP_CUR(29),
      .PHASE_PATH_SEL(0),
      .DYN_PHASE_PATH_SEL("DISABLE"),
      .DYN_FPHASE_EN("DISABLE"),
      .PI_OUT_SEL("NORMAL"),
      .FRAC_ENABLE("ENABLE"),
      .SDM_FRAC(187904819),
      .PI_FRAC_EN("DISABLE"),
      .CLKC0_PI_SHIFT_EN("DISABLE"),
      .FEEDBK_MODE("NOCOMP"),
      .DYN_CPHASE_EN("DISABLE")
  )hdmi720_phy_pll_wrapper_Inst
  (
      .clk2_en(1'b0),
      .clk2_out(),
      .clkb2_out(),
      .clk3_en(1'b0),
      .clk3_out(),
      .clkb3_out(),
      .clk6_en(1'b0),
      .clk6_out(),
      .clkb6_out(),
      .refclk(refclk),
      .drp_clk(1'b0),
      .drp_rstn(1'b1),
      .drp_sel(1'b0),
      .drp_rd(1'b0),
      .drp_wr(1'b0),
      .drp_addr(8'b00000000),
      .drp_wdata(8'b00000000),
      .drp_err(),
      .drp_rdy(),
      .drp_rdata(),
      .psclk(1'b0),
      .psclksel(3'b000),
      .psstep(1'b0),
      .psdown(1'b0),
      .cps_step(1'b0),
      .psdone(),
      .ssc_reset(1'b0),
	  .clkc_rst(2'b00),
      .pllpd(1'b0),
      .fbclk(1'b0),
      .wakeup(1'b1),
      .refclk_rst(1'b0),
      .clk0_en(1'b1),
      .clkb0_out(),
      .clk0_out(clk0_out),
      .clk1_en(1'b1),
      .clkb1_out(),
      .clk1_out(clk1_out),
      .clk4_en(1'b0),
      .clkb4_out(),
      .clk4_out(),
      .clk5_en(1'b0),
      .clkb5_out(),
      .clk5_out(),
      .lock(lock),
      .reset(reset)
  );
endmodule
