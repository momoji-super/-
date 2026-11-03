`timescale 1ns/1ps
module camera_raw_pipeline_tb;
parameter IW=1920, IH=18, OW=1024, OH=10;
reg clk=0, rst_n=0, hs_valid=0;
reg [15:0] hs_data=0;
always #5 clk=~clk;
wire fs,fe,cv,rf,re,rv,av,au,al,dv,du,qv,qu,ql;
wire [31:0] cd;
wire [39:0] rd,ad,dd,q;
csi_unpacket_2lane csi(clk,rst_n,hs_valid,hs_data,fs,fe,cv,,cd);
raw10_unpacket_2lane raw(clk,rst_n,fs,fe,cv,cd,10'd0,rf,re,rv,rd);
uial2axis #(.IMG_WIDTH(IW),.IMG_HEIGHT(IH),.INPUT_DATA_WIDTH(40)) axis(
 clk,rst_n,rd,rv,rf,re,av,ad,au,al);
raw_bayer_denoise #(.IMG_WIDTH(IW)) denoise(clk,rst_n,ad,av,au,1'b1,dd,dv,du);
raw_bayer_resize #(.IN_WIDTH(IW),.IN_HEIGHT(IH),.OUT_WIDTH(OW),.OUT_HEIGHT(OH)) resize(
 clk,rst_n,dd,dv,du,q,qv,qu,ql);
integer xm[0:OW-1],ym[0:OH-1];
integer f,y,x,j,k,idx,phase,ox=0,oy=0,out_frames=0,raw_words=0,rx,ry;
reg [7:0] bytes[0:IW*5/4-1];
reg [9:0] p0,p1,p2,p3;
function [9:0] pixel;
 input integer xx,yy;
 begin pixel=(xx*7+yy*31+((xx%2)==0?93:311)+((yy%2)==0?47:193))%1024;end
endfunction
function [9:0] filtered;
 input integer xx,yy;
 integer c,h,v,nh,nv;
 begin
  c=pixel(xx,yy);h=(xx>=2)?pixel(xx-2,yy):c;v=(yy>=2)?pixel(xx,yy-2):c;
  nh=((c>h?c-h:h-c)<=48)?h:c;nv=((c>v?c-v:v-c)<=48)?v:c;
  filtered=(2*c+nh+nv+2)/4;
 end
endfunction
task word;
 input [15:0] w;
 begin @(negedge clk);hs_valid=1;hs_data=w;end
endtask
task gap;
 input integer count;
 begin @(negedge clk);hs_valid=0;hs_data=0;repeat(count)@(negedge clk);end
endtask
always @(posedge clk) begin
 #1;
 if(rst_n && rv)begin
  rx=(raw_words%(IW*IH/4))%(IW/4)*4;
  ry=(raw_words%(IW*IH/4))/(IW/4);
  for(k=0;k<4;k=k+1)if(rd[k*10+:10]!==pixel(rx+k,ry))
   $fatal(1,"RAW10 mismatch word %0d x%0d y%0d lane%0d got%0d expected%0d",raw_words,rx,ry,k,rd[k*10+:10],pixel(rx+k,ry));
  if(au!==((rx==0)&&(ry==0)) || al!==(rx==IW-4))$fatal(1,"AXIS sideband mismatch");
  raw_words=raw_words+1;
 end
 if(rst_n && qv)begin
  if(qu!==((ox==0)&&(oy==0)) || ql!==(ox==OW-4))$fatal(1,"resize sideband mismatch");
  for(k=0;k<4;k=k+1)if(q[k*10+:10]!==filtered(xm[ox+k],ym[oy]))
   $fatal(1,"resize mismatch frame%0d x%0d y%0d lane%0d got%0d expected%0d",out_frames,ox,oy,k,q[k*10+:10],filtered(xm[ox+k],ym[oy]));
  if(ql)begin ox=0;if(oy==OH-1)begin oy=0;out_frames=out_frames+1;end else oy=oy+1;end
  else ox=ox+4;
 end
end
initial begin
 phase=IW/2-OW/2;idx=0;
 for(j=0;j<IW/2;j=j+1)begin phase=phase+OW/2;if(phase>=IW/2)begin phase=phase-IW/2;xm[idx]=j*2;xm[idx+1]=j*2+1;idx=idx+2;end end
 phase=IH/2-OH/2;idx=0;
 for(j=0;j<IH/2;j=j+1)begin phase=phase+OH/2;if(phase>=IH/2)begin phase=phase-IH/2;ym[idx]=j*2;ym[idx+1]=j*2+1;idx=idx+2;end end
 repeat(8)@(negedge clk);rst_n=1;
 for(f=0;f<2;f=f+1)begin
  gap(10);word(16'h0001);word(16'h0000);gap(10);
  for(y=0;y<IH;y=y+1)begin
   for(x=0;x<IW;x=x+4)begin
    p0=pixel(x,y);p1=pixel(x+1,y);p2=pixel(x+2,y);p3=pixel(x+3,y);
    bytes[x/4*5]=p0[9:2];bytes[x/4*5+1]=p1[9:2];bytes[x/4*5+2]=p2[9:2];bytes[x/4*5+3]=p3[9:2];
    bytes[x/4*5+4]={p3[1:0],p2[1:0],p1[1:0],p0[1:0]};
   end
   word({8'h2b,8'(IW*5/4%256)});word({8'(IW*5/4/256),8'h00});
   for(j=0;j<IW*5/4;j=j+2)word({bytes[j],bytes[j+1]});
   word(16'h0000);gap(25);
  end
  word(16'h0101);word(16'h0000);gap(600);
 end
 if(raw_words!=2*IW*IH/4 || out_frames!=2)$fatal(1,"missing data raw%0d frames%0d",raw_words,out_frames);
 $display("PASS CSI/RAW10/AXIS/denoise/resize: %0dx%0d -> %0dx%0d, %0d RAW words",IW,IH,OW,OH,raw_words);
 $finish;
end
initial begin #100000000;$fatal(1,"timeout");end
endmodule
