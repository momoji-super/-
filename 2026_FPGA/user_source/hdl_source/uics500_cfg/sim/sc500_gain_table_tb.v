`timescale 1ns/1ps
module sc500_gain_table_tb;
    reg clk=0;
    reg rst_n=1;
    reg [6:0] index=0;
    wire [15:0] gain;
    always #5 clk=~clk;

    SC500GainTbl dut(.I_clk(clk),.I_rstn(rst_n),.I(index),.O(gain));

    task check;
        input [6:0] i;
        input [15:0] expected;
        begin
            @(negedge clk); index=i;
            @(negedge clk);
            if(gain!==expected) $fatal(1,"index %0d expected %h got %h",i,expected,gain);
        end
    endtask

    initial begin
        check(0,16'h0320);
        check(31,16'h033f);
        check(32,16'h0720);
        check(48,16'h0730);
        check(63,16'h073f);
        check(64,16'h0f20);
        check(73,16'h0f29);
        check(74,16'h0f2a);
        check(80,16'h0f30);
        check(95,16'h0f3f);
        check(96,16'h1f20);
        check(124,16'h1f3c);
        check(127,16'h1f3f);
        $display("PASS SC500 analog-gain table through 15x and sensor table ceiling");
        $finish;
    end
endmodule
