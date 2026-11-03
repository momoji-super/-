`timescale 1ns/1ps
module hand_temporal_vote_tb;
    reg clk=0,rst_n=0,done=0,result_valid=1,present=1;
    reg [3:0] raw_count=0;
    reg [7:0] palm_x=80,palm_y=48;
    wire [3:0] count,support;
    wire display_valid;
    integer i;
    always #5 clk=~clk;
    hand_temporal_vote dut(.clk(clk),.rst_n(rst_n),.done(done),
        .result_valid(result_valid),.present(present),.raw_count(raw_count),
        .palm_x(palm_x),.palm_y(palm_y),.count(count),
        .display_valid(display_valid),.support(support));
    task observation;
        input integer value;
        begin
            @(negedge clk);
            result_valid=(value!=-2);present=(value!=-1);
            raw_count=(value<0)?0:value;done=1;
            @(negedge clk);done=0;
            repeat(12) @(negedge clk);
        end
    endtask
    task expect_count;
        input integer value;
        begin
            if(!display_valid || count!=value)
                $fatal(1,"expected %0d, actual %0d valid=%b",value,count,display_valid);
        end
    endtask
    initial begin
        repeat(3) @(negedge clk);rst_n=1;
        for(i=0;i<4;i=i+1) begin
            observation(4);
            if(display_valid) $fatal(1,"early acquisition");
        end
        observation(4);expect_count(4);
        // Reported field symptom: 4/3 fluctuation over an extended interval.
        for(i=0;i<48;i=i+1) begin
            observation((i%2)?4:3);expect_count(4);
        end
        // A 5/8 weak majority for 3 must not displace a locked 4.
        for(i=0;i<40;i=i+1) begin
            observation((i%8<5)?3:4);expect_count(4);
        end
        for(i=0;i<8;i=i+1) observation(4);
        for(i=0;i<6;i=i+1) begin observation(3);expect_count(4);end
        observation(3);expect_count(4); // 7/8: first confirmation only.
        observation(3);expect_count(3); // 8/8: real changed gesture accepted.
        for(i=0;i<8;i=i+1) observation(4);
        expect_count(4);
        observation(-1);expect_count(4);
        observation(-1);expect_count(4);
        observation(4);expect_count(4); // Recovery cancels absence streak.
        observation(-1);observation(-1);observation(-1);expect_count(0);
        for(i=0;i<4;i=i+1) begin
            observation(3);expect_count(0);
        end
        observation(3);expect_count(3);
        for(i=0;i<5;i=i+1) begin observation(-2);expect_count(3);end
        observation(-2);
        if(display_valid) $fatal(1,"stale display after invalid timeout");
        for(i=0;i<5;i=i+1) observation(4);
        expect_count(4);
        palm_x=120;observation(3);
        if(display_valid) $fatal(1,"large move must discard old gesture");
        for(i=0;i<4;i=i+1) observation(3);
        expect_count(3);
        // Fist is a valid zero gesture, distinct from absent or invalid input.
        for(i=0;i<8;i=i+1) observation(0);
        expect_count(0);
        for(i=0;i<8;i=i+1) observation(5);
        expect_count(5);
        rst_n=0;repeat(3) @(negedge clk);rst_n=1;
        if(display_valid) $fatal(1,"reset must release lock");
        // Invalid frames cannot accumulate a stale acquisition majority.
        for(i=0;i<4;i=i+1) observation(4);
        for(i=0;i<5;i=i+1) observation(-2);
        observation(4);
        if(display_valid) $fatal(1,"invalid observations failed to age votes");
        $display("PASS hand_temporal_vote_tb: jitter, weak majorities, true changes, absence, invalid aging, movement, reset");
        $finish;
    end
    initial begin #1000000;$fatal(1,"watchdog");end
endmodule
