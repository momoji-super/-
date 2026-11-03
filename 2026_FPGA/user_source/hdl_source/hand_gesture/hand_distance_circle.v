// Full-frame 3/4 chamfer distance transform + multi-radius angular arcs.
// No frame-wide reset loops, no floating point, atan2, sqrt or variable divider.
// The mask read interface has ONE registered read clock of latency.
module hand_distance_circle #(
    parameter WIDTH=160, HEIGHT=90, SIZE=WIDTH*HEIGHT,
    parameter MIN_AREA=100, MIN_RADIUS=5, MAX_RADIUS=24,
    parameter ANGLES=128, MIN_ARC=3, MAX_ARC=24, MERGE_BINS=4,
    parameter MIN_WRIST_CONTACT=3, REQUIRE_WRIST=1,
    parameter MIN_EXTENSION_EIGHTHS=15
)(
    input wire clk,rst_n,start, input wire [3:0] capture_error,
    output reg [15:0] mask_addr, input wire mask_skin,
    output reg busy,done,result_valid,present,
    output reg [3:0] count,error,
    output reg [7:0] palm_x,palm_y,palm_radius,wrist_x,wrist_y,
    output reg [6:0] tip0,tip1,tip2,tip3,tip4
);
    localparam IDLE=0,INIT_REQ=1,INIT_WAIT=2,INIT_GET=3,
        DT_REQ=4,DT_WAIT=5,DT_GET=6,DT_WRITE=7,DT_ADV=8,
        PALM=9,WRIST=10,CIRCLE_REQ=11,CIRCLE_WAIT=12,CIRCLE_GET=13,
        FIND_ZERO=14,ARC_SCAN=15,ARC_END=16,NEXT_RING=17,FINISH=18,CIRCLE_MATH=19,CIRCLE_POS=20,
        REMOVE_START=21,REMOVE_FWD=22,REMOVE_BACK=23,REMOVE_NEXT=24,
        FILTER_RING=25,FILTER_COMMIT=26;
    reg [4:0] state;
    localparam MEM_ADDR_WIDTH = $clog2(SIZE);
    // TD's native block-RAM directive; full 16-bit ports otherwise expand
    // this memory and can cause it to be mapped to distributed RAM.
    (* ram_style="bram" *) reg [7:0] distance_mem [0:SIZE-1];
    reg [15:0] dt_addr,dt_write_addr;
    reg [7:0] dt_q,dt_write_data;
    reg dt_we;
    always @(posedge clk) begin
        dt_q<=distance_mem[dt_addr[MEM_ADDR_WIDTH-1:0]];
        if(dt_we) distance_mem[dt_write_addr[MEM_ADDR_WIDTH-1:0]]<=dt_write_data;
    end
    reg [15:0] index,skin_total;
    reg [7:0] px,py,best_distance,best_x,best_y,best_cost;
    reg backwards;
    reg [2:0] neighbor;
    reg [7:0] local_min;
    reg [15:0] contacts [0:3];
    reg [7:0] edge_min [0:3],edge_max [0:3];
    reg [1:0] wrist_side;
    reg have_wrist;
    reg signed [9:0] wrist_dx,wrist_dy;
    integer j,chosen,chosen_votes;
    reg [8:0] midpoint;
    wire border=(px==0)||(py==0)||(px==WIDTH-1)||(py==HEIGHT-1);
    wire palm_roi=(px>=WIDTH/8)&&(px<WIDTH-WIDTH/8)
                 &&(py>=HEIGHT/8)&&(py<HEIGHT-HEIGHT/8);
    wire [8:0] central_cost=((px>WIDTH/2)?px-WIDTH/2:WIDTH/2-px)
                           +((py>HEIGHT/2)?py-HEIGHT/2:HEIGHT/2-py);
    function [7:0] sat_add;
        input [7:0] value; input [2:0] cost;
        reg [8:0] sum;
        begin sum={1'b0,value}+cost; sat_add=sum[8]?8'hff:sum[7:0]; end
    endfunction
    wire [2:0] neighbor_cost=(neighbor==2||neighbor==4)?3'd4:3'd3;
    wire [7:0] candidate=sat_add(dt_q,neighbor_cost);
    wire [7:0] merged_min=(candidate<local_min)?candidate:local_min;

    reg [1:0] ring;
    reg [6:0] angle;
    wire signed [9:0] cosine,sine;
    hand_angle_lut u_angle(.angle(angle),.cosine(cosine),.sine(sine));
    wire [8:0] radial_distance=(ring==0)?({1'b0,palm_radius}<<1):
                               (ring==1)?(({1'b0,palm_radius}*MIN_EXTENSION_EIGHTHS)>>3):
                                         (({1'b0,palm_radius}*3)>>1);
    wire signed [9:0] signed_radius=$signed({1'b0,radial_distance});
    wire signed [19:0] product_x=cosine*signed_radius;
    wire signed [19:0] product_y=sine*signed_radius;
    reg signed [19:0] prod_x_hold,prod_y_hold,pos_x_hold,pos_y_hold;
    reg signed [20:0] dot_hold,cross_hold;
    reg arm_hold;
    wire signed [19:0] circle_x=$signed({1'b0,palm_x})+((prod_x_hold+20'sd128)>>>8);
    wire signed [19:0] circle_y=$signed({1'b0,palm_y})+((prod_y_hold+20'sd128)>>>8);
    wire in_image=(pos_x_hold>=0)&&(pos_x_hold<WIDTH)&&(pos_y_hold>=0)&&(pos_y_hold<HEIGHT);
    wire signed [19:0] dot_x=cosine*wrist_dx,dot_y=sine*wrist_dy;
    wire signed [19:0] cross_x=cosine*wrist_dy,cross_y=sine*wrist_dx;
    wire signed [20:0] dot=$signed(dot_x)+$signed(dot_y);
    wire signed [20:0] cross_value=$signed(cross_x)-$signed(cross_y);
    wire [20:0] cross_abs=cross_hold[20]?-cross_hold:cross_hold;
    // Use the wrist direction only to seed the actual connected white arc.
    // A fixed cone can split a wide wrist into two false finger candidates.
    wire arm_angle=have_wrist && (dot_hold>0) && (cross_abs<=$unsigned(dot_hold));
    reg take_sample;
    reg [127:0] ring_bits [0:2];
    reg [127:0] filtered_ring;
    wire [6:0] angle_before=angle-7'd1,angle_after=angle+7'd1;
    wire ring_left=ring_bits[ring][angle_before];
    wire ring_middle=ring_bits[ring][angle];
    wire ring_right=ring_bits[ring][angle_after];
    reg [6:0] arm_seed [0:2];
    reg signed [20:0] arm_score [0:2];
    reg arm_found [0:2];
    reg [6:0] remove_angle;
    reg [7:0] remove_trials;
    reg [7:0] zero_trials,remaining,run_length;
    reg [6:0] scan_angle,run_start,arc_center;
    wire [6:0] inner_before=arc_center-7'd1,inner_after=arc_center+7'd1;
    wire [6:0] inner_before2=arc_center-7'd2,inner_after2=arc_center+7'd2;
    // A radial finger should also intersect the inner circle near its angle.
    // Reject detached outer specks instead of adding them to the finger union.
    wire inner_supported=ring_bits[2][arc_center] || ring_bits[2][inner_before] ||
                         ring_bits[2][inner_after] || ring_bits[2][inner_before2] ||
                         ring_bits[2][inner_after2];
    reg in_run,last_scan;
    reg [3:0] peak_count;
    reg [3:0] prior_peak_count;
    reg [6:0] peaks [0:5];
    reg duplicate;
    integer separation,allowed;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            prod_x_hold<=0;prod_y_hold<=0;pos_x_hold<=0;pos_y_hold<=0;dot_hold<=0;cross_hold<=0;arm_hold<=0;
            state<=IDLE; mask_addr<=0; dt_addr<=0;dt_write_addr<=0;dt_write_data<=0;dt_we<=0;
            busy<=0;done<=0;result_valid<=0;present<=0;count<=0;error<=0;
            palm_x<=0;palm_y<=0;palm_radius<=0;wrist_x<=0;wrist_y<=0;
            tip0<=0;tip1<=0;tip2<=0;tip3<=0;tip4<=0;
            index<=0;px<=0;py<=0;skin_total<=0;
            best_distance<=0;best_x<=0;best_y<=0;best_cost<=255;
            backwards<=0;neighbor<=0;local_min<=0;
            ring<=0;angle<=0;take_sample<=0;wrist_side<=0;have_wrist<=0;wrist_dx<=0;wrist_dy<=0;
            filtered_ring<=0;
            zero_trials<=0;remaining<=0;scan_angle<=0;run_start<=0;arc_center<=0;
            in_run<=0;run_length<=0;last_scan<=0;peak_count<=0;
            for(j=0;j<4;j=j+1) begin contacts[j]<=0;edge_min[j]<=255;edge_max[j]<=0; end
            remove_angle<=0;remove_trials<=0;prior_peak_count<=0;
            for(j=0;j<3;j=j+1) begin ring_bits[j]<=0;arm_seed[j]<=0;arm_score[j]<=0;arm_found[j]<=0;end
            for(j=0;j<6;j=j+1) peaks[j]<=0;
        end else begin
            done<=0;dt_we<=0;
            case(state)
            IDLE: if(start) begin
                busy<=1;result_valid<=0;present<=0;count<=0;error<=capture_error;
                index<=0;px<=0;py<=0;skin_total<=0;best_distance<=0;best_cost<=255;
                best_x<=0;best_y<=0;peak_count<=0;ring<=0;angle<=0;have_wrist<=0;
                for(j=0;j<4;j=j+1) begin contacts[j]<=0;edge_min[j]<=255;edge_max[j]<=0;end
                prior_peak_count<=0;
                for(j=0;j<3;j=j+1) begin ring_bits[j]<=0;arm_seed[j]<=0;arm_score[j]<=0;arm_found[j]<=0;end
                state<=(capture_error!=0)?FINISH:INIT_REQ;
            end
            INIT_REQ: begin mask_addr<=index;state<=INIT_WAIT;end
            INIT_WAIT: state<=INIT_GET;
            INIT_GET: begin
                dt_write_addr<=index;dt_write_data<=(mask_skin&&!border)?8'hff:0;dt_we<=1;
                if(mask_skin) begin
                    skin_total<=skin_total+1'b1;
                    if(px==1) begin
                        contacts[0]<=contacts[0]+1'b1;
                        if(py<edge_min[0]) edge_min[0]<=py;
                        if(py>edge_max[0]) edge_max[0]<=py;
                    end
                    if(px==WIDTH-2) begin
                        contacts[1]<=contacts[1]+1'b1;
                        if(py<edge_min[1]) edge_min[1]<=py;
                        if(py>edge_max[1]) edge_max[1]<=py;
                    end
                    if(py==1) begin
                        contacts[2]<=contacts[2]+1'b1;
                        if(px<edge_min[2]) edge_min[2]<=px;
                        if(px>edge_max[2]) edge_max[2]<=px;
                    end
                    if(py==HEIGHT-2) begin
                        contacts[3]<=contacts[3]+1'b1;
                        if(px<edge_min[3]) edge_min[3]<=px;
                        if(px>edge_max[3]) edge_max[3]<=px;
                    end
                end
                if(index==SIZE-1) begin
                    index<=0;px<=0;py<=0;backwards<=0;neighbor<=0;state<=DT_REQ;
                end else begin
                    index<=index+1'b1;
                    if(px==WIDTH-1) begin px<=0;py<=py+1'b1;end else px<=px+1'b1;
                    state<=INIT_REQ;
                end
            end
            DT_REQ: begin
                if(border) state<=DT_ADV;
                else begin
                    case(neighbor)
                    0: dt_addr<=index;
                    1: dt_addr<=backwards?(index+1'b1):(index-1'b1);
                    2: dt_addr<=backwards?(index+WIDTH+1):(index-WIDTH-1);
                    3: dt_addr<=backwards?(index+WIDTH):(index-WIDTH);
                    4: dt_addr<=backwards?(index+WIDTH-1):(index-WIDTH+1);
                    default:dt_addr<=index;
                    endcase
                    state<=DT_WAIT;
                end
            end
            DT_WAIT: state<=DT_GET;
            DT_GET: begin
                if(neighbor==0) begin
                    if(dt_q==0) state<=DT_ADV;
                    else begin local_min<=dt_q;neighbor<=1;state<=DT_REQ;end
                end else begin
                    local_min<=merged_min;
                    if(neighbor==4) state<=DT_WRITE;
                    else begin neighbor<=neighbor+1'b1;state<=DT_REQ;end
                end
            end
            DT_WRITE: begin
                dt_write_addr<=index;dt_write_data<=local_min;dt_we<=1;
                if(backwards&&palm_roi&&((local_min>best_distance)||
                   ((local_min==best_distance)&&(central_cost<best_cost)))) begin
                    best_distance<=local_min;best_x<=px;best_y<=py;best_cost<=central_cost[7:0];
                end
                state<=DT_ADV;
            end
            DT_ADV: begin
                neighbor<=0;
                if(!backwards) begin
                    if(index==SIZE-1) begin
                        index<=SIZE-1;px<=WIDTH-1;py<=HEIGHT-1;backwards<=1;
                    end else begin
                        index<=index+1'b1;
                        if(px==WIDTH-1) begin px<=0;py<=py+1'b1;end else px<=px+1'b1;
                    end
                    state<=DT_REQ;
                end else if(index==0) state<=PALM;
                else begin
                    index<=index-1'b1;
                    if(px==0) begin px<=WIDTH-1;py<=py-1'b1;end else px<=px-1'b1;
                    state<=DT_REQ;
                end
            end
            PALM: begin
                if(skin_total<MIN_AREA) begin result_valid<=1;present<=0;count<=0;state<=FINISH;end
                else if(best_distance<MIN_RADIUS*3 || best_distance>MAX_RADIUS*3) begin
                    present<=1;error<=2;state<=FINISH;
                end else begin
                    present<=1;palm_x<=best_x;palm_y<=best_y;palm_radius<=best_distance/3;
                    chosen=0;chosen_votes=contacts[0];
                    for(j=1;j<4;j=j+1) if(contacts[j]>chosen_votes) begin chosen=j;chosen_votes=contacts[j];end
                    wrist_side<=chosen;
                    have_wrist<=(chosen_votes>=MIN_WRIST_CONTACT);
                    midpoint=({1'b0,edge_min[chosen]}+{1'b0,edge_max[chosen]})>>1;
                    case(chosen)
                    0:begin wrist_x<=1;wrist_y<=midpoint[7:0];end
                    1:begin wrist_x<=WIDTH-2;wrist_y<=midpoint[7:0];end
                    2:begin wrist_x<=midpoint[7:0];wrist_y<=1;end
                    3:begin wrist_x<=midpoint[7:0];wrist_y<=HEIGHT-2;end
                    endcase
                    state<=WRIST;
                end
            end
            WRIST:begin
                wrist_dx<=$signed({1'b0,wrist_x})-$signed({1'b0,palm_x});
                wrist_dy<=$signed({1'b0,wrist_y})-$signed({1'b0,palm_y});
                if(REQUIRE_WRIST&&!have_wrist) begin error<=3;state<=FINISH;end
                else begin ring<=0;angle<=0;state<=CIRCLE_REQ;end
            end
            CIRCLE_REQ:begin
                prod_x_hold<=product_x;prod_y_hold<=product_y;
                dot_hold<=dot;cross_hold<=cross_value;state<=CIRCLE_MATH;
            end
            CIRCLE_MATH:begin
                pos_x_hold<=circle_x;pos_y_hold<=circle_y;arm_hold<=arm_angle;state<=CIRCLE_POS;
            end
            CIRCLE_POS:begin
                take_sample<=in_image;
                mask_addr<=in_image?(pos_y_hold*WIDTH+pos_x_hold):0;
                state<=CIRCLE_WAIT;
            end
            CIRCLE_WAIT:state<=CIRCLE_GET;
            CIRCLE_GET:begin
                ring_bits[ring][angle]<=take_sample&&mask_skin;
                if(take_sample&&mask_skin&&arm_hold&&dot_hold>arm_score[ring]) begin
                    arm_seed[ring]<=angle;arm_score[ring]<=dot_hold;arm_found[ring]<=1;
                end
                if(angle==ANGLES-1) begin
                    angle<=0;
                    if(ring==2) begin ring<=0;state<=FILTER_RING;end
                    else begin ring<=ring+1'b1;state<=CIRCLE_REQ;end
                end else begin angle<=angle+1'b1;state<=CIRCLE_REQ;end
            end
            // Circular three-bin majority fills a one-bin hole and removes
            // isolated one-bin specks. Read the original ring throughout;
            // commit only after all 128 bins so the filter is not recursive.
            FILTER_RING:begin
                filtered_ring[angle]<=(ring_left&&ring_middle)||
                                     (ring_middle&&ring_right)||(ring_left&&ring_right);
                if(angle==ANGLES-1) state<=FILTER_COMMIT;
                else angle<=angle+1'b1;
            end
            FILTER_COMMIT:begin
                ring_bits[ring]<=filtered_ring;angle<=0;
                if(ring==2) begin ring<=0;state<=REMOVE_START;end
                else begin ring<=ring+1'b1;state<=FILTER_RING;end
            end
            REMOVE_START:begin
                if(arm_found[ring]) begin
                    ring_bits[ring][arm_seed[ring]]<=0;
                    remove_angle<=arm_seed[ring]+1'b1;remove_trials<=0;state<=REMOVE_FWD;
                end else state<=REMOVE_NEXT;
            end
            REMOVE_FWD:begin
                if(ring_bits[ring][remove_angle]) begin
                    ring_bits[ring][remove_angle]<=0;remove_angle<=remove_angle+1'b1;
                    remove_trials<=remove_trials+1'b1;
                    if(remove_trials==ANGLES-2) state<=REMOVE_NEXT;
                end else begin
                    remove_angle<=arm_seed[ring]-1'b1;remove_trials<=0;state<=REMOVE_BACK;
                end
            end
            REMOVE_BACK:begin
                if(ring_bits[ring][remove_angle]) begin
                    ring_bits[ring][remove_angle]<=0;remove_angle<=remove_angle-1'b1;
                    remove_trials<=remove_trials+1'b1;
                    if(remove_trials==ANGLES-2) state<=REMOVE_NEXT;
                end else state<=REMOVE_NEXT;
            end
            REMOVE_NEXT:begin
                if(ring==2) begin ring<=0;angle<=0;zero_trials<=0;state<=FIND_ZERO;end
                else begin ring<=ring+1'b1;state<=REMOVE_START;end
            end
            // Start immediately after a zero: the final scanned bin is zero.
            // This makes a run crossing 127->0 exactly one candidate.
            FIND_ZERO:begin
                if(!ring_bits[ring][angle]) begin
                    scan_angle<=angle+1'b1;remaining<=ANGLES;run_length<=0;in_run<=0;state<=ARC_SCAN;
                end else if(zero_trials==ANGLES-1) state<=NEXT_RING;
                else begin angle<=angle+1'b1;zero_trials<=zero_trials+1'b1;end
            end
            ARC_SCAN:begin
                scan_angle<=scan_angle+1'b1;remaining<=remaining-1'b1;
                if(ring_bits[ring][scan_angle]) begin
                    if(!in_run) begin in_run<=1;run_start<=scan_angle;run_length<=1;end
                    else run_length<=run_length+1'b1;
                    if(remaining==1) state<=NEXT_RING;
                end else if(in_run) begin
                    arc_center<=run_start+(run_length>>1);last_scan<=(remaining==1);
                    in_run<=0;state<=ARC_END;
                end else if(remaining==1) state<=NEXT_RING;
            end
            ARC_END:begin
                // Inner-only bumps do not represent a sufficiently extended
                // finger. They remain available in ring_bits for diagnostics.
                if(ring<2&&inner_supported&&run_length>=MIN_ARC&&run_length<=MAX_ARC) begin
                    duplicate=0;allowed=(run_length>>1)+MERGE_BINS;
                    // Distinct arcs of this same ring are distinct candidates.
                    // Merge only against peaks already found on earlier rings.
                    for(j=0;j<6;j=j+1) if(j<prior_peak_count) begin
                        separation=(arc_center>peaks[j])?(arc_center-peaks[j]):(peaks[j]-arc_center);
                        if(separation>ANGLES/2) separation=ANGLES-separation;
                        if(separation<=allowed) duplicate=1;
                    end
                    if(!duplicate&&peak_count<6) begin peaks[peak_count]<=arc_center;peak_count<=peak_count+1'b1;end
                end
                run_length<=0;state<=last_scan?NEXT_RING:ARC_SCAN;
            end
            NEXT_RING:begin
                if(ring==2) begin
                    count<=peak_count;result_valid<=(peak_count<=5);error<=(peak_count<=5)?0:4;
                    tip0<=peaks[0];tip1<=peaks[1];tip2<=peaks[2];tip3<=peaks[3];tip4<=peaks[4];
                    state<=FINISH;
                end else begin ring<=ring+1'b1;prior_peak_count<=peak_count;angle<=0;zero_trials<=0;state<=FIND_ZERO;end
            end
            FINISH:begin done<=1;busy<=0;state<=IDLE;end
            default:state<=IDLE;
            endcase
        end
    end
endmodule

