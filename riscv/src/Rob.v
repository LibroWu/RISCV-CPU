module Rob
    #(
    parameter REG_ADDR_WIDTH = 5;
    parameter Q_WIDTH        = 5;
    )
    (
    input   wire          clk_in,
    input   wire          rst_in,
    input   wire          rdy_in,
    
    //input from issue result
    //todo add more inputs to support classifying rob node type
    input wire [REG_ADDR_WIDTH-1:0] reg_addr,
    input wire [31:0] pre_pc,
    
    //input from ex result
    input wire [Q_WIDTH-1:0] target_ROB_pos,
    input wire [31:0]        V_ex,
    
    //output value if the renamed register in rob has the value
    input  wire [Q_WIDTH-1:0] rob_pos_r1,
    input  wire [Q_WIDTH-1:0] rob_pos_r2,
    output wire [31:0] V1,
    output wire [31:0] V2,
    
    //commit
    output  wire                  has_commit,
    output  wire  [Q_WIDTH-1:0]   Commit_Q,
    output  wire  [31:0]          Commit_V,
    
    output wire   [Q_WIDTH-1:0]   ROB_tail
    )
    
    
endmodule
