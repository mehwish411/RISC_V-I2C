module riscv_i2c( 
input clk,reset
);

wire [31:0] Addr,RdM,WriteData,ReadData,WriteData_i2c,result;                                 								//memory
wire WEM,WEI,Rd_sel; 														//Address decoder
wire [1:0] immsrc;
wire resultsrc,alusrc,regwrite,pcsrc, memwrite; 
wire clk_d,sda_out_m;    
            
risc_v riscv(
.clk(clk),
.reset(reset),
.ReadData(ReadData),
.resultsrc(resultsrc),
.memwrite(memwrite),
.alusrc(alusrc),
.regwrite(regwrite),
.pcsrc(pcsrc),
.immsrc(immsrc),
.Addr(Addr),
.WriteData(WriteData)
);

address_decoder addr_decode(
.memWrite(memwrite),
.Addr(Addr),
.WEM(WEM),
.WEI(WEI),
.Rd_sel(Rd_sel)
);

shift_reg shift_reg(
.clk(clk_d),.reset(reset),.enable(WEI),.D(WriteData),.Q(WriteData_i2c)
);

mux rd_mux(
.m(RdM),
.n(sda_out_m),
.sel(Rd_sel),
.out(ReadData)
);


datamem DM(
.mem_addr(Addr),
.write_data(WriteData),
.clk(clk_d),
.memwrite(WEM),
.read_data(RdM)
);
 
//I2C Master-slave controller instantiation
i2c_Controller cont (.i_clk(clk_d),
.reset_n(reset),
.rw(memwrite),  
.i2c_wData(WriteData_i2c),
.i2c_Data(ReadData),
.i2c_rData(ReadData)
);


endmodule
