`timescale 1ns/1ps
module raw_bayer_denoise_tb;
parameter W=1920,H=8;
reg clk=0,rst=0,v=0,u=0,en=1;
reg [39:0] d=0;
wire [39:0] q;wire qv,qu;
always #5 clk=~clk;
raw_bayer_denoise #(.IMG_WIDTH(W)) dut(clk,rst,d,v,u,en,q,qv,qu);
reg [9:0] img[0:W*H-1];
reg [39:0] expected[0:W*H];
reg users[0:W*H];integer wr=0,rd=0;
integer x,y,k,i,f,c,hp,vp,nh,nv,s;
reg [39:0] word,expword;
integer raw_error=0,filtered_error=0;
always @(posedge clk)begin
 #1;
 if(rst && qv)begin
  if(rd>=wr || q!==expected[rd] || qu!==users[rd]) $fatal(1,"denoise mismatch beat %0d got%h exp%h",rd,q,expected[rd]);
  rd=rd+1;
 end
end
initial begin
 repeat(4)@(negedge clk);rst=1;
 for(f=0;f<4;f=f+1)begin
  en=(f!=3);
  for(i=0;i<W*H;i=i+1)begin
   case(f)
    0:img[i]=512+((i*13+i/W*7)%33)-16;
    1:img[i]=((i%W)<W/2)?100:900;
    2:img[i]=((i%2)==0)?200:800;
    3:img[i]=$random;
   endcase
  end
  for(y=0;y<H;y=y+1)for(x=0;x<W;x=x+4)begin
   word=0;expword=0;
   for(k=0;k<4;k=k+1)begin
    c=img[y*W+x+k];hp=(x+k>=2)?img[y*W+x+k-2]:c;vp=(y>=2)?img[(y-2)*W+x+k]:c;
    nh=((c>hp?c-hp:hp-c)<=48)?hp:c;
    nv=((c>vp?c-vp:vp-c)<=48)?vp:c;
    s=en?(2*c+nh+nv+2)/4:c;
    word[k*10+:10]=c;expword[k*10+:10]=s;
    if(f==0)begin raw_error=raw_error+(c-512)*(c-512);filtered_error=filtered_error+(s-512)*(s-512);end
    if(f==1 && s!=c)$fatal(1,"strong step blurred");
    if(f==2 && s!=c)$fatal(1,"Bayer colours mixed");
   end
   @(negedge clk);d=word;v=1;u=(x==0&&y==0);
   expected[wr]=expword;users[wr]=u;wr=wr+1;
   if(x==8)begin @(negedge clk);v=0;u=0;end
  end
  @(negedge clk);v=0;u=0;repeat(5)@(negedge clk);
 end
 if(rd!=wr)$fatal(1,"missing outputs");
 if(filtered_error>=raw_error)$fatal(1,"noise energy did not decrease");
 $display("PASS same-colour filter/reference, edges, bypass, SOF; noise SSE %0d -> %0d, beats %0d",raw_error,filtered_error,rd);$finish;
end
initial begin #10000000;$fatal(1,"timeout");end
endmodule
