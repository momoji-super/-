module MIPIIOF6F1D1P0_mipi(
	//pad
	inout						io_clk_pad_p,
	inout						io_clk_pad_n,
	inout						io_data_pad0_p,
	inout						io_data_pad0_n,
	inout						io_data_pad1_p,
	inout						io_data_pad1_n,
	inout						io_data_pad2_p,
	inout						io_data_pad2_n,
	inout						io_data_pad3_p,
	inout						io_data_pad3_n,
	//lvcmos
    input						i_ck_lvcmos_tx_en,          
    input		[6:0]			i_ck_p_lvcmos_idelay_value, 
    input						i_ck_p_lvcmos_tx,           
    output     					o_ck_p_lvcmos_rx,           
    input      					i_ck_n_lvcmos_tx,           
    output     					o_ck_n_lvcmos_rx,           

    input						i_l0_lvcmos_tx_en,          
    input		[6:0]			i_l0_p_lvcmos_idelay_value, 
    input						i_l0_p_lvcmos_tx,          
    output     					o_l0_p_lvcmos_rx,           
    input      					i_l0_n_lvcmos_tx,           
    output     					o_l0_n_lvcmos_rx,           

    input						i_l1_lvcmos_tx_en,          
    input		[6:0]			i_l1_p_lvcmos_idelay_value, 
    input						i_l1_p_lvcmos_tx,           
    output						o_l1_p_lvcmos_rx,           
    input						i_l1_n_lvcmos_tx,           
    output						o_l1_n_lvcmos_rx,           

    input						i_l2_lvcmos_tx_en,          
    input		[6:0]			i_l2_p_lvcmos_idelay_value, 
    input						i_l2_p_lvcmos_tx,           
    output						o_l2_p_lvcmos_rx,           
    input						i_l2_n_lvcmos_tx,           
    output						o_l2_n_lvcmos_rx,           

    input						i_l3_lvcmos_tx_en,          
    input		[6:0]			i_l3_p_lvcmos_idelay_value, 
    input						i_l3_p_lvcmos_tx,           
    output						o_l3_p_lvcmos_rx,           
    input						i_l3_n_lvcmos_tx,           
    output						o_l3_n_lvcmos_rx,           
	//LVDS TX
    input						i_phy_dpll_ref_clk,        
    output						o_fabric_div5_10_clk,       
    output						o_fabric_div4_8_clk,       

    input						i_phy_dpll_rst_n,         
    input						i_phy_dpll_pwdn_n, 
    output						o_phy_dpll_locked,        
    input		[6:0]			i_phy_dpll_multi_ratio,   
    input		[5:0]			i_phy_dpll_div_ratio,     

    input						i_phy_rst_n,              

    input						i_ck_tx_en,              
    input		[3:0]			i_ck_odelay_value,       
    input		[15:0]			i_ck_tx_data,            

    input						i_l0_tx_en,              
    input		[3:0]			i_l0_odelay_value,       
    input		[15:0]			i_l0_tx_data,            

    input						i_l1_tx_en,              
    input		[3:0]			i_l1_odelay_value,       
    input		[15:0]			i_l1_tx_data,            
			
    input						i_l2_tx_en,                  
    input		[3:0]			i_l2_odelay_value,                
    input		[15:0]			i_l2_tx_data,            

    input						i_l3_tx_en,                   
    input		[3:0]			i_l3_odelay_value,                 
    input		[15:0]			i_l3_tx_data,                 
	//LVDS RX
	input						i_pll_to_phy_sample_clk,
	output						o_phy_to_pll_ref_clk,
    input						i_ck_rx_en,
    input		[5:0]			i_ck_idelay_value,
    
	input						i_l0_rx_en,
    input						i_l0_slave_deser_clk_en,
    input		[5:0]			i_l0_idelay_value,
    output		[15:0]			o_l0_rx_data,
    output		[15:0]			o_l0_rx_slave_data,

    input						i_l1_rx_en,
    input						i_l1_slave_deser_clk_en,
    input		[5:0]			i_l1_idelay_value,
    output		[15:0]			o_l1_rx_data,
    output		[15:0]			o_l1_rx_slave_data,

    input						i_l2_rx_en,
    input						i_l2_slave_deser_clk_en,
    input		[5:0]			i_l2_idelay_value,
    output		[15:0]			o_l2_rx_data,
    output		[15:0]			o_l2_rx_slave_data,

    input						i_l3_rx_en,
    input						i_l3_slave_deser_clk_en,
    input		[5:0]			i_l3_idelay_value,
    output		[15:0]			o_l3_rx_data,
    output		[15:0]			o_l3_rx_slave_data,
	//MIPI TX
    input						i_ck_lp_tx_en,
    input						i_ck_lp_tx_p,
    input						i_ck_lp_tx_n,
    input						i_ck_hs_tx_en,
    input		[3:0]			i_ck_hs_odelay_value,
    input		[15:0]			i_ck_hs_tx_data,

    input						i_l0_lp_tx_en,
    input						i_l0_lp_tx_p,
    input						i_l0_lp_tx_n,
    output						o_l0_lp_rx_p,
    output						o_l0_lp_rx_n,
    input						i_l0_hs_tx_en,
    input		[3:0]			i_l0_hs_odelay_value,
    input		[15:0]			i_l0_hs_tx_data,

    input						i_l1_lp_tx_en,
    input						i_l1_lp_tx_p,
    input						i_l1_lp_tx_n,
    output						o_l1_lp_rx_p,
    output						o_l1_lp_rx_n,
    input						i_l1_hs_tx_en,
    input		[3:0]			i_l1_hs_odelay_value,
    input		[15:0]			i_l1_hs_tx_data,

    input						i_l2_lp_tx_en,          
    input						i_l2_lp_tx_p,            
    input						i_l2_lp_tx_n,            
    output						o_l2_lp_rx_p,            
    output						o_l2_lp_rx_n,            
    input						i_l2_hs_tx_en,           
    input		[3:0]			i_l2_hs_odelay_value,    
    input		[15:0]			i_l2_hs_tx_data,         

    input						i_l3_lp_tx_en,           
    input						i_l3_lp_tx_p,
    input						i_l3_lp_tx_n,
    output						o_l3_lp_rx_p,
    output						o_l3_lp_rx_n,
    input						i_l3_hs_tx_en,
    input		[3:0]			i_l3_hs_odelay_value,
    input		[15:0]			i_l3_hs_tx_data,
	//MIPI RX
	input						i_ck_lp_rx_en,
    output						o_ck_lp_rx_p,
    output						o_ck_lp_rx_n,
    input						i_ck_hs_rx_en,
    input		[1:0]			i_ck_hs_terminator_sel,
    input						i_ck_hs_idelay_en,
    input		[5:0]			i_ck_hs_idelay_value,

    input						i_l0_lp_rx_en,
    input						i_l0_hs_rx_en,
    input		[1:0]			i_l0_hs_terminator_sel,
    input						i_l0_hs_slave_deser_clk_en,
    input						i_l0_hs_idelay_en,
    input		[5:0]			i_l0_hs_idelay_value,            
    output		[15:0]			o_l0_hs_rx_data,
    output		[15:0]			o_l0_hs_rx_slave_data,

    input						i_l1_lp_rx_en,
    input						i_l1_hs_rx_en,
    input		[1:0]			i_l1_hs_terminator_sel,
    input						i_l1_hs_slave_deser_clk_en,
    input						i_l1_hs_idelay_en,
    input		[5:0]			i_l1_hs_idelay_value,            
    output		[15:0]			o_l1_hs_rx_data,
    output		[15:0]			o_l1_hs_rx_slave_data,

    input						i_l2_lp_rx_en,
    input						i_l2_hs_rx_en,
    input		[1:0]			i_l2_hs_terminator_sel,
    input						i_l2_hs_slave_deser_clk_en,
    input						i_l2_hs_idelay_en,
    input		[5:0]			i_l2_hs_idelay_value,            
    output		[15:0]			o_l2_hs_rx_data,
    output		[15:0]			o_l2_hs_rx_slave_data,

    input						i_l3_lp_rx_en,
    input						i_l3_hs_rx_en,
    input		[1:0]			i_l3_hs_terminator_sel,
    input						i_l3_hs_slave_deser_clk_en,
    input						i_l3_hs_idelay_en,
    input		[5:0]			i_l3_hs_idelay_value,            
    output		[15:0]			o_l3_hs_rx_data,
    output		[15:0]			o_l3_hs_rx_slave_data
);
//pack parameter
parameter LVCMOS_EN = 1'b0;
parameter LVDS_TX_EN = 1'b0;
parameter LVDS_RX_EN = 1'b0;
parameter MIPI_TX_EN = 1'b0;
parameter MIPI_RX_EN = 1'b1;

parameter CLK_CHANNEL_EN = 1'b1;
parameter CHANNEL0_EN = 1'b1;
parameter CHANNEL1_EN = 1'b0;
parameter CHANNEL2_EN = 1'b0;
parameter CHANNEL3_EN = 1'b0;
//common
parameter DPHY_LOCATION = "DPHY0";
//LVCOMS PMA
parameter CK_RX_IOSTANDARD = "LVCMOS18";
parameter L0_RX_IOSTANDARD = "LVCMOS18";
parameter L1_RX_IOSTANDARD = "LVCMOS18";
parameter L2_RX_IOSTANDARD = "LVCMOS18";
parameter L3_RX_IOSTANDARD = "LVCMOS18";

parameter CK_TX_SLEW_RATE = "SLOW";
parameter L0_TX_SLEW_RATE = "SLOW";
parameter L1_TX_SLEW_RATE = "SLOW";
parameter L2_TX_SLEW_RATE = "SLOW";
parameter L3_TX_SLEW_RATE = "SLOW";

parameter CK_TX_DRIVESTRENGTH = "4mA";
parameter L0_TX_DRIVESTRENGTH = "4mA";
parameter L1_TX_DRIVESTRENGTH = "4mA";
parameter L2_TX_DRIVESTRENGTH = "4mA";
parameter L3_TX_DRIVESTRENGTH = "4mA";
//LVDS TX PROTOCOL
parameter P2S_RATIO = "8:1";
parameter LVDS_OUTPUT_VCM = "1.2v";
parameter LVDS_EXTRA_VOD_GAIN = "DISABLE";
parameter LVDS_OVER_CURRENT_PROTECT = "DISABLE";
parameter LVDS_TX_VCO_BYPASS = "ENABLE";
//LVDS TX PMA
parameter CK_DE_EMPHASIS = "0dB";
parameter L0_DE_EMPHASIS = "0dB";
parameter L1_DE_EMPHASIS = "0dB";
parameter L2_DE_EMPHASIS = "0dB";
parameter L3_DE_EMPHASIS = "0dB";

parameter CK_LVDS_OUTPUT_VOD = "3.5mA";
parameter L0_LVDS_OUTPUT_VOD = "3.5mA";
parameter L1_LVDS_OUTPUT_VOD = "3.5mA";
parameter L2_LVDS_OUTPUT_VOD = "3.5mA";
parameter L3_LVDS_OUTPUT_VOD = "3.5mA";
//LVDS RX PROTOCOL
parameter S2P_RATIO = "1:8";
parameter SAMPLE_CLOCK_SEL = "CLK_LANE";
//LVDS RX PMA
parameter CK_EQUALIZER = "0dB";
parameter L0_EQUALIZER = "0dB";
parameter L1_EQUALIZER = "0dB";
parameter L2_EQUALIZER = "0dB";
parameter L3_EQUALIZER = "0dB";

parameter CK_VGA_GAIN = "0dB";
parameter L0_VGA_GAIN = "0dB";
parameter L1_VGA_GAIN = "0dB";
parameter L2_VGA_GAIN = "0dB";
parameter L3_VGA_GAIN = "0dB";

parameter CK_IDELAY_ENABLE = "ENABLE";
parameter L0_IDELAY_ENABLE = "ENABLE";
parameter L1_IDELAY_ENABLE = "ENABLE";
parameter L2_IDELAY_ENABLE = "ENABLE";
parameter L3_IDELAY_ENABLE = "ENABLE";

parameter CK_TERMINATOR = "AC100ohm";
parameter L0_TERMINATOR = "AC100ohm";
parameter L1_TERMINATOR = "AC100ohm";
parameter L2_TERMINATOR = "AC100ohm";
parameter L3_TERMINATOR = "AC100ohm";

parameter L0_SLAVE_DESER_CLK_OFFSET = "16ps";
parameter L1_SLAVE_DESER_CLK_OFFSET = "16ps";
parameter L2_SLAVE_DESER_CLK_OFFSET = "16ps";
parameter L3_SLAVE_DESER_CLK_OFFSET = "16ps";

parameter CK_VCM_COMPENSATION = "ENABLE";
parameter L0_VCM_COMPENSATION = "ENABLE";
parameter L1_VCM_COMPENSATION = "ENABLE";
parameter L2_VCM_COMPENSATION = "ENABLE";
parameter L3_VCM_COMPENSATION = "ENABLE";

parameter CK_DUTY_COMPENSATION = "0%";
parameter L0_DUTY_COMPENSATION = "0%";
parameter L1_DUTY_COMPENSATION = "0%";
parameter L2_DUTY_COMPENSATION = "0%";
parameter L3_DUTY_COMPENSATION = "0%";

parameter CK_DUTY_COMPENSATION_POLARITY = "DECREASE";
parameter L0_DUTY_COMPENSATION_POLARITY = "DECREASE";
parameter L1_DUTY_COMPENSATION_POLARITY = "DECREASE";
parameter L2_DUTY_COMPENSATION_POLARITY = "DECREASE";
parameter L3_DUTY_COMPENSATION_POLARITY = "DECREASE";

parameter CK_INTERNAL_AC_CAP_ENABLE = "DISABLE";
parameter L0_INTERNAL_AC_CAP_ENABLE = "DISABLE";
parameter L1_INTERNAL_AC_CAP_ENABLE = "DISABLE";
parameter L2_INTERNAL_AC_CAP_ENABLE = "DISABLE";
parameter L3_INTERNAL_AC_CAP_ENABLE = "DISABLE";

//MIPI TX PROTOCOL
parameter HS_OUTPUT_IMPEDANCE = "50ohm";
parameter HS_P2S_RATIO = "8:1";
parameter HS_OUTPUT_VOD = "212.5mV";
parameter MIPI_TX_VCO_BYPASS = "ENABLE";
//MIPI TX PMA
parameter CK_LP_OUTPUT_IMPEDANCE = "110ohm";
parameter L0_LP_OUTPUT_IMPEDANCE = "110ohm";
parameter L1_LP_OUTPUT_IMPEDANCE = "110ohm";
parameter L2_LP_OUTPUT_IMPEDANCE = "110ohm";
parameter L3_LP_OUTPUT_IMPEDANCE = "110ohm";

parameter CK_LP_OUTPUT_SLEW_RATE = "SLOW";
parameter L0_LP_OUTPUT_SLEW_RATE = "SLOW";
parameter L1_LP_OUTPUT_SLEW_RATE = "SLOW";
parameter L2_LP_OUTPUT_SLEW_RATE = "SLOW";
parameter L3_LP_OUTPUT_SLEW_RATE = "SLOW";

parameter CK_HS_DE_EMPHASIS = "0dB";
parameter L0_HS_DE_EMPHASIS = "0dB";
parameter L1_HS_DE_EMPHASIS = "0dB";
parameter L2_HS_DE_EMPHASIS = "0dB";
parameter L3_HS_DE_EMPHASIS = "0dB";

//MIPI RX PROTOCOL
parameter HS_S2P_RATIO = "1:8";
//MIPI RX PMA
parameter CK_HS_EQUALIZER = "0dB";
parameter L0_HS_EQUALIZER = "0dB";
parameter L1_HS_EQUALIZER = "0dB";
parameter L2_HS_EQUALIZER = "0dB";
parameter L3_HS_EQUALIZER = "0dB";

parameter CK_HS_VGA_GAIN = "12dB";
parameter L0_HS_VGA_GAIN = "12dB";
parameter L1_HS_VGA_GAIN = "12dB";
parameter L2_HS_VGA_GAIN = "12dB";
parameter L3_HS_VGA_GAIN = "12dB";

parameter L0_HS_SLAVE_DESER_CLK_OFFSET = "16ps";
parameter L1_HS_SLAVE_DESER_CLK_OFFSET = "16ps";
parameter L2_HS_SLAVE_DESER_CLK_OFFSET = "16ps";
parameter L3_HS_SLAVE_DESER_CLK_OFFSET = "16ps";

//lvcmos
wire						i_ck_lvcmos_tx_en_transition;
wire		[6:0]			i_ck_p_lvcmos_idelay_value_transition;
wire						i_ck_p_lvcmos_tx_transition;
wire						i_ck_n_lvcmos_tx_transition;

wire						i_l0_lvcmos_tx_en_transition;
wire		[6:0]			i_l0_p_lvcmos_idelay_value_transition;
wire						i_l0_p_lvcmos_tx_transition;
wire						i_l0_n_lvcmos_tx_transition;

wire						i_l1_lvcmos_tx_en_transition;
wire		[6:0]			i_l1_p_lvcmos_idelay_value_transition;
wire						i_l1_p_lvcmos_tx_transition;
wire						i_l1_n_lvcmos_tx_transition;

wire						i_l2_lvcmos_tx_en_transition;
wire		[6:0]			i_l2_p_lvcmos_idelay_value_transition;
wire						i_l2_p_lvcmos_tx_transition;
wire						i_l2_n_lvcmos_tx_transition;

wire						i_l3_lvcmos_tx_en_transition;
wire		[6:0]			i_l3_p_lvcmos_idelay_value_transition;
wire						i_l3_p_lvcmos_tx_transition;
wire						i_l3_n_lvcmos_tx_transition;
//LVDS TX
wire						i_phy_dpll_ref_clk_transition;
wire						i_phy_dpll_vco_bypass_n;

wire						i_l0_tx_en_transition;
wire		[3:0]			i_l0_odelay_value_transition;
wire		[15:0]			i_l0_tx_data_transition;

wire						i_l1_tx_en_transition;
wire		[3:0]			i_l1_odelay_value_transition;
wire		[15:0]			i_l1_tx_data_transition;

wire						i_l2_tx_en_transition;
wire		[3:0]			i_l2_odelay_value_transition;
wire		[15:0]			i_l2_tx_data_transition;

wire						i_l3_tx_en_transition;
wire		[3:0]			i_l3_odelay_value_transition;
wire		[15:0]			i_l3_tx_data_transition;
//LVDS RX

wire						i_pll_to_phy_sample_clk_transition;

wire						i_l0_rx_en_transition;
wire						i_l0_slave_deser_clk_en_transition;
wire		[5:0]			i_l0_idelay_value_transition;

wire						i_l1_rx_en_transition;
wire						i_l1_slave_deser_clk_en_transition;
wire		[5:0]			i_l1_idelay_value_transition;

wire						i_l2_rx_en_transition;
wire						i_l2_slave_deser_clk_en_transition;
wire		[5:0]			i_l2_idelay_value_transition;

wire						i_l3_rx_en_transition;
wire						i_l3_slave_deser_clk_en_transition;
wire		[5:0]			i_l3_idelay_value_transition;
//MIPI TX
wire						i_l0_lp_tx_en_transition;
wire						i_l0_lp_tx_p_transition;
wire						i_l0_lp_tx_n_transition;
wire						i_l0_hs_tx_en_transition;
wire		[3:0]			i_l0_hs_odelay_value_transition;
wire		[15:0]			i_l0_hs_tx_data_transition;

wire						i_l1_lp_tx_en_transition;
wire						i_l1_lp_tx_p_transition;
wire						i_l1_lp_tx_n_transition;
wire						i_l1_hs_tx_en_transition;
wire		[3:0]			i_l1_hs_odelay_value_transition;
wire		[15:0]			i_l1_hs_tx_data_transition;

wire						i_l2_lp_tx_en_transition;
wire						i_l2_lp_tx_p_transition;
wire						i_l2_lp_tx_n_transition;
wire						i_l2_hs_tx_en_transition;
wire		[3:0]			i_l2_hs_odelay_value_transition;
wire		[15:0]			i_l2_hs_tx_data_transition;

wire						i_l3_lp_tx_en_transition;
wire						i_l3_lp_tx_p_transition;
wire						i_l3_lp_tx_n_transition;
wire						i_l3_hs_tx_en_transition;
wire		[3:0]			i_l3_hs_odelay_value_transition;
wire		[15:0]			i_l3_hs_tx_data_transition;

//MIPI RX
wire						i_l0_lp_rx_en_transition;
wire						i_l0_hs_rx_en_transition;
wire		[1:0]			i_l0_hs_terminator_sel_transition;
wire						i_l0_hs_slave_deser_clk_en_transition;
wire						i_l0_hs_idelay_en_transition;
wire		[5:0]			i_l0_hs_idelay_value_transition;

wire						i_l1_lp_rx_en_transition;
wire						i_l1_hs_rx_en_transition;
wire		[1:0]			i_l1_hs_terminator_sel_transition;
wire						i_l1_hs_slave_deser_clk_en_transition;
wire						i_l1_hs_idelay_en_transition;
wire		[5:0]			i_l1_hs_idelay_value_transition;

wire						i_l2_lp_rx_en_transition;
wire						i_l2_hs_rx_en_transition;
wire		[1:0]			i_l2_hs_terminator_sel_transition;
wire						i_l2_hs_slave_deser_clk_en_transition;
wire						i_l2_hs_idelay_en_transition;
wire		[5:0]			i_l2_hs_idelay_value_transition;

wire						i_l3_lp_rx_en_transition;
wire						i_l3_hs_rx_en_transition;
wire		[1:0]			i_l3_hs_terminator_sel_transition;
wire						i_l3_hs_slave_deser_clk_en_transition;
wire						i_l3_hs_idelay_en_transition;
wire		[5:0]			i_l3_hs_idelay_value_transition;

//LVCMOS
assign i_ck_lvcmos_tx_en_transition = (LVCMOS_EN && CLK_CHANNEL_EN) ? i_ck_lvcmos_tx_en : 1'b0;
assign i_ck_p_lvcmos_idelay_value_transition = (LVCMOS_EN && CLK_CHANNEL_EN) ? i_ck_p_lvcmos_idelay_value : 7'b0;
assign i_ck_p_lvcmos_tx_transition = (LVCMOS_EN && CLK_CHANNEL_EN) ? i_ck_p_lvcmos_tx : 1'b0;
assign i_ck_n_lvcmos_tx_transition = (LVCMOS_EN && CLK_CHANNEL_EN) ? i_ck_n_lvcmos_tx : 1'b0;

assign i_l0_lvcmos_tx_en_transition = (LVCMOS_EN && CHANNEL0_EN) ? i_l0_lvcmos_tx_en : 1'b0;
assign i_l0_p_lvcmos_idelay_value_transition = (LVCMOS_EN && CHANNEL0_EN) ? i_l0_p_lvcmos_idelay_value : 7'b0;
assign i_l0_p_lvcmos_tx_transition = (LVCMOS_EN && CHANNEL0_EN) ? i_l0_p_lvcmos_tx : 1'b0;
assign i_l0_n_lvcmos_tx_transition = (LVCMOS_EN && CHANNEL0_EN) ? i_l0_n_lvcmos_tx : 1'b0;

assign i_l1_lvcmos_tx_en_transition = (LVCMOS_EN && CHANNEL1_EN) ? i_l1_lvcmos_tx_en : 1'b0;
assign i_l1_p_lvcmos_idelay_value_transition = (LVCMOS_EN && CHANNEL1_EN) ? i_l1_p_lvcmos_idelay_value : 7'b0;
assign i_l1_p_lvcmos_tx_transition = (LVCMOS_EN && CHANNEL1_EN) ? i_l1_p_lvcmos_tx : 1'b0;
assign i_l1_n_lvcmos_tx_transition = (LVCMOS_EN && CHANNEL1_EN) ? i_l1_n_lvcmos_tx : 1'b0;

assign i_l2_lvcmos_tx_en_transition = (LVCMOS_EN && CHANNEL2_EN) ? i_l2_lvcmos_tx_en : 1'b0;
assign i_l2_p_lvcmos_idelay_value_transition = (LVCMOS_EN && CHANNEL2_EN) ? i_l2_p_lvcmos_idelay_value : 7'b0;
assign i_l2_p_lvcmos_tx_transition = (LVCMOS_EN && CHANNEL2_EN) ? i_l2_p_lvcmos_tx : 1'b0;
assign i_l2_n_lvcmos_tx_transition = (LVCMOS_EN && CHANNEL2_EN) ? i_l2_n_lvcmos_tx : 1'b0;

assign i_l3_lvcmos_tx_en_transition = (LVCMOS_EN && CHANNEL3_EN) ? i_l3_lvcmos_tx_en : 1'b0;
assign i_l3_p_lvcmos_idelay_value_transition = (LVCMOS_EN && CHANNEL3_EN) ? i_l3_p_lvcmos_idelay_value : 7'b0;
assign i_l3_p_lvcmos_tx_transition = (LVCMOS_EN && CHANNEL3_EN) ? i_l3_p_lvcmos_tx : 1'b0;
assign i_l3_n_lvcmos_tx_transition = (LVCMOS_EN && CHANNEL3_EN) ? i_l3_n_lvcmos_tx : 1'b0;

//LVDS TX
assign i_phy_dpll_ref_clk_transition = (LVDS_TX_EN || MIPI_TX_EN) ? i_phy_dpll_ref_clk : 1'b0;
assign i_phy_dpll_vco_bypass_n = ((LVDS_TX_EN && (LVDS_TX_VCO_BYPASS == "ENABLE")) || (MIPI_TX_EN && (MIPI_TX_VCO_BYPASS == "ENABLE"))) ? 1'b0 : 1'b1;

assign i_l0_tx_en_transition = (LVDS_TX_EN && CHANNEL0_EN) ? i_l0_tx_en : 1'b0;
assign i_l0_odelay_value_transition = (LVDS_TX_EN && CHANNEL0_EN) ? i_l0_odelay_value : 4'b0;
assign i_l0_tx_data_transition = (LVDS_TX_EN && CHANNEL0_EN) ? i_l0_tx_data : 16'd0;

assign i_l1_tx_en_transition = (LVDS_TX_EN && CHANNEL1_EN) ? i_l1_tx_en : 1'b0;
assign i_l1_odelay_value_transition = (LVDS_TX_EN && CHANNEL1_EN) ? i_l1_odelay_value : 4'b0;
assign i_l1_tx_data_transition = (LVDS_TX_EN && CHANNEL1_EN) ? i_l1_tx_data : 16'd0;

assign i_l2_tx_en_transition = (LVDS_TX_EN && CHANNEL2_EN) ? i_l2_tx_en : 1'b0;
assign i_l2_odelay_value_transition = (LVDS_TX_EN && CHANNEL2_EN) ? i_l2_odelay_value : 4'b0;
assign i_l2_tx_data_transition = (LVDS_TX_EN && CHANNEL2_EN) ? i_l2_tx_data : 16'd0;

assign i_l3_tx_en_transition = (LVDS_TX_EN && CHANNEL3_EN) ? i_l3_tx_en : 1'b0;
assign i_l3_odelay_value_transition = (LVDS_TX_EN && CHANNEL3_EN) ? i_l3_odelay_value : 4'b0;
assign i_l3_tx_data_transition = (LVDS_TX_EN && CHANNEL3_EN) ? i_l3_tx_data : 16'd0;

//LVDS RX
assign i_l0_rx_en_transition = (LVDS_RX_EN && CHANNEL0_EN) ? i_l0_rx_en : 1'b0;
assign i_l0_slave_deser_clk_en_transition = (LVDS_RX_EN && CHANNEL0_EN) ?  i_l0_slave_deser_clk_en : 1'b0;
assign i_l0_idelay_value_transition = (LVDS_RX_EN && CHANNEL0_EN) ? i_l0_idelay_value : 6'b0;

assign i_l1_rx_en_transition = (LVDS_RX_EN && CHANNEL1_EN) ? i_l1_rx_en : 1'b0;
assign i_l1_slave_deser_clk_en_transition = (LVDS_RX_EN && CHANNEL1_EN) ?  i_l1_slave_deser_clk_en : 1'b0;
assign i_l1_idelay_value_transition = (LVDS_RX_EN && CHANNEL1_EN) ? i_l1_idelay_value : 6'b0;

assign i_l2_rx_en_transition = (LVDS_RX_EN && CHANNEL2_EN) ? i_l2_rx_en : 1'b0;
assign i_l2_slave_deser_clk_en_transition = (LVDS_RX_EN && CHANNEL2_EN) ?  i_l2_slave_deser_clk_en : 1'b0;
assign i_l2_idelay_value_transition = (LVDS_RX_EN && CHANNEL2_EN) ? i_l2_idelay_value : 6'b0;

assign i_l3_rx_en_transition = (LVDS_RX_EN && CHANNEL3_EN) ? i_l3_rx_en : 1'b0;
assign i_l3_slave_deser_clk_en_transition = (LVDS_RX_EN && CHANNEL3_EN) ?  i_l3_slave_deser_clk_en : 1'b0;
assign i_l3_idelay_value_transition = (LVDS_RX_EN && CHANNEL3_EN) ? i_l3_idelay_value : 6'b0;

//MIPI TX
assign i_l0_lp_tx_en_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL0_EN) ? i_l0_lp_tx_en : 1'b0;
assign i_l0_lp_tx_p_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL0_EN) ? i_l0_lp_tx_p : 1'b0;
assign i_l0_lp_tx_n_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL0_EN) ? i_l0_lp_tx_n : 1'b0;
assign i_l0_hs_tx_en_transition = (MIPI_TX_EN && CHANNEL0_EN) ? i_l0_hs_tx_en : 1'b0;
assign i_l0_hs_odelay_value_transition = (MIPI_TX_EN && CHANNEL0_EN) ? i_l0_hs_odelay_value : 4'b0;
assign i_l0_hs_tx_data_transition = (MIPI_TX_EN && CHANNEL0_EN) ? i_l0_hs_tx_data : 16'b0;

assign i_l1_lp_tx_en_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL1_EN) ? i_l1_lp_tx_en : 1'b0;
assign i_l1_lp_tx_p_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL1_EN) ? i_l1_lp_tx_p : 1'b0;
assign i_l1_lp_tx_n_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL1_EN) ? i_l1_lp_tx_n : 1'b0;
assign i_l1_hs_tx_en_transition = (MIPI_TX_EN && CHANNEL1_EN) ? i_l1_hs_tx_en : 1'b0;
assign i_l1_hs_odelay_value_transition = (MIPI_TX_EN && CHANNEL1_EN) ? i_l1_hs_odelay_value : 4'b0;
assign i_l1_hs_tx_data_transition = (MIPI_TX_EN && CHANNEL1_EN) ? i_l1_hs_tx_data : 16'b0;

assign i_l2_lp_tx_en_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL2_EN) ? i_l2_lp_tx_en : 1'b0;
assign i_l2_lp_tx_p_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL2_EN) ? i_l2_lp_tx_p : 1'b0;
assign i_l2_lp_tx_n_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL2_EN) ? i_l2_lp_tx_n : 1'b0;
assign i_l2_hs_tx_en_transition = (MIPI_TX_EN && CHANNEL2_EN) ? i_l2_hs_tx_en : 1'b0;
assign i_l2_hs_odelay_value_transition = (MIPI_TX_EN && CHANNEL2_EN) ? i_l2_hs_odelay_value : 4'b0;
assign i_l2_hs_tx_data_transition = (MIPI_TX_EN && CHANNEL2_EN) ? i_l2_hs_tx_data : 16'b0;

assign i_l3_lp_tx_en_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL3_EN) ? i_l3_lp_tx_en : 1'b0;
assign i_l3_lp_tx_p_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL3_EN) ? i_l3_lp_tx_p : 1'b0;
assign i_l3_lp_tx_n_transition = ((MIPI_TX_EN || MIPI_RX_EN) && CHANNEL3_EN) ? i_l3_lp_tx_n : 1'b0;
assign i_l3_hs_tx_en_transition = (MIPI_TX_EN && CHANNEL3_EN) ? i_l3_hs_tx_en : 1'b0;
assign i_l3_hs_odelay_value_transition = (MIPI_TX_EN && CHANNEL3_EN) ? i_l3_hs_odelay_value : 4'b0;
assign i_l3_hs_tx_data_transition = (MIPI_TX_EN && CHANNEL3_EN) ? i_l3_hs_tx_data : 16'b0;

//MIPI RX
assign i_pll_to_phy_sample_clk_transition = (SAMPLE_CLOCK_SEL == "PLL") ? i_pll_to_phy_sample_clk : 1'b0;

assign i_l0_lp_rx_en_transition = (MIPI_RX_EN && CHANNEL0_EN) ? i_l0_lp_rx_en : 1'b0;
assign i_l0_hs_rx_en_transition = (MIPI_RX_EN && CHANNEL0_EN) ? i_l0_hs_rx_en : 1'b0;
assign i_l0_hs_terminator_sel_transition = (MIPI_RX_EN && CHANNEL0_EN) ? i_l0_hs_terminator_sel : 2'b0;
assign i_l0_hs_slave_deser_clk_en_transition = (MIPI_RX_EN && CHANNEL0_EN) ? i_l0_hs_slave_deser_clk_en : 1'b0;
assign i_l0_hs_idelay_en_transition = (MIPI_RX_EN && CHANNEL0_EN) ? i_l0_hs_idelay_en : 1'b0;
assign i_l0_hs_idelay_value_transition = (MIPI_RX_EN && CHANNEL0_EN) ? i_l0_hs_idelay_value : 6'b0;

assign i_l1_lp_rx_en_transition = (MIPI_RX_EN && CHANNEL1_EN) ? i_l1_lp_rx_en : 1'b0;
assign i_l1_hs_rx_en_transition = (MIPI_RX_EN && CHANNEL1_EN) ? i_l1_hs_rx_en : 1'b0;
assign i_l1_hs_terminator_sel_transition = (MIPI_RX_EN && CHANNEL1_EN) ? i_l1_hs_terminator_sel : 2'b0;
assign i_l1_hs_slave_deser_clk_en_transition = (MIPI_RX_EN && CHANNEL1_EN) ? i_l1_hs_slave_deser_clk_en : 1'b0;
assign i_l1_hs_idelay_en_transition = (MIPI_RX_EN && CHANNEL1_EN) ? i_l1_hs_idelay_en : 1'b0;
assign i_l1_hs_idelay_value_transition = (MIPI_RX_EN && CHANNEL1_EN) ? i_l1_hs_idelay_value : 6'b0;

assign i_l2_lp_rx_en_transition = (MIPI_RX_EN && CHANNEL2_EN) ? i_l2_lp_rx_en : 1'b0;
assign i_l2_hs_rx_en_transition = (MIPI_RX_EN && CHANNEL2_EN) ? i_l2_hs_rx_en : 1'b0;
assign i_l2_hs_terminator_sel_transition = (MIPI_RX_EN && CHANNEL2_EN) ? i_l2_hs_terminator_sel : 2'b0;
assign i_l2_hs_slave_deser_clk_en_transition = (MIPI_RX_EN && CHANNEL2_EN) ? i_l2_hs_slave_deser_clk_en : 1'b0;
assign i_l2_hs_idelay_en_transition = (MIPI_RX_EN && CHANNEL2_EN) ? i_l2_hs_idelay_en : 1'b0;
assign i_l2_hs_idelay_value_transition = (MIPI_RX_EN && CHANNEL2_EN) ? i_l2_hs_idelay_value : 6'b0;

assign i_l3_lp_rx_en_transition = (MIPI_RX_EN && CHANNEL3_EN) ? i_l3_lp_rx_en : 1'b0;
assign i_l3_hs_rx_en_transition = (MIPI_RX_EN && CHANNEL3_EN) ? i_l3_hs_rx_en : 1'b0;
assign i_l3_hs_terminator_sel_transition = (MIPI_RX_EN && CHANNEL3_EN) ? i_l3_hs_terminator_sel : 2'b0;
assign i_l3_hs_slave_deser_clk_en_transition = (MIPI_RX_EN && CHANNEL3_EN) ? i_l3_hs_slave_deser_clk_en : 1'b0;
assign i_l3_hs_idelay_en_transition = (MIPI_RX_EN && CHANNEL3_EN) ? i_l3_hs_idelay_en : 1'b0;
assign i_l3_hs_idelay_value_transition = (MIPI_RX_EN && CHANNEL3_EN) ? i_l3_hs_idelay_value : 6'b0;



generate 
	if(LVCMOS_EN)begin
		PH1P_LOGIC_DPHY_LVCMOS #(
			.DPHY_LOCATION						(DPHY_LOCATION),

			.CK_RX_IOSTANDARD					(CK_RX_IOSTANDARD),
			.L0_RX_IOSTANDARD					(L0_RX_IOSTANDARD),
			.L1_RX_IOSTANDARD					(L1_RX_IOSTANDARD),
			.L2_RX_IOSTANDARD					(L2_RX_IOSTANDARD),
			.L3_RX_IOSTANDARD					(L3_RX_IOSTANDARD),

			.CK_TX_SLEW_RATE					(CK_TX_SLEW_RATE),
			.L0_TX_SLEW_RATE					(L0_TX_SLEW_RATE),
			.L1_TX_SLEW_RATE					(L1_TX_SLEW_RATE),
			.L2_TX_SLEW_RATE					(L2_TX_SLEW_RATE),
			.L3_TX_SLEW_RATE					(L3_TX_SLEW_RATE),

			.CK_TX_DRIVESTRENGTH				(CK_TX_DRIVESTRENGTH),
			.L0_TX_DRIVESTRENGTH				(L0_TX_DRIVESTRENGTH),
			.L1_TX_DRIVESTRENGTH				(L1_TX_DRIVESTRENGTH),
			.L2_TX_DRIVESTRENGTH				(L2_TX_DRIVESTRENGTH),
			.L3_TX_DRIVESTRENGTH				(L3_TX_DRIVESTRENGTH)
		)
		u_PH1P_LOGIC_DPHY_LVCMOS(
			.io_clk_pad_p						(io_clk_pad_p),
			.io_clk_pad_n						(io_clk_pad_n),
			.io_data_pad_p						({io_data_pad3_p,io_data_pad2_p,io_data_pad1_p,io_data_pad0_p}),
			.io_data_pad_n						({io_data_pad3_n,io_data_pad2_n,io_data_pad1_n,io_data_pad0_n}),
			
			.i_ck_lvcmos_tx_en					(i_ck_lvcmos_tx_en_transition),
			.i_ck_p_lvcmos_idelay_value			(i_ck_p_lvcmos_idelay_value_transition),
			.i_ck_p_lvcmos_tx					(i_ck_p_lvcmos_tx_transition),
			.i_ck_n_lvcmos_tx					(i_ck_n_lvcmos_tx_transition),
			.o_ck_p_lvcmos_rx					(o_ck_p_lvcmos_rx),
			.o_ck_n_lvcmos_rx					(o_ck_n_lvcmos_rx),
			
			.i_l0_lvcmos_tx_en					(i_l0_lvcmos_tx_en_transition),
			.i_l0_p_lvcmos_idelay_value			(i_l0_p_lvcmos_idelay_value_transition),
			.i_l0_p_lvcmos_tx					(i_l0_p_lvcmos_tx_transition),
			.i_l0_n_lvcmos_tx					(i_l0_n_lvcmos_tx_transition),
			.o_l0_p_lvcmos_rx					(o_l0_p_lvcmos_rx),
			.o_l0_n_lvcmos_rx					(o_l0_n_lvcmos_rx),

			.i_l1_lvcmos_tx_en					(i_l1_lvcmos_tx_en_transition),
			.i_l1_p_lvcmos_idelay_value			(i_l1_p_lvcmos_idelay_value_transition),
			.i_l1_p_lvcmos_tx					(i_l1_p_lvcmos_tx_transition),
			.i_l1_n_lvcmos_tx					(i_l1_n_lvcmos_tx_transition),
			.o_l1_p_lvcmos_rx					(o_l1_p_lvcmos_rx),
			.o_l1_n_lvcmos_rx					(o_l1_n_lvcmos_rx),

			.i_l2_lvcmos_tx_en					(i_l2_lvcmos_tx_en_transition),
			.i_l2_p_lvcmos_idelay_value			(i_l2_p_lvcmos_idelay_value_transition),
			.i_l2_p_lvcmos_tx					(i_l2_p_lvcmos_tx_transition),
			.i_l2_n_lvcmos_tx					(i_l2_n_lvcmos_tx_transition),
			.o_l2_p_lvcmos_rx					(o_l2_p_lvcmos_rx),
			.o_l2_n_lvcmos_rx					(o_l2_n_lvcmos_rx),
			
			.i_l3_lvcmos_tx_en					(i_l3_lvcmos_tx_en_transition),
			.i_l3_p_lvcmos_idelay_value			(i_l3_p_lvcmos_idelay_value_transition),
			.i_l3_p_lvcmos_tx					(i_l3_p_lvcmos_tx_transition),
			.i_l3_n_lvcmos_tx					(i_l3_n_lvcmos_tx_transition),
			.o_l3_p_lvcmos_rx					(o_l3_p_lvcmos_rx),
			.o_l3_n_lvcmos_rx					(o_l3_n_lvcmos_rx)
		);
	end
	else if(LVDS_TX_EN)begin
		PH1P_LOGIC_DPHY_LVDS_TX #(
			.DPHY_TX_LOCATION					(DPHY_LOCATION),
			.P2S_RATIO							(P2S_RATIO),
			.LVDS_OUTPUT_VCM					(LVDS_OUTPUT_VCM),
			.LVDS_EXTRA_VOD_GAIN				(LVDS_EXTRA_VOD_GAIN),
			.LVDS_OVER_CURRENT_PROTECT			(LVDS_OVER_CURRENT_PROTECT),

			.CK_DE_EMPHASIS						(CK_DE_EMPHASIS),
			.L0_DE_EMPHASIS						(L0_DE_EMPHASIS),
			.L1_DE_EMPHASIS						(L1_DE_EMPHASIS),
			.L2_DE_EMPHASIS						(L2_DE_EMPHASIS),
			.L3_DE_EMPHASIS						(L3_DE_EMPHASIS),

			.CK_LVDS_OUTPUT_VOD					(CK_LVDS_OUTPUT_VOD),
			.L0_LVDS_OUTPUT_VOD					(L0_LVDS_OUTPUT_VOD),
			.L1_LVDS_OUTPUT_VOD					(L1_LVDS_OUTPUT_VOD),
			.L2_LVDS_OUTPUT_VOD					(L2_LVDS_OUTPUT_VOD),
			.L3_LVDS_OUTPUT_VOD					(L3_LVDS_OUTPUT_VOD)
		)
		u_PH1P_LOGIC_DPHY_LVDS_TX(
			.io_clk_pad_p						(io_clk_pad_p),
			.io_clk_pad_n						(io_clk_pad_n),
			.io_data_pad_p						({io_data_pad3_p,io_data_pad2_p,io_data_pad1_p,io_data_pad0_p}),
			.io_data_pad_n						({io_data_pad3_n,io_data_pad2_n,io_data_pad1_n,io_data_pad0_n}),

			.i_phy_dpll_ref_clk					(i_phy_dpll_ref_clk_transition),
			.o_fabric_div5_10_clk				(o_fabric_div5_10_clk),
			.o_fabric_div4_8_clk				(o_fabric_div4_8_clk),
			
			.i_phy_dpll_rst_n					(i_phy_dpll_rst_n),
			.i_phy_dpll_pwdn_n					(i_phy_dpll_pwdn_n),
			.i_phy_dpll_vco_bypass_n			(i_phy_dpll_vco_bypass_n),
			.o_phy_dpll_locked					(o_phy_dpll_locked),
			.i_phy_dpll_multi_ratio				(i_phy_dpll_multi_ratio),
			.i_phy_dpll_div_ratio				(i_phy_dpll_div_ratio),

			.i_phy_rst_n						(i_phy_rst_n),

			.i_ck_tx_en							(i_ck_tx_en),
			.i_ck_odelay_value					(i_ck_odelay_value),
			.i_ck_tx_data						(i_ck_tx_data),

			.i_l0_tx_en							(i_l0_tx_en_transition),
			.i_l0_odelay_value					(i_l0_odelay_value_transition),
			.i_l0_tx_data						(i_l0_tx_data_transition),

			.i_l1_tx_en							(i_l1_tx_en_transition),
			.i_l1_odelay_value					(i_l1_odelay_value_transition),
			.i_l1_tx_data						(i_l1_tx_data_transition),

			.i_l2_tx_en							(i_l2_tx_en_transition),
			.i_l2_odelay_value					(i_l2_odelay_value_transition),
			.i_l2_tx_data						(i_l2_tx_data_transition),

			.i_l3_tx_en							(i_l3_tx_en_transition),
			.i_l3_odelay_value					(i_l3_odelay_value_transition),
			.i_l3_tx_data						(i_l3_tx_data_transition)
		);
	end
	else if(LVDS_RX_EN)begin
		PH1P_LOGIC_DPHY_LVDS_RX #(
			.DPHY_RX_LOCATION					(DPHY_LOCATION),
			.S2P_RATIO							(S2P_RATIO),
			.SAMPLE_CLOCK_SEL					(SAMPLE_CLOCK_SEL),

			.CK_EQUALIZER						(CK_EQUALIZER),
			.L0_EQUALIZER						(L0_EQUALIZER),
			.L1_EQUALIZER						(L1_EQUALIZER),
			.L2_EQUALIZER						(L2_EQUALIZER),
			.L3_EQUALIZER						(L3_EQUALIZER),
			
			.CK_VGA_GAIN						(CK_VGA_GAIN),
			.L0_VGA_GAIN						(L0_VGA_GAIN),
			.L1_VGA_GAIN						(L1_VGA_GAIN),
			.L2_VGA_GAIN						(L2_VGA_GAIN),
			.L3_VGA_GAIN						(L3_VGA_GAIN),

			.CK_IDELAY_ENABLE					(CK_IDELAY_ENABLE),
			.L0_IDELAY_ENABLE					(L0_IDELAY_ENABLE),
			.L1_IDELAY_ENABLE					(L1_IDELAY_ENABLE),
			.L2_IDELAY_ENABLE					(L2_IDELAY_ENABLE),
			.L3_IDELAY_ENABLE					(L3_IDELAY_ENABLE),
			
			.CK_TERMINATOR						(CK_TERMINATOR),
			.L0_TERMINATOR						(L0_TERMINATOR),
			.L1_TERMINATOR						(L1_TERMINATOR),
			.L2_TERMINATOR						(L2_TERMINATOR),
			.L3_TERMINATOR						(L3_TERMINATOR),

			.L0_SLAVE_DESER_CLK_OFFSET			(L0_SLAVE_DESER_CLK_OFFSET),
			.L1_SLAVE_DESER_CLK_OFFSET			(L1_SLAVE_DESER_CLK_OFFSET),
			.L2_SLAVE_DESER_CLK_OFFSET			(L2_SLAVE_DESER_CLK_OFFSET),
			.L3_SLAVE_DESER_CLK_OFFSET			(L3_SLAVE_DESER_CLK_OFFSET),

			.CK_VCM_COMPENSATION				(CK_VCM_COMPENSATION),
			.L0_VCM_COMPENSATION				(L0_VCM_COMPENSATION),
			.L1_VCM_COMPENSATION				(L1_VCM_COMPENSATION),
			.L2_VCM_COMPENSATION				(L2_VCM_COMPENSATION),
			.L3_VCM_COMPENSATION				(L3_VCM_COMPENSATION),

			.CK_DUTY_COMPENSATION				(CK_DUTY_COMPENSATION),
			.L0_DUTY_COMPENSATION				(L0_DUTY_COMPENSATION),
			.L1_DUTY_COMPENSATION				(L1_DUTY_COMPENSATION),
			.L2_DUTY_COMPENSATION				(L2_DUTY_COMPENSATION),
			.L3_DUTY_COMPENSATION				(L3_DUTY_COMPENSATION),
			
			.CK_DUTY_COMPENSATION_POLARITY		(CK_DUTY_COMPENSATION_POLARITY),
			.L0_DUTY_COMPENSATION_POLARITY		(L0_DUTY_COMPENSATION_POLARITY),
			.L1_DUTY_COMPENSATION_POLARITY		(L1_DUTY_COMPENSATION_POLARITY),
			.L2_DUTY_COMPENSATION_POLARITY		(L2_DUTY_COMPENSATION_POLARITY),
			.L3_DUTY_COMPENSATION_POLARITY		(L3_DUTY_COMPENSATION_POLARITY),

			.CK_INTERNAL_AC_CAP_ENABLE			(CK_INTERNAL_AC_CAP_ENABLE),
			.L0_INTERNAL_AC_CAP_ENABLE			(L0_INTERNAL_AC_CAP_ENABLE),
			.L1_INTERNAL_AC_CAP_ENABLE			(L1_INTERNAL_AC_CAP_ENABLE),
			.L2_INTERNAL_AC_CAP_ENABLE			(L2_INTERNAL_AC_CAP_ENABLE),
			.L3_INTERNAL_AC_CAP_ENABLE			(L3_INTERNAL_AC_CAP_ENABLE)

		)
		u_PH1P_LOGIC_DPHY_LVDS_RX(
			.io_clk_pad_p						(io_clk_pad_p),
			.io_clk_pad_n						(io_clk_pad_n),
			.io_data_pad_p						({io_data_pad3_p,io_data_pad2_p,io_data_pad1_p,io_data_pad0_p}),
			.io_data_pad_n						({io_data_pad3_n,io_data_pad2_n,io_data_pad1_n,io_data_pad0_n}),

			.i_pll_to_phy_sample_clk			(i_pll_to_phy_sample_clk_transition),
			.o_phy_to_pll_ref_clk				(o_phy_to_pll_ref_clk),
			.o_fabric_div5_10_clk				(o_fabric_div5_10_clk),
			.o_fabric_div4_8_clk				(o_fabric_div4_8_clk),
			.i_phy_rst_n						(i_phy_rst_n),

			.i_ck_rx_en							(i_ck_rx_en),
			.i_ck_idelay_value					(i_ck_idelay_value),

			.i_l0_rx_en							(i_l0_rx_en_transition),
			.i_l0_slave_deser_clk_en			(i_l0_slave_deser_clk_en_transition),
			.i_l0_idelay_value					(i_l0_idelay_value_transition),
			.o_l0_rx_data						(o_l0_rx_data),
			.o_l0_rx_slave_data					(o_l0_rx_slave_data),

			.i_l1_rx_en							(i_l1_rx_en_transition),
			.i_l1_slave_deser_clk_en			(i_l1_slave_deser_clk_en_transition),
			.i_l1_idelay_value					(i_l1_idelay_value_transition),
			.o_l1_rx_data						(o_l1_rx_data),
			.o_l1_rx_slave_data					(o_l1_rx_slave_data),

			.i_l2_rx_en							(i_l2_rx_en_transition),
			.i_l2_slave_deser_clk_en			(i_l2_slave_deser_clk_en_transition),
			.i_l2_idelay_value					(i_l2_idelay_value_transition),
			.o_l2_rx_data						(o_l2_rx_data),
			.o_l2_rx_slave_data					(o_l2_rx_slave_data),

			.i_l3_rx_en							(i_l3_rx_en_transition),
			.i_l3_slave_deser_clk_en			(i_l3_slave_deser_clk_en_transition),
			.i_l3_idelay_value					(i_l3_idelay_value_transition),
			.o_l3_rx_data						(o_l3_rx_data),
			.o_l3_rx_slave_data					(o_l3_rx_slave_data)
		);
	end
	else if(MIPI_TX_EN)begin
		PH1P_LOGIC_DPHY_MIPI_TX #(
			.DPHY_TX_LOCATION					(DPHY_LOCATION),
			.HS_OUTPUT_IMPEDANCE				(HS_OUTPUT_IMPEDANCE),
			.HS_P2S_RATIO						(HS_P2S_RATIO),
			.HS_OUTPUT_VOD						(HS_OUTPUT_VOD),

			.CK_LP_OUTPUT_IMPEDANCE				(CK_LP_OUTPUT_IMPEDANCE),
			.L0_LP_OUTPUT_IMPEDANCE				(L0_LP_OUTPUT_IMPEDANCE),
			.L1_LP_OUTPUT_IMPEDANCE				(L1_LP_OUTPUT_IMPEDANCE),
			.L2_LP_OUTPUT_IMPEDANCE				(L2_LP_OUTPUT_IMPEDANCE),
			.L3_LP_OUTPUT_IMPEDANCE				(L3_LP_OUTPUT_IMPEDANCE),

			.CK_LP_OUTPUT_SLEW_RATE				(CK_LP_OUTPUT_SLEW_RATE),
			.L0_LP_OUTPUT_SLEW_RATE				(L0_LP_OUTPUT_SLEW_RATE),
			.L1_LP_OUTPUT_SLEW_RATE				(L1_LP_OUTPUT_SLEW_RATE),
			.L2_LP_OUTPUT_SLEW_RATE				(L2_LP_OUTPUT_SLEW_RATE),
			.L3_LP_OUTPUT_SLEW_RATE				(L3_LP_OUTPUT_SLEW_RATE),

			.CK_HS_DE_EMPHASIS					(CK_HS_DE_EMPHASIS),
			.L0_HS_DE_EMPHASIS					(L0_HS_DE_EMPHASIS),
			.L1_HS_DE_EMPHASIS					(L1_HS_DE_EMPHASIS),
			.L2_HS_DE_EMPHASIS					(L2_HS_DE_EMPHASIS),
			.L3_HS_DE_EMPHASIS					(L3_HS_DE_EMPHASIS)
		)
		u_PH1P_LOGIC_DPHY_MIPI_TX(
			.io_clk_pad_p						(io_clk_pad_p),
			.io_clk_pad_n						(io_clk_pad_n),
			.io_data_pad_p						({io_data_pad3_p,io_data_pad2_p,io_data_pad1_p,io_data_pad0_p}),
			.io_data_pad_n						({io_data_pad3_n,io_data_pad2_n,io_data_pad1_n,io_data_pad0_n}),

			.i_phy_dpll_ref_clk					(i_phy_dpll_ref_clk_transition),
			.o_fabric_div4_8_clk				(o_fabric_div4_8_clk),

			.i_phy_dpll_rst_n					(i_phy_dpll_rst_n),
			.i_phy_dpll_pwdn_n					(i_phy_dpll_pwdn_n),
			.i_phy_dpll_vco_bypass_n			(i_phy_dpll_vco_bypass_n),
			.o_phy_dpll_locked					(o_phy_dpll_locked),
			.i_phy_dpll_multi_ratio				(i_phy_dpll_multi_ratio),
			.i_phy_dpll_div_ratio				(i_phy_dpll_div_ratio),

			.i_phy_rst_n						(i_phy_rst_n),
			
			.i_ck_lp_tx_en						(i_ck_lp_tx_en),
			.i_ck_lp_tx_p						(i_ck_lp_tx_p),
			.i_ck_lp_tx_n						(i_ck_lp_tx_n),
			.i_ck_hs_tx_en						(i_ck_hs_tx_en),
			.i_ck_hs_odelay_value				(i_ck_hs_odelay_value),
			.i_ck_hs_tx_data					(i_ck_hs_tx_data),

			.i_l0_lp_tx_en						(i_l0_lp_tx_en_transition),
			.i_l0_lp_tx_p						(i_l0_lp_tx_p_transition),
			.i_l0_lp_tx_n						(i_l0_lp_tx_n_transition),
			.o_l0_lp_rx_p						(o_l0_lp_rx_p),
			.o_l0_lp_rx_n						(o_l0_lp_rx_n),
			.i_l0_hs_tx_en						(i_l0_hs_tx_en_transition),
			.i_l0_hs_odelay_value				(i_l0_hs_odelay_value_transition),
			.i_l0_hs_tx_data					(i_l0_hs_tx_data_transition),

			.i_l1_lp_tx_en						(i_l1_lp_tx_en_transition),
			.i_l1_lp_tx_p						(i_l1_lp_tx_p_transition),
			.i_l1_lp_tx_n						(i_l1_lp_tx_n_transition),
			.o_l1_lp_rx_p						(o_l1_lp_rx_p),
			.o_l1_lp_rx_n						(o_l1_lp_rx_n),
			.i_l1_hs_tx_en						(i_l1_hs_tx_en_transition),
			.i_l1_hs_odelay_value				(i_l1_hs_odelay_value_transition),
			.i_l1_hs_tx_data					(i_l1_hs_tx_data_transition),

			.i_l2_lp_tx_en						(i_l2_lp_tx_en_transition),
			.i_l2_lp_tx_p						(i_l2_lp_tx_p_transition),
			.i_l2_lp_tx_n						(i_l2_lp_tx_n_transition),
			.o_l2_lp_rx_p						(o_l2_lp_rx_p),
			.o_l2_lp_rx_n						(o_l2_lp_rx_n),
			.i_l2_hs_tx_en						(i_l2_hs_tx_en_transition),
			.i_l2_hs_odelay_value				(i_l2_hs_odelay_value_transition),
			.i_l2_hs_tx_data					(i_l2_hs_tx_data_transition),

			.i_l3_lp_tx_en						(i_l3_lp_tx_en_transition),
			.i_l3_lp_tx_p						(i_l3_lp_tx_p_transition),
			.i_l3_lp_tx_n						(i_l3_lp_tx_n_transition),
			.o_l3_lp_rx_p						(o_l3_lp_rx_p),
			.o_l3_lp_rx_n						(o_l3_lp_rx_n),
			.i_l3_hs_tx_en						(i_l3_hs_tx_en_transition),
			.i_l3_hs_odelay_value				(i_l3_hs_odelay_value_transition),
			.i_l3_hs_tx_data					(i_l3_hs_tx_data_transition)
		);				
	end
	else if(MIPI_RX_EN)begin
		PH1P_LOGIC_DPHY_MIPI_RX #(
			.DPHY_RX_LOCATION					(DPHY_LOCATION),
			.HS_S2P_RATIO						(HS_S2P_RATIO),

			.CK_HS_EQUALIZER					(CK_HS_EQUALIZER),
			.L0_HS_EQUALIZER					(L0_HS_EQUALIZER),
			.L1_HS_EQUALIZER					(L1_HS_EQUALIZER),
			.L2_HS_EQUALIZER					(L2_HS_EQUALIZER),
			.L3_HS_EQUALIZER					(L3_HS_EQUALIZER),

			.CK_HS_VGA_GAIN						(CK_HS_VGA_GAIN),
			.L0_HS_VGA_GAIN						(L0_HS_VGA_GAIN),
			.L1_HS_VGA_GAIN						(L1_HS_VGA_GAIN),
			.L2_HS_VGA_GAIN						(L2_HS_VGA_GAIN),
			.L3_HS_VGA_GAIN						(L3_HS_VGA_GAIN),

			.L0_HS_SLAVE_DESER_CLK_OFFSET		(L0_HS_SLAVE_DESER_CLK_OFFSET),
			.L1_HS_SLAVE_DESER_CLK_OFFSET		(L1_HS_SLAVE_DESER_CLK_OFFSET),
			.L2_HS_SLAVE_DESER_CLK_OFFSET		(L2_HS_SLAVE_DESER_CLK_OFFSET),
			.L3_HS_SLAVE_DESER_CLK_OFFSET		(L3_HS_SLAVE_DESER_CLK_OFFSET)
		)
		u_PH1P_LOGIC_DPHY_MIPI_RX(
			.io_clk_pad_p						(io_clk_pad_p),
			.io_clk_pad_n						(io_clk_pad_n),
			.io_data_pad_p						({io_data_pad3_p,io_data_pad2_p,io_data_pad1_p,io_data_pad0_p}),
			.io_data_pad_n						({io_data_pad3_n,io_data_pad2_n,io_data_pad1_n,io_data_pad0_n}),

			.o_fabric_div4_8_clk				(o_fabric_div4_8_clk),
			.i_phy_rst_n						(i_phy_rst_n),

			.i_ck_lp_rx_en						(i_ck_lp_rx_en),
			.o_ck_lp_rx_p						(o_ck_lp_rx_p),
			.o_ck_lp_rx_n						(o_ck_lp_rx_n),
			.i_ck_hs_rx_en						(i_ck_hs_rx_en),
			.i_ck_hs_terminator_sel				(i_ck_hs_terminator_sel),
			.i_ck_hs_idelay_en					(i_ck_hs_idelay_en),
			.i_ck_hs_idelay_value				(i_ck_hs_idelay_value),

			.i_l0_lp_rx_en						(i_l0_lp_rx_en_transition),
			.i_l0_lp_tx_en						(i_l0_lp_tx_en_transition),
			.o_l0_lp_rx_p						(o_l0_lp_rx_p),
			.o_l0_lp_rx_n						(o_l0_lp_rx_n),
			.i_l0_lp_tx_p						(i_l0_lp_tx_p_transition),
			.i_l0_lp_tx_n						(i_l0_lp_tx_n_transition),
			.i_l0_hs_rx_en						(i_l0_hs_rx_en_transition),
			.i_l0_hs_terminator_sel				(i_l0_hs_terminator_sel_transition),
			.i_l0_hs_slave_deser_clk_en			(i_l0_hs_slave_deser_clk_en_transition),
			.i_l0_hs_idelay_en					(i_l0_hs_idelay_en_transition),
			.i_l0_hs_idelay_value				(i_l0_hs_idelay_value_transition),
			.o_l0_hs_rx_data					(o_l0_hs_rx_data),
			.o_l0_hs_rx_slave_data				(o_l0_hs_rx_slave_data),

			.i_l1_lp_rx_en						(i_l1_lp_rx_en_transition),
			.i_l1_lp_tx_en						(i_l1_lp_tx_en_transition),
			.o_l1_lp_rx_p						(o_l1_lp_rx_p),
			.o_l1_lp_rx_n						(o_l1_lp_rx_n),
			.i_l1_lp_tx_p						(i_l1_lp_tx_p_transition),
			.i_l1_lp_tx_n						(i_l1_lp_tx_n_transition),
			.i_l1_hs_rx_en						(i_l1_hs_rx_en_transition),
			.i_l1_hs_terminator_sel				(i_l1_hs_terminator_sel_transition),
			.i_l1_hs_slave_deser_clk_en			(i_l1_hs_slave_deser_clk_en_transition),
			.i_l1_hs_idelay_en					(i_l1_hs_idelay_en_transition),
			.i_l1_hs_idelay_value				(i_l1_hs_idelay_value_transition),
			.o_l1_hs_rx_data					(o_l1_hs_rx_data),
			.o_l1_hs_rx_slave_data				(o_l1_hs_rx_slave_data),

			.i_l2_lp_rx_en						(i_l2_lp_rx_en_transition),
			.i_l2_lp_tx_en						(i_l2_lp_tx_en_transition),
			.o_l2_lp_rx_p						(o_l2_lp_rx_p),
			.o_l2_lp_rx_n						(o_l2_lp_rx_n),
			.i_l2_lp_tx_p						(i_l2_lp_tx_p_transition),
			.i_l2_lp_tx_n						(i_l2_lp_tx_n_transition),
			.i_l2_hs_rx_en						(i_l2_hs_rx_en_transition),
			.i_l2_hs_terminator_sel				(i_l2_hs_terminator_sel_transition),
			.i_l2_hs_slave_deser_clk_en			(i_l2_hs_slave_deser_clk_en_transition),
			.i_l2_hs_idelay_en					(i_l2_hs_idelay_en_transition),
			.i_l2_hs_idelay_value				(i_l2_hs_idelay_value_transition),
			.o_l2_hs_rx_data					(o_l2_hs_rx_data),
			.o_l2_hs_rx_slave_data				(o_l2_hs_rx_slave_data),

			.i_l3_lp_rx_en						(i_l3_lp_rx_en_transition),
			.i_l3_lp_tx_en						(i_l3_lp_tx_en_transition),
			.o_l3_lp_rx_p						(o_l3_lp_rx_p),
			.o_l3_lp_rx_n						(o_l3_lp_rx_n),
			.i_l3_lp_tx_p						(i_l3_lp_tx_p_transition),
			.i_l3_lp_tx_n						(i_l3_lp_tx_n_transition),
			.i_l3_hs_rx_en						(i_l3_hs_rx_en_transition),
			.i_l3_hs_terminator_sel				(i_l3_hs_terminator_sel_transition),
			.i_l3_hs_slave_deser_clk_en			(i_l3_hs_slave_deser_clk_en_transition),
			.i_l3_hs_idelay_en					(i_l3_hs_idelay_en_transition),
			.i_l3_hs_idelay_value				(i_l3_hs_idelay_value_transition),
			.o_l3_hs_rx_data					(o_l3_hs_rx_data),
			.o_l3_hs_rx_slave_data				(o_l3_hs_rx_slave_data)
		);
		
	end
endgenerate

endmodule



