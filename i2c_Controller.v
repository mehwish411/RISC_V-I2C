module i2c_Master_Controller(
input i_clk,
input reset_n,
input rw,  //1:Read , 0: Write
input sda_in_m,
input [6:0] i2c_address,
output reg sda_out_m,
output reg sda_out_en_m,
output reg scl_out_m,
output reg addr_ack,
output reg data_ack,
input [7:0] i2c_wData,
output reg [7:0] i2c_rData
);
//State Machine

parameter I2C_IDLE       = 3'b000,
          I2C_START      = 3'b001,
          I2C_CLOCK_LOW  = 3'b010,
          I2C_DATA_SHIFT = 3'b011,
          I2C_CLOCK_HIGH = 3'b100,
	  I2C_STOP       = 3'b101;
assign i2c_address    = 6'b111100;
assign i2c_wData= 8'b01010101;
assign i2c_rData= 8'b01000101;

//Internal wire/reg Declaration

reg [2:0] i2c_SM_MAIN_M;
reg [4:0] bit_count;
reg [17:0] shift_reg;
reg data_continue;

//I2C Master Controller Logic

always @(posedge i_clk or negedge reset_n)
begin
if(~reset_n)
begin
i2c_SM_MAIN_M <= I2C_IDLE;
bit_count <= 4'b0000;
sda_out_m <= 1'b1;
sda_out_en_m <= 1'b0;
scl_out_m <= 1'b1;
data_continue <= 1'b1;
end

else begin
case(i2c_SM_MAIN_M)
I2C_IDLE: begin
i2c_SM_MAIN_M <= I2C_START;
end

I2C_START: begin
sda_out_m <=1'b0;
i2c_SM_MAIN_M <= I2C_CLOCK_LOW;
if(rw)
begin
shift_reg <= {i2c_address[6:0],1'b0,1'b1,8'h00, 1'b1};
end
else begin
shift_reg <= {1'b1,i2c_wData,1'b1,1'b0,i2c_address[6:0]};
end
end
I2C_CLOCK_LOW: begin
scl_out_m <= 1'b0;
i2c_SM_MAIN_M <= I2C_DATA_SHIFT;
end

I2C_DATA_SHIFT: begin
sda_out_m <= shift_reg[0];
shift_reg <= {1'b0, shift_reg[17:1]};
i2c_SM_MAIN_M <= I2C_CLOCK_HIGH;
end

I2C_CLOCK_HIGH: begin
scl_out_m <= 1'b1;
bit_count <= bit_count + 1;
if(bit_count == 8)
begin
addr_ack <= sda_in_m;
end
else if (bit_count == 18) begin
data_ack <= sda_in_m;
end

if(bit_count == 18) begin
i2c_SM_MAIN_M <= I2C_STOP;
end

else begin
if(bit_count != 17) begin
i2c_rData <= {i2c_rData[6:0], sda_in_m};
i2c_SM_MAIN_M <= I2C_CLOCK_LOW;
end
end
end
I2C_STOP: begin
sda_out_m<= 1'b1;
i2c_SM_MAIN_M <= I2C_IDLE;
end
endcase
end
end
endmodule


module i2cslave(
input i_clk,
input reset_n,
input sda_in_s,
output reg sda_out_s,
output reg sda_out_en_s,
input scl_in_s,
output reg [7:0] i2c_Data
);

//State Machine Declaration
parameter
I2C_IDLE= 3'b000, I2C_START = 3'b001, I2C_ADDR_SHIFT = 3'b010, I2C_RW = 3'b011, 
I2C_DATA_SHIFT = 3'b100, I2C_ADDR_DATA_ACK = 3'b101, I2C_STOP = 3'b110, I2C_REPEAT_START = 3'b111;

//Internal wire/reg Declartaion
reg [2:0] i2c_SM_Main_S;
reg [4:0] bit_count;
reg [17:0] shift_reg;
reg [6:0] addr_reg;
reg [7:0] data_reg;
reg rw;
reg scl_q;
reg sda_q;
reg addr_ack;

// 12c Slave Controller Logic
always @(posedge i_clk or negedge reset_n)
begin
if (~reset_n)
begin
scl_q <= 1'b0;
sda_q <= 1'b0;
end

else begin
scl_q <= scl_in_s;
sda_q <= sda_in_s;
end
end

wire scl_in_rising_edge = ~scl_q & scl_in_s;
wire sda_in_rising_edge = ~sda_q & sda_in_s;
wire sda_in_falling_edge = sda_q & ~sda_in_s;

always @(posedge i_clk or negedge reset_n)
begin

if (~reset_n)
begin
i2c_SM_Main_S <= I2C_IDLE;
bit_count <= 4'b0000;
sda_out_s <= 1'b1;
sda_out_en_s <= 1'b0;
addr_ack <= 1'b0;
rw <= 1'b0;
data_reg <= 8'h00;

//scl_out_m <= 1'b1;
end

else begin

case(i2c_SM_Main_S)

I2C_IDLE: begin
i2c_SM_Main_S <= I2C_START;
end

I2C_START: begin
if (sda_in_s == 0 && scl_in_s ===1)
begin
i2c_SM_Main_S <= I2C_ADDR_SHIFT;
end
end

I2C_ADDR_SHIFT: begin
if(scl_in_rising_edge)
begin
addr_reg [bit_count] <= sda_in_s; 
if(bit_count == 6)
begin
bit_count <= 0;
i2c_SM_Main_S <= I2C_RW;
end

else begin
bit_count = bit_count + 1;
i2c_SM_Main_S <= I2C_ADDR_SHIFT;
end
end
end

I2C_RW: begin 
if(scl_in_rising_edge)
begin
rw <= sda_in_s;
addr_ack <= 1'b1;
i2c_SM_Main_S <= I2C_ADDR_DATA_ACK;
end
end

I2C_DATA_SHIFT: begin 
if(scl_in_rising_edge)
begin
sda_out_en_s <= 1'b1;
sda_out_s <= data_reg [bit_count];
end

else begin
data_reg [bit_count] <= sda_in_s;
sda_out_s <= 1'b1;
sda_out_en_s <= 1'b0;
end

if(bit_count == 8)
begin
bit_count <= 0; i2c_Data = data_reg;
i2c_SM_Main_S <= I2C_ADDR_DATA_ACK;
end

else begin
bit_count <= bit_count + 1;
i2c_SM_Main_S <= I2C_DATA_SHIFT;
end
end

I2C_ADDR_DATA_ACK: begin
sda_out_s <= 1'b0;
sda_out_en_s <= 1'b1;
if(scl_in_rising_edge)
begin
if (addr_ack)
begin
addr_ack <= 1'b0;
i2c_SM_Main_S <= I2C_DATA_SHIFT;
end
end

if(sda_in_rising_edge && scl_in_s ===1) begin
i2c_SM_Main_S <= I2C_STOP;
end

else if (sda_in_falling_edge && scl_in_s ===1) begin
i2c_SM_Main_S <= I2C_ADDR_SHIFT;
end

else begin

//i2c_SM_Main_S <= I2C_DATA_SHIFT;

end
end

I2C_STOP: begin
i2c_SM_Main_S <= I2C_IDLE;
sda_out_s <= 1'b1;
sda_out_en_s <= 1'b0;
end
endcase
end
end
endmodule




module i2c_Controller(
input i_clk,
input reset_n,
input rw,  //1:Read , 0: Write
input [6:0] i2c_address,
input [7:0] i2c_wData,
output [7:0] i2c_Data,
output reg [7:0] i2c_rData
);

//Internal wire/reg Declaration
wire SDA1;
wire SDA2;
wire SCL;
wire i2c_rData1, i2c_rData2;
wire data_ack, addr_ack;
wire sda_out_en_m, sda_out_en_s;

//I2C Master controller instantiation
i2c_Master_Controller xI2C_Master(.i_clk(i_clk),.reset_n(reset_n),.rw(rw),. sda_in_m(SDA1),. i2c_address(i2c_address),
.i2c_wData(i2c_wData),. sda_out_m(SDA2),. sda_out_en_m(sda_out_en_m),.scl_out_m(SCL),. addr_ack(addr_ack),.data_ack(data_ack),
.i2c_rData(i2c_rData));

//I2C slave controller instantiation
i2cslave xI2C_Slave(.i_clk(i_clk),. reset_n(reset_n),. sda_in_s(SDA2),. i2c_address(i2c_address),. sda_out_s(SDA1),
.sda_out_en_s(sda_out_en_s),. scl_in_s(SCL),.i2c_Data(i2c_Data));

endmodule


module i2c_Controller_tb;
  reg i_clk;
  reg reset_n;
  reg rw;
  reg [6:0] i2c_address;
  reg [7:0] i2c_wData;
  wire [7:0] i2c_Data;
  wire [7:0] i2c_rData;

  // Instantiate the i2c_Controller module
  i2c_Controller uut (
    .i_clk(i_clk),
    .reset_n(reset_n),
    .rw(rw),
    .i2c_address(i2c_address),
    .i2c_wData(i2c_wData),
    .i2c_Data(i2c_Data),
    .i2c_rData(i2c_rData)
  );

  // Clock generation
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;  // 10ns clock period (100MHz)
  end

  // Reset and Initialization
  initial begin
    reset_n = 0;
    rw = 0;
    i2c_address = 7'b1010000; // Example I2C address
    i2c_wData = 8'hA5;        // Example data for write

    #10 reset_n = 1;           // Release reset
    #10 rw = 0;                // Start with a write operation

    // Test write operation
    #10 i2c_address = 7'b1010001;
    #10 i2c_wData = 8'h3C;

    // Delay for operation to complete
    #100;

    // Test read operation
    rw = 1;                    // Set to read mode
    #10 i2c_address = 7'b1010010;

    // Delay for read to complete
    #100;

    // End of simulation
    $stop;
  end

  // Monitor to observe the signals
  initial begin
    $monitor("Time=%0t | i_clk=%b | reset_n=%b | rw=%b | i2c_address=%b | i2c_wData=%h | i2c_Data=%h | i2c_rData=%h",
             $time, i_clk, reset_n, rw, i2c_address, i2c_wData, i2c_Data, i2c_rData);
  end
endmodule

