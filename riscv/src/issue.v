module Issue
    #(
    parameter Q_WIDTH = 5,
    parameter REG_ADDR_WIDTH = 5;
    )
    (
    input wire [31:0]   instr,
    input wire      has_instr,
    
    //get value & Q from regfile or ROB
    input wire [31:0]   V1，
    input wire [31:0]   V2,
    input wire [Q_WIDTH-1:0] Q1,
    input wire [Q_WIDTH-1:0] Q2,
    output wire [REG_ADDR_WIDTH-1:0] rs1,
    output wire [REG_ADDR_WIDTH-1:0] rs2,
    output wire [REG_ADDR_WIDTH-1:0] rd,
    
    output wire toSLB,
    output wire toRS,
    output wire hasResult,
    
    output wire [6:0]   opcode,
    output wire [2:0]   func3,
    output wire [6:0]   func7,
    output wire [31:0]   V1_output，
    output wire [31:0]   V2_output,
    output wire [31:0]   immediate,
    output wire [31:0]   npc,
    output wire [Q_WIDTH-1:0] Q1_output,
    output wire [Q_WIDTH-1:0] Q2_output
    )
    
endmodule
