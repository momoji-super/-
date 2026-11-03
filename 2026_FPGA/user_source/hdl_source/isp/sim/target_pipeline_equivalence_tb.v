`timescale 1ns/1ps
// Red tracker and frame toggle match the prior detector (+2 clocks).
// Motion now has its own noise/stability behavioral regression.
// Exercises continuous frames, stalled beats, random red/luma and tied peaks.
module target_pipeline_equivalence_tb;
    reg clk=0,rst_n=0;
    reg [95:0] rgb=0,red=0;
    reg valid=0,user=0,last=0;
    wire [124:0] ref_out,new_out;
    reg [124:0] delay0=0,delay1=0;
    integer f,x,y,lane,seed=712,cycles=0;
    always #5 clk=~clk;
    target_detect_track_before #(.IMG_WIDTH(64),.IMG_HEIGHT(32)) ref_dut(
        clk,rst_n,rgb,red,valid,user,last,
        ref_out[124],ref_out[123],ref_out[122:112],ref_out[111:101],
        ref_out[100:90],ref_out[89:79],ref_out[78:68],ref_out[67:57],
        ref_out[56:45],ref_out[44],ref_out[43:33],ref_out[32:22],ref_out[21:11],ref_out[10:0]);
    target_detect_track #(.IMG_WIDTH(64),.IMG_HEIGHT(32)) dut(
        clk,rst_n,rgb,red,valid,user,last,
        new_out[124],new_out[123],new_out[122:112],new_out[111:101],
        new_out[100:90],new_out[89:79],new_out[78:68],new_out[67:57],
        new_out[56:45],new_out[44],new_out[43:33],new_out[32:22],new_out[21:11],new_out[10:0]);
    always @(posedge clk) begin
        delay0<=ref_out;delay1<=delay0;
        #1;
        if(rst_n) begin
            cycles=cycles+1;
            if(cycles>4 && new_out[124:57]!==delay1[124:57])
                $fatal(1,"Pipeline changed output at cycle %0d: %h != %h",cycles,new_out,delay1);
        end
    end
    initial begin
        repeat(4) @(negedge clk);rst_n=1;
        for(f=0;f<24;f=f+1) begin
            for(y=0;y<32;y=y+1) for(x=0;x<64;x=x+4) begin
                if(f%3==1 && x%12==0) begin
                    @(negedge clk);valid=0;user=0;last=0;
                end
                @(negedge clk);valid=1;user=(x==0&&y==0);last=(x==60);
                for(lane=0;lane<4;lane=lane+1) begin
                    rgb[lane*24+:24]=$random(seed);
                    red[lane*24+:24]=(f%4==0)?24'hf00000:$random(seed);
                end
            end
        end
        @(negedge clk);valid=0;user=0;last=0;
        repeat(12) @(negedge clk);
        $display("PASS target_pipeline_equivalence_tb: 24 frames, red tracker/frame toggle identical (+2 cycles)");
        $finish;
    end
    initial begin #2000000;$fatal(1,"watchdog");end
endmodule
