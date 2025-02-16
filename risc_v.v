module risc_v(
input clk,reset,
input [31:0] ReadData,
output resultsrc,memwrite,alusrc,regwrite,pcsrc,
output [1:0] immsrc,
output [31:0] Addr,WriteData 
);

wire [31:0] pcnext,pc;                    //pc
wire [31:0] pcplus4;                      //adder
wire [31:0] pctarget;                     //adder
wire [31:0] instr;                        //instructionmemory
wire [31:0] rd1;               				//registerfile
wire [31:0] imm_ext;                      //immediatextender
wire [31:0] srcb;              			   //alu
wire [2:0] alucontrol;                    //alu              
//wire [31:0] read_data;                  //datamemory
wire zero;                                //controlunit
                              
                
clk_div clkd(clk_d,clk);

mux pc_next(pcplus4,pctarget,pcsrc,pcnext);

pc ProgC(clk_d,reset,pcnext,pc);

adder pc_plus4(pc,32'b100,pcplus4);

instmem IM(pc,instr);

registerfile RF(instr[19:15],instr[24:20],instr[11:7],result,regwrite,rd1,rd2,clk_d);

immext ImmExt(instr,immsrc,imm_ext);

mux src_b(rd2,imm_ext,alusrc,srcb);

alu ALU(rd1,srcb,alucontrol,zero,aluresult);

datamem DM(aluresult,rd2,clk_d,memwrite,read_data);

mux result_0(aluresult,read_data,resultsrc,result);

adder pc_target(pc,imm_ext,pctarget);

cu CU(instr[6:0],zero,instr[14:12],instr[30],alusrc,resultsrc,immsrc,regwrite,memwrite,pcsrc,alucontrol);

endmodule 

