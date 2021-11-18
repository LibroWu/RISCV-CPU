module EX
    #(
    parameter Q_WIDTH = 5;
    )
    ( 
    input wire [6:0]    opcode,
    input wire [2:0]    func3,
    input wire [6:0]    func7,
    input wire [31:0]   V1，
    input wire [31:0]   V2,
    input wire [31:0]   immediate,
    input wire [31:0]   npc,
    input wire [Q_WIDTH-1:0] ROB_pos,
    output wire [Q_WIDTH-1:0] ROB_pos_output,
    output wire [31:0]  V
    )
    
endmodule
