module Rob
    #(
    parameter REG_ADDR_WIDTH = 5,
    parameter Q_WIDTH        = 4
    )
    (
    input   wire          clk_in,
    input   wire          rst_in,
    input   wire          rdy_in,
    
    //input from issue result
    input wire has_issue,
    input wire isStore_input,
    input wire isBranch_input,
    input wire [REG_ADDR_WIDTH-1:0] reg_addr,
    input wire [31:0] pre_pc,
    input wire [31:0] predict_pc,
    
    //input from SLBuffer result
    input wire has_slb_result,
    input wire slb_head_isStore,
    input wire [Q_WIDTH-1:0] slb_target_ROB_pos,
    input wire [31:0] V_slb,

    //input from ex result
    input wire has_ex_result,
    input wire [Q_WIDTH-1:0] target_ROB_pos,
    input wire [31:0]        V_ex,
    input wire [31:0]        pc_ex,
    //output value if the renamed register in rob has the value
    input  wire [Q_WIDTH-1:0] rob_pos_r1,
    input  wire [Q_WIDTH-1:0] rob_pos_r2,
    output wire has_value1,
    output wire has_value2,
    output wire [31:0] V1,
    output wire [31:0] V2,
    
    //commit
    output  wire                  has_commit_toSLB,
    output  wire                  commit_modify_regfile,
    output  wire  [REG_ADDR_WIDTH-1:0] commit_reg_addr,
    output  wire  [Q_WIDTH-1:0]   Commit_Q,
    output  wire  [31:0]          Commit_V,
    output  wire  [31:0]          Commit_pc,
    output  wire  [31:0]          pre_pc_output,
    output  wire                  control_hazard,
    output  wire                  isBranch_output,
    
    output wire                   empty,
    output wire                   full,
    
    output wire   [Q_WIDTH-1:0]   ROB_tail
    );

    reg  [Q_WIDTH-1:0] q_rd_ptr;
    wire [Q_WIDTH-1:0] d_rd_ptr;
    reg  [Q_WIDTH-1:0] q_wr_ptr;
    wire [Q_WIDTH-1:0] d_wr_ptr;
    reg                  q_empty;
    wire                 d_empty;
    reg                  q_full;
    wire                 d_full;

    wire rd_en_prot;
    wire wr_en_prot;

    reg [REG_ADDR_WIDTH-1:0] rob_reg_addr [2**Q_WIDTH-1:0];
    reg [31:0] rob_V [2**Q_WIDTH-1:0];
    reg [31:0] rob_npc [2**Q_WIDTH-1:0],rob_predict_pc[2**Q_WIDTH-1:0],pre_pc_queue[2**Q_WIDTH-1:0];
    reg [2**Q_WIDTH-1:0] has_value,isStore,isBranch;
    wire _has_value,_isStore,_isBranch;
    wire [REG_ADDR_WIDTH-1:0] _rob_reg_addr;
    wire [31:0] _rob_predict_pc,_pre_pc_queue;
    integer j;
    always @(posedge clk_in) begin
        if (rst_in) begin
            q_rd_ptr  <= 1;
            q_wr_ptr  <= 1;
            q_empty   <= 1'b1;
            q_full    <= 1'b0;
            has_value <= 0;
            isBranch  <= 0;
            isStore   <= 0;
        end
        else if (!rdy_in) begin
            
        end else begin
            if (control_hazard) begin
                q_rd_ptr <= 1;
                q_wr_ptr <= 1;
                q_empty  <= 1'b1;
                q_full   <= 1'b0;
                has_value <= 0;
                isBranch  <= 0;
                isStore   <= 0;
            end else begin
                q_rd_ptr            <= d_rd_ptr;
                q_wr_ptr            <= d_wr_ptr;
                q_empty             <= d_empty;
                q_full              <= d_full;
                rob_reg_addr[q_wr_ptr] <= _rob_reg_addr;
                has_value[q_wr_ptr] <= _has_value;
                isBranch[q_wr_ptr] <= _isBranch;
                isStore[q_wr_ptr] <= _isStore;
                rob_predict_pc[q_wr_ptr] <= _rob_predict_pc;
                pre_pc_queue[q_wr_ptr] <= _pre_pc_queue;
                if (has_ex_result) begin
                    rob_V[target_ROB_pos] <= V_ex;
                    rob_npc[target_ROB_pos] <= pc_ex;
                    has_value[target_ROB_pos] <= 1;
                end
                if (has_slb_result || slb_head_isStore) begin
                    rob_V[slb_target_ROB_pos] <= V_slb;
                    has_value[slb_target_ROB_pos] <= 1;
                end
            end
            if (rd_en_prot) begin
                $display("%h",pre_pc_queue[q_rd_ptr][15:0]);
                if (commit_modify_regfile && commit_reg_addr!=0) begin
                    $display("reg[%0h] %0h",commit_reg_addr,Commit_V);
                end
            end
            // if (control_hazard) begin
            //     $display("control hazard at %h",pre_pc_queue[q_rd_ptr][15:0]);
            // end
            // $display("%b %b %b %b %b %h",control_hazard,d_empty,q_empty,wr_en_prot,isStore_input,has_value);
            // if (rd_en_prot) begin
            //     $display("%h %h %h",pre_pc_queue[q_rd_ptr],rob_predict_pc[q_rd_ptr],rob_npc[q_rd_ptr]);
            //     $display("%h %h %h",commit_modify_regfile,commit_reg_addr,Commit_V);
            //     if (commit_modify_regfile) begin
            //         $display("%h %h",commit_reg_addr,Commit_V);
            //     end
            //     //$display("%d",pre_pc_queue[q_rd_ptr]);
            // end
        end
    end
    wire debug;
    assign debug = commit_reg_addr=='he && Commit_V=='h11f9;
    wire [31:0] debug2;
    assign debug2 = rob_V[7];
    // Derive "protected" read/write signals
    assign rd_en_prot = (!q_empty && has_value[q_rd_ptr]);
    assign wr_en_prot = (!q_full  && has_issue);

    // Handle writes.
    assign d_wr_ptr = (wr_en_prot) ? ((q_wr_ptr+1'h1==4'b0) ? 1 : q_wr_ptr + 1'h1) : q_wr_ptr;
    assign _has_value = (wr_en_prot) ? 0:has_value[q_wr_ptr];
    assign _isStore = (wr_en_prot) ? isStore_input:isStore[q_wr_ptr];
    assign _isBranch = (wr_en_prot) ? isBranch_input: isBranch[q_wr_ptr];
    assign _rob_reg_addr = (wr_en_prot) ? reg_addr: rob_reg_addr[q_wr_ptr];
    assign _rob_predict_pc = (wr_en_prot) ? predict_pc: rob_predict_pc[q_wr_ptr];
    assign _pre_pc_queue = (wr_en_prot) ? pre_pc : pre_pc_queue[q_wr_ptr];
    
    // Handle commits.
    assign d_rd_ptr = (rd_en_prot) ? ((q_rd_ptr+1'h1==4'b0) ? 1 : q_rd_ptr + 1'h1) : q_rd_ptr;

    wire [Q_WIDTH-1:0] addr_bits_wide_1;
    assign addr_bits_wide_1 = 1;
    wire [Q_WIDTH-1:0] addr_bits_wide_2;
    assign addr_bits_wide_2 = 2;

    // Detect empty state:
    //   1) We were empty before and there was no write.
    //   2) We had one entry and there was a read.
    assign d_empty = ((q_empty && !wr_en_prot) ||
                    (((q_wr_ptr - q_rd_ptr) == addr_bits_wide_1 || 
                      (q_wr_ptr - q_rd_ptr) == addr_bits_wide_2 && q_wr_ptr == addr_bits_wide_1
                      ) && rd_en_prot && !wr_en_prot));

    // Detect full state:
    //   1) We were full before and there was no read.
    //   2) We had n-1 entries and there was a write.
    assign d_full = ((q_full && !rd_en_prot) ||
                    (((q_rd_ptr - q_wr_ptr) == addr_bits_wide_1 || 
                      (q_rd_ptr - q_wr_ptr) == addr_bits_wide_2 && q_rd_ptr == addr_bits_wide_1
                      ) && wr_en_prot && !rd_en_prot));

    // Assign output signals to appropriate FFs.
    assign has_commit_toSLB = rd_en_prot && isStore[q_rd_ptr];
    assign commit_reg_addr = rob_reg_addr[q_rd_ptr];
    assign Commit_V = rob_V[q_rd_ptr];
    assign Commit_Q = q_rd_ptr;
    assign Commit_pc = rob_npc[q_rd_ptr];
    assign commit_modify_regfile = rd_en_prot && !(isStore[q_rd_ptr] || isBranch[q_rd_ptr]);
    assign control_hazard = rd_en_prot && (isBranch[q_rd_ptr] && rob_npc[q_rd_ptr]!=rob_predict_pc[q_rd_ptr]);
    assign isBranch_output = isBranch[q_rd_ptr];
    assign pre_pc_output = pre_pc_queue[q_rd_ptr];
    assign full    = q_full;
    assign empty   = q_empty;
    assign ROB_tail = q_wr_ptr;

    assign V1 = (has_value[rob_pos_r1])                            ?  rob_V[rob_pos_r1] :
                (has_ex_result && target_ROB_pos==rob_pos_r1)      ?  V_ex              :
                (has_slb_result && slb_target_ROB_pos==rob_pos_r1) ?  V_slb             :
                0;
    assign V2 = (has_value[rob_pos_r2])                            ?  rob_V[rob_pos_r2] :
                (has_ex_result && target_ROB_pos==rob_pos_r2)      ?  V_ex              :
                (has_slb_result && slb_target_ROB_pos==rob_pos_r2) ?  V_slb             :
                0;
    assign has_value1 = has_value[rob_pos_r1] || (has_ex_result && target_ROB_pos==rob_pos_r1) || (has_slb_result && slb_target_ROB_pos==rob_pos_r1);
    assign has_value2 = has_value[rob_pos_r2] || (has_ex_result && target_ROB_pos==rob_pos_r2) || (has_slb_result && slb_target_ROB_pos==rob_pos_r2);
endmodule