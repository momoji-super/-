`timescale 1ns/1ps

module w128_d512_fifo (
    input wire rst, clkw, clkr, we, re,
    input wire [127:0] di,
    output wire afull, full_flag,
    output wire [9:0] wrusedw,
    output wire [127:0] dout,
    output wire [8:0] rdusedw,
    output wire valid, empty_flag, aempty
);
    assign afull = 1'b0;
    assign full_flag = 1'b0;
    assign wrusedw = 10'd0;
    assign dout = 128'd0;
    assign rdusedw = 9'd0;
    assign valid = 1'b0;
    assign empty_flag = 1'b1;
    assign aempty = 1'b1;
endmodule

module video_frame_id_tb;
    reg rst_n = 1'b0;
    reg camera_clk = 1'b0;
    reg ddr_clk = 1'b0;
    reg camera_frame_start = 1'b0;
    wire [15:0] capture_frame_id;
    wire [15:0] display_frame_id;
    wire frame_id_toggle;
    wire [1:0] read_pointer;

    always #5 camera_clk = ~camera_clk;
    always #7 ddr_clk = ~ddr_clk;

    video_in dut (
        .I_rst_n(rst_n),
        .I_camera_clk(camera_clk),
        .I_camera_frame_start(camera_frame_start),
        .I_camera_valid(1'b0),
        .I_camera_data(128'd0),
        .I_mipi_rx_error(1'b0),
        .I_ddr_clk(ddr_clk),
        .I_display_pause(1'b0),
        .I_video_out_rd_busy(1'b0),
        .O_video_in_wr_busy(),
        .O_video_out_rp(read_pointer),
        .O_capture_frame_id(capture_frame_id),
        .O_display_frame_id(display_frame_id),
        .O_frame_id_toggle(frame_id_toggle),
        .O_ddr_user_wr_en(),
        .O_ddr_user_addr(),
        .O_ddr_user_wr_data(),
        .I_ddr_user_ready(1'b0)
    );

    task capture_frame;
        input [15:0] expected_capture_id;
        input [15:0] expected_display_id;
        input [1:0] expected_read_pointer;
        begin
            @(negedge camera_clk);
            camera_frame_start = 1'b1;
            repeat (2) @(negedge camera_clk);
            camera_frame_start = 1'b0;
            repeat (10) @(posedge ddr_clk);
            #1;
            if (capture_frame_id !== expected_capture_id ||
                display_frame_id !== expected_display_id ||
                read_pointer !== expected_read_pointer) begin
                $display("got capture=%0d display=%0d rp=%0d expected=%0d/%0d/%0d",
                    capture_frame_id, display_frame_id, read_pointer,
                    expected_capture_id, expected_display_id, expected_read_pointer);
                $fatal(1, "Frame ID did not follow DDR ring-buffer slot selection");
            end
        end
    endtask

    initial begin
        repeat (4) @(posedge ddr_clk);
        rst_n = 1'b1;
        capture_frame(16'd1, 16'd0, 2'd2);
        capture_frame(16'd2, 16'd0, 2'd3);
        capture_frame(16'd3, 16'd1, 2'd0);
        capture_frame(16'd4, 16'd2, 2'd1);
        capture_frame(16'd5, 16'd3, 2'd2);
        $display("PASS video_in capture/display frame IDs match ring-buffer slots");
        $finish;
    end
endmodule
