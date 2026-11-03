create_clock -name {sys_clk_50m} -period 20.000 -waveform {0.000 10.000} [get_ports {I_sys_clk}]
create_clock -name {mipi_rx_ck_pad} -period 2.222 -waveform {0.000 1.111} [get_nets {IO_rx_clk_pad_p}]

# PH1P35 V2 fractional PLL: generated IP uses 29 + 187904819 / 2^28.
# Explicit ratios avoid the TD auto-derivation discrepancy (73.003/365.097).
# Keep the 5:1 relationship visible to STA; this does not change PLL hardware.
create_generated_clock -name {HDMI_PIXEL_CLK} -source [get_ports {I_sys_clk}] -multiply_by 1.485 [get_pins {u_hdmi_pll/ph1p_phy_pll_wrapper_Inst/u_PH1P_PHY_PLL.clkc[0]}]
create_generated_clock -name {HDMI_SERIAL_CLK} -source [get_ports {I_sys_clk}] -multiply_by 7.425 [get_pins {u_hdmi_pll/ph1p_phy_pll_wrapper_Inst/u_PH1P_PHY_PLL.clkc[1]}]

derive_clocks

rename_clock -name {pll_clk_100m} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[0]}]
rename_clock -name {pll_clk_24m} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[1]}]
rename_clock -name {HAND_ANALYSIS_CLK} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[4]}]

rename_clock -name {MIPI_RX_BYTE_CLK} [get_clocks {u_mipi_dphy_rx_ph1p_mipiio_wrapper/u_ph1p_mipiio_rx_wrapper/u_mipi_ip/MIPIIOF6F1D1P0_Inst/u_PH1P_LOGIC_DPHY_MIPI_RX.o_fabric_div4_8_clk}]


set_clock_groups -asynchronous \
    -group [get_clocks {HDMI_PIXEL_CLK HDMI_SERIAL_CLK}] \
    -group [get_clocks {mipi_rx_ck_pad MIPI_RX_BYTE_CLK}] \
    -group [get_clocks {sys_clk_50m pll_clk_100m pll_clk_24m HAND_ANALYSIS_CLK}] \
    -group [get_clocks {u_ph1p35_324_ddr_wrapper/u_ddr2/ddr_clk u_ph1p35_324_ddr_wrapper/u_ddr2/usr_clk}]

set_false_path -from [get_clocks {pll_clk_24m}] \
    -to [get_clocks {HDMI_PIXEL_CLK}]
