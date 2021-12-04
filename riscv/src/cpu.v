// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(input wire clk_in,
           input wire rst_in,
           input wire rdy_in,
           input wire  [7:0]  mem_din,
           output wire [7:0] mem_dout,
           output wire [31:0]   mem_a,
           output wire         mem_wr,
           input wire  io_buffer_full,         // 1 if uart buffer is full
           output wire [31:0] dbgreg_dout);
    // implementation goes here
    
    // Specifications:
    // - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
    // - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
    // - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
    // - I/O port is mapped to address higher than 0x30000 (mem_a[17:16] == 2'b11)
    // - 0x30000 read: read a byte from input
    // - 0x30000 write: write a byte to output (write 0x00 is ignored)
    // - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
    // - 0x30004 write: indicates program stop (will output '\0' through uart tx)
    parameter Q_WIDTH = 4;
    parameter RS_WIDTH = 4;
    parameter SLB_WIDTH = 4;
    parameter REG_ADDR_WIDTH = 5;
    //rob
    wire rob_isFull,rob_isEmpty,commit_modify_regfile,has_commit_toSLB,rob_has_value1,rob_has_value2;
    wire [Q_WIDTH-1:0] ROB_tail,Commit_Q;
    wire [REG_ADDR_WIDTH-1:0] commit_reg_addr;
    wire [31:0] Commit_V,Commit_pc,rob_V1,rob_V2;
    wire control_hazard;
    //slb
    wire slb_has_result,slb_access_valid,slb_access_request,slb_mem_wr,slb_isFull;
    wire [Q_WIDTH-1:0] slb_target_ROB_pos;
    wire [31:0] slb_V,slb_mem_addr;
    wire [7:0] slb_mem_din,slb_mem_dout;
    //IF
    wire IF_access_request,IF_access_valid,IF_has_instr,IF_rd_en;
    wire [7:0] IF_mem_din;
    wire [31:0] IF_instr,IF_mem_addr,IF_npc,IF_predict_pc;
    wire SLB_pre_access_valid,IF_pre_access_valid;
    //issue
    wire [4:0] issue_rs1,issue_rs2,issue_rd;
    wire issue_toRS,issue_toSLB;
    wire [9:0] issue_op;
    wire [31:0] issue_immediate;
    //rs
    wire rs_input_valid,RS_full,has_ex_node,ex_has_result;
    wire [31:0] rs_V1,rs_V2,rs_immediate,rs_npc;
    wire [Q_WIDTH-1:0] ex_ROB_pos,rs_rob_tag;
    wire [9:0] rs_op;
    assign IF_rd_en = !rob_isFull && !slb_isFull;
    IF _if( .clk_in(clk_in),
            .rst_in(rst_in),
            .rdy_in(rdy_in),
            .control_hazard(control_hazard),
            .Commit_pc(Commit_pc),
            .rd_en(IF_rd_en),
            .access_valid(IF_access_valid),
            .mem_din(IF_mem_din),
            .mem_addr(IF_mem_addr),
            .access_control(IF_access_request),
            .has_instr(IF_has_instr),
            .instr(IF_instr),
            .npc(IF_npc),
            .predict_pc_output(IF_predict_pc),
            .access_valid_output(IF_pre_access_valid)
            );
    Issue _issue( .instr(IF_instr),
                  .has_instr(IF_has_instr),
                  .rs1(issue_rs1),
                  .rs2(issue_rs2),
                  .rd(issue_rd),
                  .toSLB(issue_toSLB),
                  .toRS(issue_toRS),
                  .op(issue_op),
                  .immediate(issue_immediate)
                );
    wire regfile_rd_control;
    assign regfile_rd_control = IF_has_instr &&!(issue_op[9:7]==3 || issue_op[9:7]==4);
    wire [31:0] regfile_V1,regfile_V2,V1,V2,ex_V1,ex_V2,ex_immediate,ex_npc,ex_V,ex_tpc;
    wire [Q_WIDTH-1:0] regfile_Q1,regfile_Q2,Q1,Q2;
    wire [9:0]  ex_op;
    assign V1 = (regfile_Q1==0)  ? regfile_V1 :
                (rob_has_value1) ? rob_V1     :
                0;
    assign V2 = (regfile_Q2==0)  ? regfile_V2 :
                (rob_has_value2) ? rob_V2     :
                0;
    assign Q1 = (issue_op[9:7]==5 || issue_op[9:7]==6 || (regfile_Q1==0 || rob_has_value1))? 0 : regfile_Q1;
    assign Q2 = (issue_op[9:7]==5 || issue_op[9:7]==6 || issue_op[9:7]==2 ||(regfile_Q2==0 || rob_has_value2))? 0 : regfile_Q2;
    regfile  _regfile( .clk_in(clk_in),
                      .rst_in(rst_in),
                      .rdy_in(rdy_in),
                      .rs1(issue_rs1),
                      .rs2(issue_rs2),
                      .control_hazard(control_hazard),
                      .rd_control(regfile_rd_control),
                      .rd(issue_rd),
                      .Q_value(ROB_tail),
                      .has_commit(commit_modify_regfile),
                      .commit_target(commit_reg_addr),
                      .Commit_Q(Commit_Q),
                      .Commit_V(Commit_V),
                      .V1(regfile_V1),
                      .V2(regfile_V2),
                      .Q1(regfile_Q1),
                      .Q2(regfile_Q2)
    );
    Rs _rs( .clk_in(clk_in),
            .rst_in(rst_in),
            .rdy_in(rdy_in),
            .control_hazard(control_hazard),
            .input_valid(rs_input_valid),
            .rob_tag_input(ROB_tail),
            .op_input(issue_op),
            .Q1_input(Q1),
            .Q2_input(Q2),
            .V1_input(V1),
            .V2_input(V2),
            .npc_input(IF_npc),
            .immediate_input(issue_immediate),
            .update_control(ex_has_result),
            .target_ROB_pos(ex_ROB_pos),
            .V_ex(ex_V),
            .has_slb_result(slb_has_result),
            .slb_target_ROB_pos(slb_target_ROB_pos),
            .V_slb(slb_V),
            .has_ex_node(has_ex_node),
            .op_output(rs_op),
            .V1_output(rs_V1),
            .V2_output(rs_V2),
            .immediate_output(rs_immediate),
            .rob_tag_output(rs_rob_tag),
            .npc_output(rs_npc),
            .RS_Full(RS_full)
    );
    assign rs_input_valid = IF_has_instr && issue_toRS && !(!has_ex_node && Q1==0 && Q2==0);
    assign ex_has_result = (has_ex_node || (IF_has_instr && issue_toRS && (Q1==0 && Q2==0)));
    assign ex_op = (has_ex_node)? rs_op : issue_op;
    assign ex_npc = (has_ex_node)? rs_npc : IF_npc;
    assign ex_V1 = (has_ex_node)? rs_V1 : V1;
    assign ex_V2 = (has_ex_node)? rs_V2 : V2;
    assign ex_immediate = (has_ex_node)? rs_immediate : issue_immediate;
    assign ex_ROB_pos = (has_ex_node) ? rs_rob_tag : ROB_tail;  
    EX _ex( .op(ex_op),
            .V1(ex_V1),
            .V2(ex_V2),
            .immediate(ex_immediate),
            .npc(ex_npc),
            .V(ex_V),
            .true_pc(ex_tpc)
    );
    Rob  _rob( .clk_in(clk_in),
               .rst_in(rst_in),
               .rdy_in(rdy_in),
               .has_issue(IF_has_instr),
               .isStore_input(issue_op[9:7]==3),
               .isBranch_input(issue_op[9:7]==4 || IF_instr[6:0]==7'b1100111),
               .reg_addr(issue_rd),
               .pre_pc(IF_npc),
               .predict_pc(IF_predict_pc),
               .has_slb_result(slb_has_result),
               .slb_target_ROB_pos(slb_target_ROB_pos),
               .V_slb(slb_V),
               .has_ex_result(ex_has_result),
               .target_ROB_pos(ex_ROB_pos),
               .V_ex(ex_V),
               .pc_ex(ex_tpc),
               .rob_pos_r1(regfile_Q1),
               .rob_pos_r2(regfile_Q2),
               .has_value1(rob_has_value1),
               .has_value2(rob_has_value2),
               .V1(rob_V1),
               .V2(rob_V2),
               .has_commit_toSLB(has_commit_toSLB),
               .commit_modify_regfile(commit_modify_regfile),
               .commit_reg_addr(commit_reg_addr),
               .Commit_Q(Commit_Q),
               .Commit_V(Commit_V),
               .Commit_pc(Commit_pc),
               .control_hazard(control_hazard),
               .empty(rob_isEmpty),
               .full(rob_isFull),
               .ROB_tail(ROB_tail)
    );
    SLBuffer _slbuffer( .clk_in(clk_in),
                        .rst_in(rst_in),
                        .rdy_in(rdy_in),
                        .control_hazard(control_hazard),
                        .input_valid(IF_has_instr && issue_toSLB),
                        .rob_id(ROB_tail),
                        .immediate_input(issue_immediate),
                        .op_input(issue_op),
                        .Q1_input(Q1),
                        .Q2_input(Q2),
                        .V1_input(V1),
                        .V2_input(V2),
                        .update_control(ex_has_result),
                        .target_ROB_pos(ex_ROB_pos),
                        .V_ex(ex_V),
                        .has_commit(has_commit_toSLB),
                        .Commit_Q(Commit_Q),
                        .Commit_V(Commit_V),
                        .access_valid(slb_access_valid),
                        .mem_din(slb_mem_din),
                        .mem_dout(slb_mem_dout),
                        .mem_addr(slb_mem_addr),
                        .access_control(slb_access_request),
                        .mem_wr(slb_mem_wr),
                        .has_result(slb_has_result),
                        .slb_target_ROB_pos(slb_target_ROB_pos),
                        .V(slb_V),
                        .access_valid_output(SLB_pre_access_valid),
                        .full(slb_isFull)
    );

    //mem access control
    assign IF_access_valid = !slb_access_request && IF_access_request && (!slb_access_request || slb_mem_addr[17:16]!=3);
    assign slb_access_valid = slb_access_request && (slb_mem_addr[17:16]!=3 || !io_buffer_full) && !(SLB_pre_access_valid || IF_pre_access_valid);
    assign mem_wr = (slb_access_valid && slb_mem_wr);
    assign mem_a = (IF_access_valid) ? IF_mem_addr:
                      (slb_access_valid) ? slb_mem_addr:
                      0;
    assign mem_dout = slb_mem_dout;
    assign slb_mem_din = mem_din;
    assign IF_mem_din = mem_din;

    always @(posedge clk_in)
    begin
        if (rst_in)
        begin
            
        end
        else if (!rdy_in)
        begin
            
        end
        else
        begin
        // $display("@%b",rob_isFull);
        // if (IF_has_instr) begin
        //         // $display("%h",IF_instr);
        //         // $display("%h %h %h %h",V1,V2,Q1,Q2);
        //         if (commit_modify_regfile) begin
        //                 $display("%h %h %h",commit_modify_regfile,commit_reg_addr,Commit_V);
        //         end
        // end
        //      if (IF_has_instr && issue_toSLB && issue_op[9:7]==3 && V1[17:16]==2'b11) begin
        //              $display("%h %h %h %h %h",IF_instr,issue_rs1,issue_rs2,V1,V2);
        //      end
        //      if (IF_has_instr && (issue_rd=='h08 || issue_rs1=='h08 || issue_rs2=='h08 || issue_rd == 'h0a)) begin
        //              $display("%h %h %h %h %h %h %h %h %h %h %h",IF_instr,issue_op,issue_op[9:7],issue_op[3:0],issue_rd,issue_rs1,issue_rs2,ex_V1,ex_V2,ex_immediate,ex_V);
        //      end
        end
    end
endmodule