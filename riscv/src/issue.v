module Issue
    #(
    parameter Q_WIDTH = 5,
    parameter REG_ADDR_WIDTH = 5
    )
    (
    input wire [31:0]     instr,
    input wire [31:0] npc_input,
    input wire        has_instr,
    
    output wire [REG_ADDR_WIDTH-1:0] rs1,
    output wire [REG_ADDR_WIDTH-1:0] rs2,
    output wire [REG_ADDR_WIDTH-1:0] rd,
    
    output wire toSLB,
    output wire toRS,

    output wire [9:0]    op,
    output wire [31:0]   immediate,
    output wire [31:0]   npc
    );
    
    wire [31:0] immediateI,immediateS,immediateB,immediateU,immediateJ;
    //0 for empty, 1 for R, 2 for I
    //3 for S, 4 for B, 5 for U
    //6 for J
    wire [2:0] type;
    wire [3:0] sub_opcode;
    wire [2:0] sub_opcode_head;
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];
    assign immediateI = {{21{instr[31]}},instr[30:20]};
    assign immediateS = {{21{instr[31]}},instr[30:25],instr[11:7]};
    assign immediateB = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};
    assign immediateU = {instr[31:12],12'b0};
    assign immediateJ = {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};
    assign immediate = (type==2? immediateI:
                        type==3? immediateS:
                        type==4? immediateB:
                        type==5? immediateU:
                        type==6? immediateJ:
                        0);
    assign toSLB = (instr[6:0]==7'b0100011 | instr[6:0]==7'b0000011)? 1:0;
    assign toRS = ~toSLB;
    assign type = (instr[6:0]==7'b0100011)?3:
                  (instr[6:0]==7'b0110011)?1:
                  (instr[6:0]==7'b0000011)?2:
                  (instr[6:0]==7'b0010011)?2:
                  (instr[6:0]==7'b1100111)?2:
                  (instr[6:0]==7'b0001111)?2:
                  (instr[6:0]==7'b1110011)?2:
                  (instr[6:0]==7'b0110111)?5:
                  (instr[6:0]==7'b0010111)?5:
                  (instr[6:0]==7'b1101111)?6:
                  (instr[6:0]==7'b1100011)?4:
                  0;
    assign sub_opcode = {instr[30],instr[14:12]};
    assign sub_opcode_head = (instr[6:0]==7'b0100011)?1:
                  (instr[6:0]==7'b0110011)?1:
                  (instr[6:0]==7'b0000011)?1:
                  (instr[6:0]==7'b0010011)?2:
                  (instr[6:0]==7'b1100111)?3:
                  (instr[6:0]==7'b0001111)?4:
                  (instr[6:0]==7'b1110011)?5:
                  (instr[6:0]==7'b0110111)?1:
                  (instr[6:0]==7'b0010111)?2:
                  (instr[6:0]==7'b1101111)?1:
                  (instr[6:0]==7'b1100011)?1:
                  0;
    assign op = {type,sub_opcode_head,sub_opcode};
    assign npc = npc_input;
    // always @(*) begin
    //     case (instr[6:0])
    //         7'b0100011: begin
    //           type <= 1;
    //         end 
    //         7'b0110011: begin
              
    //         end
    //         7'b0000011: begin
              
    //         end
    //         7'b0010011: begin
              
    //         end
    //         7'b1100111: begin
              
    //         end
    //         7'b0001111: begin
              
    //         end
    //         7'b1110011: begin
              
    //         end
    //         7'b0110111: begin
              
    //         end
    //         7'b0010111: begin
              
    //         end
    //         7'b1101111: begin
              
    //         end
    //         7'b1100011: begin
              
    //         end
    //         default: begin
              
    //         end
    //     endcase
    // end
endmodule