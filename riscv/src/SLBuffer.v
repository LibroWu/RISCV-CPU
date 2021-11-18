module SLBuffer(
    input   wire          clk_in,
    input   wire          rst_in,
    input   wire          rdy_in,
    
    //input from issue result
    //more inputs
    input   wire       input_valid,
    input   wire [Q_WIDTH-1:0]  Q1,
    input   wire [Q_WIDTH-1:0]  Q2,
    input   wire [31:0]         V1,
    input   wire [31:0]         V2,
    
    //input from ex result
    input wire [Q_WIDTH-1:0] target_ROB_pos,
    input wire [31:0]        V_ex,
    
    //commit
    input  wire                  has_commit,
    input  wire  [Q_WIDTH-1:0]   Commit_Q,
    input  wire  [31:0]          Commit_V,
    
    //mem access
    input   wire [7:0]    mem_din,
    output  wire [7:0]    mem_dout,
    output  wire [31:0]   mem_addr
    output  wire          access_control; //1 if need to do mem access
    output  wire          mem_wr;         //1 for write
    )
    
    
endmodule
