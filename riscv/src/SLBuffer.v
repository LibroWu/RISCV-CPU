module excutable_checker_slb #(parameter Q_WIDTH = 5)
                          (input wire [Q_WIDTH-1:0] Q1,
                           input wire [Q_WIDTH-1:0] Q2,
                           input wire isStore,
                           input wire has_commit,
                           output wire exable);
    assign exable = (Q1 == 0) && (!isStore || Q2==0 && has_commit);
endmodule

module SLBuffer
#(
    parameter Q_WIDTH = 4,
    parameter SLB_WIDTH       = 4
)
(
    input   wire          clk_in,
    input   wire          rst_in,
    input   wire          rdy_in,
    
    //from rob commit, process branch & jump
    input   wire          control_hazard,
   
    //input from issue result
    input   wire                input_valid,
    input   wire [Q_WIDTH-1:0]  rob_id,
    input   wire [31:0]         immediate_input,
    input   wire [9:0]          op_input,
    input   wire [Q_WIDTH-1:0]  Q1_input,
    input   wire [Q_WIDTH-1:0]  Q2_input,
    input   wire [31:0]         V1_input,
    input   wire [31:0]         V2_input,
    
    //input from ex result
    input wire update_control,
    input wire [Q_WIDTH-1:0] target_ROB_pos,
    input wire [31:0]        V_ex,
    
    //commit
    input  wire                  has_commit,
    input  wire  [Q_WIDTH-1:0]   Commit_Q,
    input  wire  [31:0]          Commit_V,
    
    //mem access
    input   wire          access_valid,
    input   wire [7:0]    mem_din,
    output  wire [7:0]    mem_dout,
    output  wire [31:0]   mem_addr,
    output  wire          access_control, //1 if need to do mem access
    output  wire          access_valid_output,
    output  wire          mem_wr,          //1 for write

    output  wire          has_result,
    output  wire          head_isStore,
    output  wire [Q_WIDTH-1:0] slb_target_ROB_pos,
    output  wire [31:0]   V,
    output  wire          full
    );
    
    wire [2**SLB_WIDTH-1:0] exable;
    reg [9:0] op [2**SLB_WIDTH-1:0];
    wire [9:0] _op;
    reg [Q_WIDTH-1:0] Q1[2**SLB_WIDTH-1:0],Q2[2**SLB_WIDTH-1:0],id[2**SLB_WIDTH-1:0];
    wire [Q_WIDTH-1:0] _Q1,_Q2,_id;
    wire [31:0] V_tmp;
    reg [7:0] _mem_dout;
    reg [31:0] V1[2**SLB_WIDTH-1:0],V2[2**SLB_WIDTH-1:0],immediate[2**SLB_WIDTH-1:0];
    wire [31:0] _V1,_V2,_immediate;
    reg [2**SLB_WIDTH-1:0] isStore,receive_commit;
    wire _isStore,_receive_commit;
    reg  [3:0] q_rd_ptr;
    wire [3:0] d_rd_ptr;
    reg  [3:0] _q_rd_ptr;
    wire [3:0] _d_rd_ptr;
    reg  [3:0] q_wr_ptr;
    wire [3:0] d_wr_ptr;
    wire [1:0] target_counter,_target_counter;
    reg  [1:0] counter,_counter;
    reg [SLB_WIDTH-1:0] last_commit_pos;
    wire [SLB_WIDTH-1:0] _last_commit_pos;
    reg has_last_commit;
    reg         q_empty;
    wire        d_empty;
    reg        _q_empty;
    wire       _d_empty;
    reg          q_full;
    wire         d_full;
    reg         _q_full;
    wire        _d_full;
    wire     rd_en_prot;
    wire    _rd_en_prot;
    wire     wr_en_prot;
    wire          fetch;
    reg   _access_valid;

    //sub_ex_module
    wire [31:0] sub_ex_1,sub_ex_2;
    wire [31:0] sub_ex_module_result;
    reg  [31:0] debug_mem_addr;
    assign sub_ex_1 = V1[_q_rd_ptr];
    assign sub_ex_2 = immediate[_q_rd_ptr];
    assign sub_ex_module_result = sub_ex_1 + sub_ex_2;

    integer j;
    always @(posedge clk_in) begin
        if (rst_in) begin
            has_last_commit <= 0;
            last_commit_pos <= 0;
            q_rd_ptr      <= 0;
            q_wr_ptr      <= 0;
            _q_rd_ptr     <= 0;
            q_empty       <= 1'b1;
            q_full        <= 1'b0;
            _q_empty      <= 1'b1;
            _q_full       <= 1'b0;
            _access_valid <= 1'b0;
            counter       <= 0;
            _counter      <= 0;
            isStore       <= 0;
            receive_commit    <= 0;
            for (j = 0; j<2**SLB_WIDTH; j=j+1) begin
                Q1[j]<=0;
                Q2[j]<=0;
                id[j]<=0;
                op[j]<=0;
            end
        end
        else if (!rdy_in) begin

        end else begin
            if (control_hazard) begin
                if (!has_last_commit) begin
                    has_last_commit <= 0;
                    last_commit_pos <= 0;
                    q_rd_ptr      <= 0;
                    q_wr_ptr      <= 0;
                    _q_rd_ptr     <= 0;
                    q_empty       <= 1'b1;
                    q_full        <= 1'b0;
                    _q_empty      <= 1'b1;
                    _q_full       <= 1'b0;
                    _access_valid <= 1'b0;
                    counter       <= 0;
                    _counter      <= 0;
                    isStore       <= 0;
                    receive_commit    <= 0;
                end else begin
                    q_wr_ptr <= _last_commit_pos;
                    last_commit_pos <= 0;
                    has_last_commit <= 0;
                end
            end else begin
                // $display("V2[8]=%h",V2[8]);
                // $display("Q2[8]=%h",Q2[8]);
                // if (q_wr_ptr == 8) begin
                //     $display("Q2[8] input=%h",_Q2);
                // end
                if (rd_en_prot) begin
                    Q1[q_rd_ptr]             <= 0;  
                    Q2[q_rd_ptr]             <= 0;  
                end
                if (_rd_en_prot) begin
                    Q1[_q_rd_ptr]             <= 0;  
                    Q2[_q_rd_ptr]             <= 0;  
                end
                q_rd_ptr                 <= d_rd_ptr;
                _q_rd_ptr                <= _d_rd_ptr;
                q_wr_ptr                 <= d_wr_ptr;
                q_empty                  <= d_empty;
                q_full                   <= d_full;
                _q_empty                 <= _d_empty;
                _q_full                  <= _d_full;
                Q1[q_wr_ptr]             <= _Q1;
                Q2[q_wr_ptr]             <= _Q2;
                V1[q_wr_ptr]             <= _V1;
                V2[q_wr_ptr]             <= _V2;
                immediate[q_wr_ptr]      <= _immediate;
                op[q_wr_ptr]             <= _op;
                id[q_wr_ptr]             <= _id;
                isStore[q_wr_ptr]        <= _isStore;
                receive_commit[q_wr_ptr] <= _receive_commit;
                if (_rd_en_prot && has_last_commit && last_commit_pos==_q_rd_ptr) begin
                    has_last_commit <= 0;
                    last_commit_pos <= 0;
                end
                if (update_control) begin
                    if (wr_en_prot) begin
                        if (_Q1==target_ROB_pos) begin
                            Q1[q_wr_ptr] <= 0;
                            V1[q_wr_ptr] <= V_ex;
                        end
                        if (_Q2==target_ROB_pos) begin
                            Q2[q_wr_ptr] <= 0;
                            V2[q_wr_ptr] <= V_ex;
                        end
                    end
                    if (q_rd_ptr<q_wr_ptr) begin
                        for (j = q_rd_ptr; j<q_wr_ptr; j=j+1) begin
                            if (Q1[j]==target_ROB_pos) begin
                                Q1[j] <= 0;
                                V1[j] <= V_ex;
                            end
                            if (Q2[j]==target_ROB_pos) begin
                                // if (j==8) begin
                                //     $display("j==8_1,update_V=%h, Q2[8] %h target_ROB_pos %h",V_ex,Q2[8],target_ROB_pos);
                                // end
                                Q2[j] <= 0;
                                V2[j] <= V_ex;
                            end
                        end
                    end else begin
                        for (j = q_rd_ptr; j<2**SLB_WIDTH; j=j+1) begin
                            if (Q1[j]==target_ROB_pos) begin
                                Q1[j] <= 0;
                                V1[j] <= V_ex;
                            end
                            if (Q2[j]==target_ROB_pos) begin
                                // if (j==8) begin
                                //     $display("j==8_1,update_V=%h, Q2[8] %h target_ROB_pos %h",V_ex,Q2[8],target_ROB_pos);
                                // end
                                Q2[j] <= 0;
                                V2[j] <= V_ex;
                            end
                        end
                        for (j = 0; j<q_wr_ptr; j=j+1) begin
                            if (Q1[j]==target_ROB_pos) begin
                                Q1[j] <= 0;
                                V1[j] <= V_ex;
                            end
                            if (Q2[j]==target_ROB_pos) begin
                                // if (j==8) begin
                                //     $display("j==8_1,update_V=%h, Q2[8] %h target_ROB_pos %h",V_ex,Q2[8],target_ROB_pos);
                                // end
                                Q2[j] <= 0;
                                V2[j] <= V_ex;
                            end
                        end
                    end
                        // for (j = 0; j<2**SLB_WIDTH; j=j+1) begin
                        //     if (Q1[j]==target_ROB_pos) begin
                        //         Q1[j] <= 0;
                        //         V1[j] <= V_ex;
                        //     end
                        //     if (Q2[j]==target_ROB_pos) begin
                        //         if (j==8) begin
                        //             $display("j==8_1,update_V=%h, Q2[8] %h target_ROB_pos %h",V_ex,Q2[8],target_ROB_pos);
                        //         end
                        //         Q2[j] <= 0;
                        //         V2[j] <= V_ex;
                        //     end
                        // end
                end
                if (has_result) begin
                    if (wr_en_prot) begin
                        if (_Q1==slb_target_ROB_pos) begin
                            Q1[q_wr_ptr] <= 0;
                            V1[q_wr_ptr] <= V;
                        end
                        if (_Q2==slb_target_ROB_pos) begin
                            Q2[q_wr_ptr] <= 0;
                            V2[q_wr_ptr] <= V;
                        end
                    end
                    if (q_rd_ptr<q_wr_ptr) begin
                        for (j = q_rd_ptr; j<q_wr_ptr; j=j+1) begin
                            if (Q1[j]==slb_target_ROB_pos) begin
                                Q1[j] <= 0;
                                V1[j] <= V;
                            end
                            if (Q2[j]==slb_target_ROB_pos) begin
                                // if (j==8) begin
                                //     $display("j==8_2,update_V=%h",V_ex);
                                // end
                                Q2[j] <= 0;
                                V2[j] <= V;
                            end
                        end
                    end else begin
                        for (j = q_rd_ptr; j<2**SLB_WIDTH; j=j+1) begin
                            if (Q1[j]==slb_target_ROB_pos) begin
                                Q1[j] <= 0;
                                V1[j] <= V;
                            end
                            if (Q2[j]==slb_target_ROB_pos) begin
                                // if (j==8) begin
                                //     $display("j==8_2,update_V=%h",V_ex);
                                // end
                                Q2[j] <= 0;
                                V2[j] <= V;
                            end
                        end
                        for (j = 0; j<q_wr_ptr; j=j+1) begin
                            if (Q1[j]==slb_target_ROB_pos) begin
                                Q1[j] <= 0;
                                V1[j] <= V;
                            end
                            if (Q2[j]==slb_target_ROB_pos) begin
                                // if (j==8) begin
                                //     $display("j==8_2,update_V=%h",V_ex);
                                // end
                                Q2[j] <= 0;
                                V2[j] <= V;
                            end
                        end
                    end
                        // for (j = 0; j<2**SLB_WIDTH; j=j+1) begin
                        //     if (Q1[j]==slb_target_ROB_pos) begin
                        //         Q1[j] <= 0;
                        //         V1[j] <= V;
                        //     end
                        //     if (Q2[j]==slb_target_ROB_pos) begin
                        //         if (j==8) begin
                        //             $display("j==8_2,update_V=%h",V_ex);
                        //         end
                        //         Q2[j] <= 0;
                        //         V2[j] <= V;
                        //     end
                        // end
                end
                if (has_commit) begin
                    if (q_rd_ptr<q_wr_ptr) begin
                        for (j = q_rd_ptr; j<q_wr_ptr; j=j+1) begin
                            if (id[j]==Commit_Q && isStore[j]) begin
                                    receive_commit[j] <= 1;
                                    last_commit_pos <= j;
                                    has_last_commit <= 1;
                                end
                        end
                    end else begin
                        for (j = q_rd_ptr; j<2**SLB_WIDTH; j=j+1) begin
                            if (id[j]==Commit_Q && isStore[j]) begin
                                    receive_commit[j] <= 1;
                                    last_commit_pos <= j;
                                    has_last_commit <= 1;
                                end
                        end
                        for (j = 0; j<q_wr_ptr; j=j+1) begin
                             if (id[j]==Commit_Q && isStore[j]) begin
                                    receive_commit[j] <= 1;
                                    last_commit_pos <= j;
                                    has_last_commit <= 1;
                                end
                        end
                    end
                    // for (j = 0; j<2**SLB_WIDTH ; j=j+1) begin
                    //     if (id[j]==Commit_Q) begin
                    //         receive_commit[j] <= 1;
                    //         last_commit_pos <= j;
                    //         has_last_commit <= 1;
                    //     end
                    // end
                end
                if (access_valid) begin
                    if (_counter == _target_counter) begin
                        _counter <= 0;
                    end else begin
                        V1[_q_rd_ptr] <= sub_ex_module_result;
                        V2[_q_rd_ptr] <= V2[_q_rd_ptr] >> 8;
                        immediate[_q_rd_ptr] <= 1;
                        _counter <= _counter + 1;
                    end
                end
                _access_valid <= access_valid;
                if (_access_valid) begin
                    if (counter==target_counter) begin
                        counter <= 0;
                    end else counter <= counter + 1;
                end
            end
            // debug_mem_addr<=mem_addr;
            // if (mem_wr && access_valid) begin
            //     $display("mem %h %h:write %h at %h",_q_rd_ptr,id[_q_rd_ptr],mem_dout,mem_addr);
            // end
            // if (_access_valid) begin
            //     $display("mem %h %h:read %h at %h",_q_rd_ptr,id[_q_rd_ptr],mem_din,debug_mem_addr);
            // end
        end
    end

    assign _last_commit_pos = last_commit_pos + 1;

    // Derive "protected" read/write signals.
    assign _rd_en_prot    = (access_valid && _counter == _target_counter && !_q_empty);
    assign rd_en_prot     = (_access_valid && counter==target_counter && !q_empty);
    assign wr_en_prot     = (input_valid && !q_full);
    
    // Handle writes.
    assign d_wr_ptr        = (wr_en_prot)  ?        q_wr_ptr + 1'h1 : q_wr_ptr;
    assign _Q1             = (wr_en_prot)  ?               Q1_input : Q1[q_wr_ptr];
    assign _Q2             = (wr_en_prot)  ?               Q2_input : Q2[q_wr_ptr];
    assign _V1             = (wr_en_prot)  ?               V1_input : V1[q_wr_ptr];
    assign _V2             = (wr_en_prot)  ?               V2_input : V2[q_wr_ptr];
    assign _isStore        = (wr_en_prot)  ? (op_input[9:7]==3?1:0) : isStore[q_wr_ptr];
    assign _op             = (wr_en_prot)  ?               op_input : op[q_wr_ptr];
    assign _receive_commit = (wr_en_prot)  ?                      0 : receive_commit[q_wr_ptr];
    assign _immediate      = (wr_en_prot)  ?        immediate_input : immediate[q_wr_ptr];
    assign _id             = (wr_en_prot)  ?                 rob_id : id[q_wr_ptr];

    // Handle reads.
    assign d_rd_ptr = (rd_en_prot)  ? q_rd_ptr + 1'h1 : q_rd_ptr;
    assign _d_rd_ptr = (_rd_en_prot) ? _q_rd_ptr + 1'h1 : _q_rd_ptr;
    wire [3:0] addr_bits_wide_1;
    assign addr_bits_wide_1 = 1;

    // Detect empty state:
    //   1) We were empty before and there was no write.
    //   2) We had one entry and there was a read.
    assign d_empty = ((q_empty && !wr_en_prot) ||
                    (((q_wr_ptr - q_rd_ptr) == addr_bits_wide_1) && rd_en_prot && !wr_en_prot));
    assign _d_empty = ((_q_empty && !wr_en_prot) ||
                    (((q_wr_ptr - _q_rd_ptr) == addr_bits_wide_1) && _rd_en_prot && !wr_en_prot));

    // Detect full state:
    //   1) We were full before and there was no read.
    //   2) We had n-1 entries and there was a write.
    assign d_full  = ((q_full && !rd_en_prot) ||
                    (((q_rd_ptr - q_wr_ptr) == addr_bits_wide_1) && wr_en_prot && !rd_en_prot));
    assign _d_full  = ((_q_full && !_rd_en_prot) ||
                    (((_q_rd_ptr - q_wr_ptr) == addr_bits_wide_1) && wr_en_prot && !_rd_en_prot));
    
    // Assign output signals to appropriate FFs.
    assign has_result = (rd_en_prot && !isStore[q_rd_ptr]);
    assign slb_target_ROB_pos = id[q_rd_ptr];
    wire [9:0] op_tmp,_op_tmp;
    assign op_tmp = op[q_rd_ptr];
    assign _op_tmp = op[_q_rd_ptr];
    assign V_tmp[7:0] = (counter==0)? mem_din:V_tmp[7:0];
    assign V_tmp[15:8] = (counter==1)? mem_din:V_tmp[15:8];
    assign V_tmp[23:16] = (counter==2)? mem_din:V_tmp[23:16];
    assign V_tmp[31:24] = (counter==3)? mem_din:V_tmp[31:24];
    assign target_counter = (op_tmp[1:0]==0)? 0:
                            (op_tmp[1:0]==1)? 1:
                            (op_tmp[1:0]==2)? 3:
                            0;
    assign _target_counter = (_op_tmp[1:0]==0)? 0:
                             (_op_tmp[1:0]==1)? 1:
                             (_op_tmp[1:0]==2)? 3:
                             0;
    assign V = (op_tmp[2:0]==0)?   {{25{V_tmp[7]}},V_tmp[6:0]}:
               (op_tmp[2:0]==1)? {{17{V_tmp[15]}},V_tmp[14:0]}:
               (op_tmp[2:0]==2)?                         V_tmp:
               (op_tmp[2:0]==4)?                    V_tmp[7:0]:
               (op_tmp[2:0]==5)? {{17{V_tmp[15]}},V_tmp[14:0]}:
               0;
    assign full      = q_full;
    assign empty     = q_empty;
    assign mem_addr  = sub_ex_module_result;
    assign mem_wr    = _op_tmp[9:7]==3;
    assign mem_dout  = V2[_q_rd_ptr][7:0];
    assign access_control = !_q_empty && exable[_q_rd_ptr];
    assign access_valid_output = _access_valid;
    assign head_isStore = !q_empty && isStore[q_rd_ptr] && !receive_commit[q_rd_ptr];

    genvar i;
    generate 
    for (i = 0;i<2**SLB_WIDTH;i = i+1) begin
        excutable_checker_slb #(.Q_WIDTH(Q_WIDTH)) excuter  (.Q1(Q1[i]),.Q2(Q2[i]),.isStore(isStore[i]),.has_commit(receive_commit[i]),.exable(exable[i]));
    end
    endgenerate
endmodule