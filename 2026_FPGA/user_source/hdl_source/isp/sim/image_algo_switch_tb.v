`timescale 1ns/1ps

module image_algo_switch_tb;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg [95:0] tdata = 96'd0;
    reg tvalid = 1'b0;
    reg tuser = 1'b0;
    reg tlast = 1'b0;
    reg [2:0] mode = 3'd0;
    reg [7:0] threshold = 8'd128;
    reg vivid_enable = 1'b1;
    wire [95:0] out_data;
    wire out_valid;
    wire out_user;
    wire out_last;

    always #5 clk = ~clk;

    image_algo_switch dut (
        .I_clk(clk),
        .I_rst_n(rst_n),
        .I_tdata(tdata),
        .I_tvalid(tvalid),
        .I_tuser(tuser),
        .I_tlast(tlast),
        .I_tready(),
        .O_tdata(out_data),
        .O_tvalid(out_valid),
        .O_tuser(out_user),
        .O_tlast(out_last),
        .I_algo_mode(mode),
        .I_threshold(threshold),
        .I_vivid_enable(vivid_enable)
    );

    task send_beat;
        input [95:0] data;
        input valid;
        input user;
        input last;
        begin
            @(negedge clk);
            tdata = data;
            tvalid = valid;
            tuser = user;
            tlast = last;
            @(posedge clk);
            #1;
        end
    endtask

    task expect_beat;
        input [95:0] data;
        input valid;
        input user;
        input last;
        begin
            // All modes now have four register stages (three extra edges).
            @(negedge clk);
            tvalid = 0; tuser = 0; tlast = 0;
            repeat (3) begin @(posedge clk); #1; end
            if (out_data !== data || out_valid !== valid ||
                out_user !== user || out_last !== last) begin
                $display("FAIL got data=%h valid=%b user=%b last=%b",
                         out_data, out_valid, out_user, out_last);
                $display("     exp data=%h valid=%b user=%b last=%b",
                         data, valid, user, last);
                $fatal(1);
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        mode = 3'd0;
        send_beat({24'h123456, 24'habcdef, 24'h0080ff, 24'hffffff},
                  1'b1, 1'b1, 1'b0);
        expect_beat({24'h0e345b, 24'ha7cdf4, 24'h0083ff, 24'hffffff},
                    1'b1, 1'b1, 1'b0);

        mode = 3'd1;
        send_beat({24'hff0000, 24'h00ff00, 24'h0000ff, 24'h808080},
                  1'b1, 1'b1, 1'b0);
        expect_beat({24'h4c4c4c, 24'h959595, 24'h1c1c1c, 24'h808080},
                    1'b1, 1'b1, 1'b0);

        mode = 3'd2;
        send_beat({24'hff0000, 24'h00ff00, 24'h0000ff, 24'h808080},
                  1'b1, 1'b0, 1'b1);
        expect_beat({24'h4c4c4c, 24'h959595, 24'h1c1c1c, 24'h808080},
                    1'b1, 1'b0, 1'b1);

        send_beat({24'hffffff, 24'h000000, 24'h808080, 24'hff0000},
                  1'b1, 1'b1, 1'b0);
        expect_beat({24'hffffff, 24'h000000, 24'hffffff, 24'h000000},
                    1'b1, 1'b1, 1'b0);

        mode = 3'd3;
        send_beat({24'h123456, 24'habcdef, 24'h0080ff, 24'hffffff},
                  1'b1, 1'b1, 1'b0);
        expect_beat({24'hedcba9, 24'h543210, 24'hff7f00, 24'h000000},
                    1'b1, 1'b1, 1'b0);

        mode = 3'd4;
        send_beat({24'hff0000, 24'h20ff00, 24'h00ff00, 24'h404040},
                  1'b1, 1'b1, 1'b1);
        expect_beat({24'hff0000, 24'h9f9f9f, 24'h959595, 24'h404040},
                    1'b1, 1'b1, 1'b1);

        send_beat(96'd0, 1'b0, 1'b0, 1'b0);
        expect_beat({24'hff0000, 24'h9f9f9f, 24'h959595, 24'h404040},
                    1'b0, 1'b0, 1'b0);

        mode = 3'd7;
        send_beat({24'hff0000, 24'h00ff00, 24'h0000ff, 24'h808080},
                  1'b1, 1'b1, 1'b0);
        expect_beat({24'h4c4c4c, 24'h959595, 24'h1c1c1c, 24'h808080},
                    1'b1, 1'b1, 1'b0);

        $display("PASS image_algo_switch");
        $finish;
    end
endmodule
