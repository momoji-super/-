`timescale 1ns/1ps

module histogram_equalizer_tb;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg tuser = 1'b0;
    reg sample_valid = 1'b0;
    reg [7:0] sample_luma = 8'd0;
    reg [31:0] map_luma = {8'd192, 8'd128, 8'd64, 8'd0};
    wire [31:0] equalized_luma;

    always #5 clk = ~clk;

    histogram_equalizer #(
        .IMG_WIDTH(32),
        .IMG_HEIGHT(16)
    ) dut (
        .I_clk(clk),
        .I_rst_n(rst_n),
        .I_tuser(tuser),
        .I_sample_valid(sample_valid),
        .I_sample_luma(sample_luma),
        .I_map_luma(map_luma),
        .O_equalized_luma(equalized_luma)
    );

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        tuser = 1'b1;
        sample_valid = 1'b1;
        sample_luma = 8'd64;
        @(negedge clk);
        tuser = 1'b0;
        sample_luma = 8'd192;
        @(negedge clk);
        sample_valid = 1'b0;
        @(negedge clk);
        tuser = 1'b1;
        @(negedge clk);
        tuser = 1'b0;

        repeat (1800) @(posedge clk);
        @(negedge clk);
        tuser = 1'b1;
        @(negedge clk);
        tuser = 1'b0;
        #1;
        if (equalized_luma[7:0] !== 8'd0 ||
            equalized_luma[15:8] !== 8'd0 ||
            equalized_luma[23:16] !== 8'd0 ||
            equalized_luma[31:24] !== 8'd255)
            $fatal(1, "CDFmin equalization did not stretch a two-point histogram");

        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        map_luma = {8'd128, 8'd128, 8'd128, 8'd128};
        @(negedge clk);
        tuser = 1'b1;
        sample_valid = 1'b1;
        sample_luma = 8'd128;
        @(negedge clk);
        tuser = 1'b0;
        sample_luma = 8'd128;
        @(negedge clk);
        sample_valid = 1'b0;
        tuser = 1'b1;
        @(negedge clk);
        tuser = 1'b0;
        repeat (1800) @(posedge clk);
        @(negedge clk);
        tuser = 1'b1;
        @(negedge clk);
        tuser = 1'b0;
        #1;
        if (equalized_luma[7:0] !== 8'd128 ||
            equalized_luma[15:8] !== 8'd128 ||
            equalized_luma[23:16] !== 8'd128 ||
            equalized_luma[31:24] !== 8'd128)
            $fatal(1, "Constant-luma frame did not fall back to identity mapping");

        $display("PASS histogram_equalizer CDFmin, flat-field fallback and atomic LUT apply");
        $finish;
    end
endmodule
