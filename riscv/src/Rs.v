module excutable_checker #(parameter Q_WIDTH = 5;)
                          (input reg [Q_WIDTH-1:0] Q1,
                           input reg [Q_WIDTH-1:0] Q2,
                           input wire busy,
                           output wire exable);
    assign exable = (busy && Q1 == 0 && Q2 == 0)? 1:0;
endmodule
    
    module Rs
        #(
        parameter REG_ADDR_WIDTH = 5;
        parameter Q_WIDTH        = 4;
        parameter RS_WIDTH       = 4;
        )
        (
        input   wire          clk_in,
        input   wire          rst_in,
        input   wire          rdy_in,
        
        //input from issue
        //more inputs
        input   wire             input_valid,
        input   wire [Q_WIDTH-1:0]  Q1_input,
        input   wire [Q_WIDTH-1:0]  Q2_input,
        input   wire [31:0]         V1_input,
        input   wire [31:0]         V2_input,
        //opcode
        
        //input from ex result
        input wire update_control,//1 if have ex result
        input wire [Q_WIDTH-1:0] target_ROB_pos,
        input wire [31:0]        V_ex,
        
        output  wire has_ex_node,
        output  wire [31:0]    V1_output,
        output  wire [31:0]    V2_output,
        //opcode
        output  wire RS_Full
        )
        
        reg [2**RS_WIDTH-1:0] Busy;
        wire [RS_WIDTH-1:0] empty_pos,exable_pos;
        wire [2**RS_WIDTH-1:0] exable;
        wire _has_ex_node;
        reg [7:0] op [2**RS_WIDTH-1:0];
        reg [Q_WIDTH-1:0] Q1[2**RS_WIDTH-1:0],Q2[2**RS_WIDTH-1:0],id[2**RS_WIDTH-1:0];
        reg [31:0] V1[2**RS_WIDTH-1:0],V2[2**RS_WIDTH-1:0];
        reg [31:0] V_target;
        reg [Q_WIDTH-1:0] Q_target;
        reg [31:0] _V1_output,_V2_output;
        integer j;
        always @(posedge clk_in) begin
            if (rst_in) begin
                Busy     <= RS_WIDTH'b0;
                V_target <= 32'b0;
                Q_target <= Q_WIDTH'b0;
                for (i = 0;i<2**RS_WIDTH;i = i+1) begin
                    Q1[i] <= Q_WIDTH'b0;
                    Q2[i] <= Q_WIDTH'b0;
                    V1[i] <= 32'b0;
                    V2[i] <= 32'b0;
                end
                end else if (!rdy_in) begin
                
                end else begin
                    if (input_valid) begin
                        busy[empty_pos] <= 1;
                        Q1[empty_pos] <= Q1_input;
                        Q2[empty_pos] <= Q2_input;
                        V1[empty_pos] <= V1_input;
                        V2[empty_pos] <= V2_input;
                        if (update_control) begin
                            if (Q1_input == target_ROB_pos) begin
                                Q1[empty_pos] <= 0;
                                V1[empty_pos] <= V_ex;
                            end
                            if (Q2_input == target_ROB_pos) begin
                                Q2[empty_pos] <= 0;
                                V2[empty_pos] <= V_ex;
                            end
                        end
                    end
                    if (update_control) begin
                        for (j = 0; j<2**RS_WIDTH; j=j+1) begin
                            if (Q1[j]==target_ROB_pos) begin
                                Q1[j] <= 0;
                                V1[j] <= V_ex;
                            end
                            if (Q2[j]==target_ROB_pos) begin
                                Q2[j] <= 0;
                                V2[j] <= V_ex;
                            end
                        end
                    end
                    if (_has_ex_node) begin
                        _V1_output <= V1[exable_pos];
                        _V2_output <= V2[exable_pos];
                        busy[exable_pos] = 0;
                    end
                end
            end
        end
        end
        assign empty_pos = (busy[0] == 0? 0:
        busy[1] == 0? 1:
        busy[2] == 0? 2:
        busy[3] == 0? 3:
        busy[4] == 0? 4:
        busy[5] == 0? 5:
        busy[6] == 0? 6:
        busy[7] == 0? 7:
        busy[8] == 0? 8:
        busy[9] == 0? 9:
        busy[10] == 0? 10:
        busy[11] == 0? 11:
        busy[12] == 0? 12:
        busy[13] == 0? 13:
        busy[14] == 0? 14:
        busy[15] == 0? 15:
        4'bxxxx
        );
        assign RS_Full = (empty_pos===4'bxxxx)?1:0;
        assign exable_pos = (exable[0] == 1? 0:
        exable[1] == 1? 1:
        exable[2] == 1? 2:
        exable[3] == 1? 3:
        exable[4] == 1? 4:
        exable[5] == 1? 5:
        exable[6] == 1? 6:
        exable[7] == 1? 7:
        exable[8] == 1? 8:
        exable[9] == 1? 9:
        exable[10] == 1? 10:
        exable[11] == 1? 11:
        exable[12] == 1? 12:
        exable[13] == 1? 13:
        exable[14] == 1? 14:
        exable[15] == 1? 15:
        4'bxxxx
        );
        assign _has_ex_node = (exable_pos===4'bxxxx)?0:1;
        assign has_ex_node = _has_ex_node;
        assign V1_output = _V1_output;
        assign V2_output = _V2_output;
        genvar i;
        generate
        for (i = 0;i<2**RS_WIDTH;i = i+1) begin
            excutable_checker excuter #(.Q_WIDTH(Q_WIDTH)) (.Q1(Q1[i]),.Q2(Q2[i]),.busy(busy[i]),.exable(exable));
        end
        endgenerate
        
    endmodule
