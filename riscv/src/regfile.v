module regfile
    #(
    parameter REG_ADDR_WIDTH = 5,
    parameter Q_WIDTH = 5
    )
    (
    input  wire           clk_in,   // system clock
    input   wire          rst_in,
    input   wire          rdy_in,
    input  wire  [REG_ADDR_WIDTH-1:0] rs1,      // rs1 address
    input  wire  [REG_ADDR_WIDTH-1:0] rs2,      // rs2 address
    
    //change Q value in issue
    input  wire  rd_control, //1 if change Q value in issue
    input  wire  [REG_ADDR_WIDTH-1:0] rd,       //rd address
    input  wire  [Q_WIDTH-1:0]   Q_value,       //rob's pos
    
    //commit
    input  wire                  has_commit,
    input  wire  [REG_ADDR_WIDTH-1:0] commit_target,
    input  wire  [Q_WIDTH-1:0]   Commit_Q,
    input  wire  [31:0]          Commit_V,
    
    output wire  [31:0]          V1,     // data input
    output wire  [31:0]          V2,     // data output
    output wire  [Q_WIDTH-1:0]   Q1,
    output wire  [Q_WIDTH-1:0]   Q2
    )
    
    reg [31:0] regs[REG_ADDR_WIDTH-1:0];
    reg [Q_WIDTH-1:0] Q[REG_ADDR_WIDTH-1:0];
    reg [31:0] _V1,_V2;
    reg [Q_WIDTH-1:0] _Q1,_Q2;
    always @(posedge clk_in) begin
        if (rst_in)
        begin
        for (i = 0;i<2**REG_ADDR_WIDTH;i = i+1) begin
            regs[i] <= 0;
            Q[i]    <= 0;
        end
        end
        else if (!rdy_in)
        begin
            
        end
        else
        begin
            _V1 <= regs[rs1];
            _V2 <= regs[rs2];
            _Q1 <= Q[rs1];
            _Q2 <= Q[rs2];
            if (has_commit) begin
                regs[commit_target] <= commit_V;
                if (Q[commit_target]==Commit_Q) begin
                    Q[commit_target] <= 0;
                end
                if (commit_target==rs1) begin
                    _Q1 <= 0;
                    _V1 <= commit_V;
                end
                if (commit_target==rs2) begin
                    _Q2 <= 0;
                    _V2 <= commit_V;
                end
            end
            if (rd_control) begin
                Q[rd] <= Q_value;
            end
        end
    end
    assign Q1 = _Q1;
    assign Q2 = _Q2;
    assign V1 = _V1;
    assign V2 = _V2;
endmodule
