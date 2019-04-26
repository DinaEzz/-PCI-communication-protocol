module Device(CLK,RESET,FRAME,AD,CBE,IRDY,TRDY,DEVSEL,FREQ,REQ,MY_GRNT,i,WRnotRD,countData,count,TRadd);

output reg [2:0] REQ;
input CLK,RESET,WRnotRD; // i for which bit of req & grnt & FREQ of this device
inout [2:0] MY_GRNT;
input [1:0] countData,count; // for no. of Data words in one transaction
input [31:0] TRadd; 
input [2:0] FREQ; 
input  [1:0] i; 
inout [3:0] CBE;
inout [31:0] AD;
inout FRAME,IRDY,TRDY,DEVSEL;
reg [3:0] ROW_NUM; 
reg [31:0] DEV[0:9];
reg [31:0] Data; 
reg AD_IN,FRAME_IN,IRDY_IN,TRDY_IN,CBE_IN,DEVSEL_IN,GRNT_IN;
reg FRAMEReg,IRDYReg,TRDYReg,DEVSELReg; // count for no. of transactions  
reg [3:0] CBEReg;
reg [1:0]countData_temp,count_temp; 
reg [31:0] sendData;  
wire [2:0] GRNT; 
reg [31:0] My_Address; 
reg tarf; 
reg endt;
reg [1:0]NotAdd;
//----------------------------------------------------------------------------------------------------------
assign AD	=(AD_IN)?32'bzzzzzzzz_zzzzzzzz_zzzzzzzz_zzzzzzzz:Data;
assign FRAME	=(FRAME_IN)?32'bzzzzzzzz_zzzzzzzz_zzzzzzzz_zzzzzzzz:FRAMEReg;
assign IRDY	=(IRDY_IN)?32'bzzzzzzzz_zzzzzzzz_zzzzzzzz_zzzzzzzz:IRDYReg;
assign TRDY	=(TRDY_IN)?32'bzzzzzzzz_zzzzzzzz_zzzzzzzz_zzzzzzzz:TRDYReg;
assign CBE	=(CBE_IN)?32'bzzzzzzzz_zzzzzzzz_zzzzzzzz_zzzzzzzz:CBEReg;
assign DEVSEL	=(DEVSEL_IN)?32'bzzzzzzzz_zzzzzzzz_zzzzzzzz_zzzzzzzz:DEVSELReg;
assign MY_GRNT 	=(GRNT_IN)?3'bzzz:GRNT; 

initial
begin
NotAdd=0;
end

always @(WRnotRD,TRadd) 
begin 
ROW_NUM =0;
FRAME_IN = 0; 
IRDY_IN = 0;
FRAMEReg = 1; 
IRDYReg = 1;
end 

always @(*)
begin 
case (i)
	0: begin sendData = 32'hAAAAAAAA; My_Address = 32'h0000_0000; end
	1: begin sendData = 32'hBBBBBBBB; My_Address = 32'h0000_0010; end
	2: begin sendData = 32'hCCCCCCCC; My_Address = 32'h0000_0011; end 
endcase 
end 

always @(posedge CLK)
begin
	if(FREQ[i] == 0) // the initiator
	begin
	if (FRAME || FRAME === 1'bz) begin 
	TRDY_IN = 1; 
	DEVSEL_IN = 1; 
	countData_temp = countData; 
	count_temp = count;
	endt=0;
	end 
	@(negedge CLK) begin REQ[i] = 0; end 
		GRNT_IN = 0;
		if(GRNT[i] == 0)
		begin 
		FRAME_IN = 0; 
		IRDY_IN = 0;
		AD_IN = 0; 
		CBE_IN = 0; 
		@(negedge CLK) 
		begin 
		FRAMEReg = 0; 
		Data = TRadd;  
		CBEReg = (WRnotRD)? 4'b0011 : 4'b0010; 
		if (count_temp == 0 && ~FRAME) REQ[i] = 1; // complete all transactions  
		end
                if(NotAdd==3)
                begin
                 repeat (2) @(posedge CLK);
                FRAME_IN=0;
                IRDY_IN=0;
                @(negedge CLK)
                begin
                
                FRAMEReg=1;
                IRDYReg=1;
                end
                end    
			if (~WRnotRD) // READ 
			begin
				AD_IN = 1; 
				@(negedge CLK) begin    end // turn around cycle
								
				if (~TRDY) 
				begin 
					
					if (countData_temp > 0)
					begin 
					@(negedge CLK) begin
					DEV[ROW_NUM] = AD; 
					countData_temp = countData_temp -1; 
					ROW_NUM = ROW_NUM +1; 
					end end     
				end 
				@(negedge CLK) 
				begin 
					if (count_temp == 1 && !endt) FRAMEReg = 1; 
					if (count_temp == 0 && !endt) begin IRDYReg  = 1; endt =1; end 
				end
				if (countData_temp == 0) count_temp = count_temp -1;
				if (endt == 1) 
				@(negedge CLK)
				begin
					FRAME_IN = 1; 
					IRDY_IN = 1;
					REQ = 3'bzzz; 
					GRNT_IN = 1; 
					TRDY_IN = 1; 
					DEVSEL_IN = 1;  
					AD_IN = 1; 
				end  
			end 
			else if (WRnotRD) // Write 
			begin
				AD_IN = 0;
				if(countData_temp > 0)
				begin 
					@(negedge CLK) begin
					IRDYReg = 0;
					Data = sendData; 
					countData_temp = countData_temp -1;
					end 
				end  
				@(negedge CLK) 
				begin 
					if (countData_temp ==0 && count_temp == 1 && !endt)
					begin
						 FRAMEReg = 1;
						 
					end 
					if (count_temp == 0 && TRDY && !endt) begin IRDYReg  = 1; endt=1; end 
						if (endt == 1) 
						@(negedge CLK)
						begin
						FRAME_IN = 1; 
						IRDY_IN = 1;
						REQ = 3'bzzz; 
						GRNT_IN = 1; 
						TRDY_IN = 1; 
						DEVSEL_IN = 1; 
						AD_IN = 1; 
						end  
				end
				if (countData_temp == 0) count_temp = count_temp -1;
			end 
		end  
	end
	else //************* the target ***************
	begin
 	
		FRAME_IN = 1;  
		REQ = 3'bzzz; 
		IRDY_IN = 1;
		CBE_IN = 1; 
		AD_IN = 1;
		GRNT_IN = 1;  
		if (FRAME !== 0) begin 
		countData_temp = countData; 
		count_temp = count;

		TRDY_IN =1; 
		DEVSEL_IN =1; 
		end 
		if (AD!=My_Address)//AD NOT Equal MY_Address
                begin
                NotAdd=NotAdd+1;
                end
		else if (AD == My_Address)
		begin
		DEVSEL_IN = 0;
		TRDY_IN = 0;
		tarf = 1;  
		@(negedge CLK) begin DEVSELReg = 0;TRDYReg =0; end   
		end 
			else if (~WRnotRD && tarf) // Read
			begin 
				AD_IN = 0;  	
				if (countData_temp > 0)
				begin
				@(negedge CLK)begin
				IRDYReg =0;
				Data = sendData;
				countData_temp = countData_temp -1; 
				end end
				 
				if (countData_temp == 0 && count_temp == 0 ) begin @(negedge CLK) begin TRDYReg =1; DEVSELReg =1; end end     	
			end 
			else if (WRnotRD && tarf) // Write 
			begin 
				AD_IN = 1; 
				 
				if (countData_temp > 0)
				begin 
				DEV[ROW_NUM] = AD; 
				ROW_NUM = ROW_NUM +1; 
				countData_temp = countData_temp -1; 
				end 
				@(negedge CLK) begin TRDYReg =0; end
				if (countData_temp == 0) begin @(negedge CLK) begin TRDYReg =1; DEVSELReg =1; tarf=0; end end 
			end 

		
 
 
end // end of else of RESET
end // end of always 
arbiter a1(GRNT,REQ,CLK,RESET,IRDY,FRAME);

endmodule

//------------------------------------------arbiter--------------------------------------------------------------  
module arbiter(GRNT,REQ,CLK,RESET,IRDY,FRAME);  
output reg [2:0]GRNT; 
input CLK,RESET,IRDY,FRAME; 
input [2:0] REQ; 
// reg [2:0]GRNT1;  

always @(posedge CLK) 
begin   
if (FRAME && IRDY) 
begin  
@(negedge CLK) 
	begin 
	case (REQ[0]) 
	0: GRNT <= 3'b110;  
	default: case(REQ[1]) 
 		0: GRNT <= 3'b101; 
 		default: case (REQ[2]) 
  			0: GRNT <= 3'b011; 
  			1: GRNT <= 3'b111; 
  			endcase 
 		endcase 
	endcase
	end // end of negedge    
end // end of if (FRAME && IRDY)  
end // end of always 
endmodule 

module MYPCI_tb ();
reg [2:0] FREQ; 
reg WRnotRD,RESET,CLK;
reg [1:0] iA,iB,iC; 
reg [31:0] TRadd; 
reg [1:0] countData, count; 
wire [31:0] AD; 
wire FRAME, IRDY, TRDY,DEVSEL; 
wire [2:0] REQ, GRNT;
wire [3:0] CBE;  



initial
begin
$monitor($time," CLK %b RESET %b FREQ %b GRNT %b REQ %b FRAME %b IRDY %b CBE %b AD %b TRDY %b DEVSEL %b",CLK,RESET,FREQ,GRNT,REQ,FRAME,IRDY,CBE,AD,TRDY,DEVSEL);
CLK =0;
iA = 0; 
iB = 1; 
iC = 2; 
RESET = 1;


/*#10
WRnotRD = 1; 
countData = 2; 
FREQ = 3'b101; 
TRadd = 32'h0000_0000;
count = 1;*/

/*#70
WRnotRD = 1; 
countData = 3; 
FREQ = 3'b110; 
TRadd = 32'h0000_0010;
count = 1;*/
 
#5
WRnotRD = 1; 
countData = 3; 
FREQ = 3'b110; 
TRadd = 32'h0000_0100;
count = 1;

/*#50
WRnotRD = 1; 
countData = 2; 
FREQ = 3'b010; 
TRadd = 32'h0000_0011;
count = 1; 
*/
end 

always
begin
#3
CLK=~CLK;
end

Device DA(CLK,RESET,FRAME,AD,CBE,IRDY,TRDY,DEVSEL,FREQ,REQ,GRNT,iA,WRnotRD,countData,count,TRadd);
Device DB(CLK,RESET,FRAME,AD,CBE,IRDY,TRDY,DEVSEL,FREQ,REQ,GRNT,iB,WRnotRD,countData,count,TRadd);
Device DC(CLK,RESET,FRAME,AD,CBE,IRDY,TRDY,DEVSEL,FREQ,REQ,GRNT,iC,WRnotRD,countData,count,TRadd);

endmodule 
//*****************************
module Arbiter_FCFS (
 input CLK,
 input tri1 REQA, // pull up resistor 
 input tri1 REQB,
 input tri1 REQC,
 input tri1 FRAM,
 output reg    GNTA,
 output reg    GNTB,
 output reg    GNTC

);

parameter REQ_A=2'b01;
parameter REQ_B=2'b10;
parameter REQ_C=2'b11;
reg [2:0] Mem [0:31];
reg check_FRAM;
integer count_REQ;
integer count_GNT;
initial 
begin
count_REQ=0;
count_GNT=0;
end
always @(posedge CLK)
begin 
  if(!REQA)
   begin
    Mem[count_REQ] <=1;
    count_REQ <=count_REQ+1;
   end 
 if(!REQB)
   begin
    Mem[count_REQ] <=2;
    count_REQ <=count_REQ+1;
   end 
 if(!REQC)
   begin
    Mem[count_REQ] <=3;
    count_REQ <=count_REQ+1;
   end 
  check_FRAM <=FRAM;
end
always @(negedge CLK)
begin
if(check_FRAM)
case(Mem[count_GNT])
1: begin GNTA<=0 ; GNTB <= 1; GNTC <=1; end 
2:  begin GNTA<=1 ; GNTB <= 0; GNTC <=1; end 
3:  begin GNTA<=1 ; GNTB <= 1; GNTC <=0; end 
endcase
if(GNTA||GNTB||GNTC)
 count_GNT=count_GNT+1;
end 
endmodule 