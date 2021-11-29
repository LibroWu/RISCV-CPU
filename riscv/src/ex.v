module EX
    #(
    parameter Q_WIDTH = 5
    )
    ( 
    input wire [9:0]    op,
    input wire [31:0]   V1,
    input wire [31:0]   V2,
    input wire [31:0]   immediate,
    input wire [31:0]   npc,
    output wire [31:0]  V,
    output wire [31:0] true_pc
    );
    reg [31:0] _V,_true_pc;
    always @(*) begin
        case (op[9:7])
        1:begin
          //R
          //0110011
          case (op[3:0])
              0:  _V <= V1 + V2;
              1:  _V <= V1 << V2;
              2:  _V <= $signed(V1) < $signed(V2);
              3:  _V <= V1 < V2;
              4:  _V <= V1 ^ V2;
              5:  _V <= V1 >> V2;
              6:  _V <= V1 | V2;
              7:  _V <= V1 & V2;
              8:  _V <= V1 - V2;
              13: _V <= V1 >>> V2;
              default: _V <= 0;
          endcase
        end
        2:begin
          //I
          if (op[6:4]==2) begin
            //0010011
            case (op[2:0])
              0:  _V <= V1 + immediate;
              1:  _V <= V1 << immediate[5:0];
              2:  _V <= $signed(V1) < $signed(immediate);
              3:  _V <= V1 < immediate;
              4:  _V <= V1 ^ immediate;
              5:  _V <= (op[3]==1'b1)? (V1>>>immediate[5:0]):(V1 >> immediate[5:0]);
              6:  _V <= V1 | immediate;
              7:  _V <= V1 & immediate;
              default: _V <= 0;
            endcase
          end else if (op[6:4]==3) begin
            //1100111 JALR
            _V <= npc + 4;
            _true_pc <= (V1 + immediate) & ~1;
          end else if (op[6:4]==4) begin
            //0001111 fence

          end else if (op[6:4]==5) begin
            //1110011 ecall & ebreak

          end
        end
        4:begin
          //B
            case (op[2:0])
              0:  _true_pc <= npc + ( (V1 == V2)? immediate: 4);
              1:  _true_pc <= npc + ( (V1 != V2)? immediate: 4);
              4:  _true_pc <= npc + ( ($signed(V1) < $signed(V2))? immediate: 4);
              5:  _true_pc <= npc + ( (!($signed(V1) < $signed(V2)))? immediate: 4);
              6:  _true_pc <= npc + ( (V1<V2)? immediate: 4);
              7:  _true_pc <= npc + ( (!(V1<V2))? immediate: 4);
              default: _true_pc <= 0;
            endcase
        end
        5:begin
          //U
            _V <= 0;
            if (op[6:4]==1) begin
                _V <= immediate;
            end else if (op[6:4]==2) begin
                _V <= npc + immediate;
            end
        end
        6:begin
          //J
          _V <= npc + 4;
          _true_pc <= npc + immediate;
        end
        default:begin
          _V <= 0;
          _true_pc <= 0;
        end
        endcase
    end
    assign V = _V;
    assign true_pc = _true_pc;
endmodule