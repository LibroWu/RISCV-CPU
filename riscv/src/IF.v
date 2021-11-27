module IF(
    input   wire          clk_in,
    input   wire          rst_in,
    input   wire          rdy_in,

    //from rob commit, process branch & jump
    input   wire          control_hazard,
    input   wire [31:0]        Commit_pc,

    //1 if ROB is not full
    //in my design, ROB is the same capacity as RS
    input   wire          rd_en,
    //mem access
    input   wire          access_valid, //1 if the mem access is valid
    input   wire [7:0]    mem_din,
    output  wire [31:0]   mem_addr,
    output  wire          access_control, // 1 to request a mem access
    output  wire          access_valid_output,
    
    output  wire          has_instr,//1 if the instruction is ready
    output  wire [31:0]   instr,
    output  wire [31:0]   npc,
    output  wire [31:0]   predict_pc_output 
    );
    
    reg  [3:0] q_rd_ptr;
    wire [3:0] d_rd_ptr;
    reg  [3:0] q_wr_ptr;
    wire [3:0] d_wr_ptr;
    reg                  q_empty;
    wire                 d_empty;
    reg                  q_full;
    wire                 d_full;

    reg [31:0] instr_queue [15:0],pc_que[15:0],predict_pc_queue[15:0];
    wire [31:0] _instr,instr_tmp;
    reg [31:0] _pc;
    wire [31:0] _pc_preserve,_predict_pc_queue;
    reg [1:0] counter,_counter;
    reg _access_valid;
    wire rd_en_prot;
    wire wr_en_prot;
    reg stall,flag;

    //predict part
    //implement as static predict except JAL
    wire [31:0] immediate; 
    wire predict_jump;
    assign predict_jump = 1'b0;
    wire [31:0] predict_pc;
    assign immediate = (flag || _counter!=0) ? {30'b0,_counter}:
                       (instr_tmp[6:0]==7'b1101111)?{{12{instr_tmp[31]}},instr_tmp[19:12],instr_tmp[20],instr_tmp[30:21],1'b0}:
                       (instr_tmp[6:0]==7'b1100011 && predict_jump)?{{20{instr_tmp[31]}},instr_tmp[7],instr_tmp[30:25],instr_tmp[11:8],1'b0}:
                       4;
    assign predict_pc = _pc + immediate;

    integer j;
    always @(posedge clk_in) begin
        if (rst_in) begin
            stall <= 0;
            flag  <= 1;
            _access_valid <= 0;
            _pc <= 0;
            counter<=0;
            _counter <= 0;
            q_rd_ptr <= 1;
            q_wr_ptr <= 1;
            q_empty  <= 1'b1;
            q_full   <= 1'b0;
            for (j = 0; j<16; j=j+1) begin
                instr_queue[j] <= 0;
                pc_que[j] <= 0;
                predict_pc_queue[j] <= 0;
            end
        end
        else if (!rdy_in) begin
            
        end else begin
            if (control_hazard) begin
                stall <= 0;
                _access_valid <= 0;
                flag<= 1;
                _pc <= Commit_pc;
                counter<=0;
                _counter <= 0;
                q_rd_ptr <= 1;
                q_wr_ptr <= 1;
                q_empty  <= 1'b1;
                q_full   <= 1'b0;
                for (j = 0; j<16; j=j+1) begin
                    instr_queue[j] <= 0;
                    pc_que[j] <= 0;
                    predict_pc_queue[j] <= 0;
                end
            end else begin
                q_full   <= d_full;
                q_empty  <= d_empty;
                q_wr_ptr <= d_wr_ptr;
                q_rd_ptr <= d_rd_ptr;
                instr_queue[q_wr_ptr] <= _instr;
                pc_que[q_wr_ptr] <= _pc_preserve;
                predict_pc_queue[q_wr_ptr] <= _predict_pc_queue;
                _access_valid <= access_valid;
                if (access_valid) begin
                    flag<=0;
                    _counter <= _counter + 1;
                    //pc  <= predict_pc;
                    if (counter==3 && _access_valid) begin
                        _pc <= predict_pc;
                    end
                end
                
                if (_access_valid) begin
                    // case (counter)
                    //     0: instr_tmp[7:0] = mem_din;
                    //     1: instr_tmp[15:8] = mem_din;
                    //     2: instr_tmp[23:16] = mem_din;
                    //     3: instr_tmp[31:24] = mem_din;
                    // endcase
                    // if (counter==0) begin
                    //     instr_tmp <= {24'b0,mem_din};
                    // end else begin
                    //   instr_tmp <= instr_tmp<<8 | {24'b0,mem_din};
                    // end
                    counter <= counter+1;
                end
            end 
        end
    end

    assign instr_tmp[7:0] = (counter==0)? mem_din:instr_tmp[7:0];
    assign instr_tmp[15:8] = (counter==1)? mem_din:instr_tmp[15:8];
    assign instr_tmp[23:16] = (counter==2)? mem_din:instr_tmp[23:16];
    assign instr_tmp[31:24] = (counter==3)? mem_din:instr_tmp[31:24];

    // always @(*) begin
    //     if (counter==1) instr_tmp[7:0] = mem_din;
    //     if (counter==2) instr_tmp[15:8] = mem_din;
    //     if (counter==3) instr_tmp[23:16] = mem_din;
    //     if (counter==0) instr_tmp[31:24] = mem_din;
    // end
    // Derive "protected" read/write signals.
    assign rd_en_prot = (rd_en && !q_empty);
    assign wr_en_prot = (counter==3 && _access_valid && !q_full);

    // Handle writes.
    assign d_wr_ptr = (wr_en_prot)  ? q_wr_ptr + 1'h1 : q_wr_ptr;
    assign _instr   = (wr_en_prot)  ? instr_tmp : instr_queue[q_wr_ptr];
    assign _pc_preserve = (wr_en_prot) ? _pc : pc_que[q_wr_ptr];
    assign _predict_pc_queue = (wr_en_prot) ? predict_pc : predict_pc_queue[q_wr_ptr];

    // Handle reads.
    assign d_rd_ptr = (rd_en_prot)  ? q_rd_ptr + 1'h1 : q_rd_ptr;
    
    wire [3:0] addr_bits_wide_1;
    assign addr_bits_wide_1 = 1;

    // Detect empty state:
    //   1) We were empty before and there was no write.
    //   2) We had one entry and there was a read.
    assign d_empty = ((q_empty && !wr_en_prot) ||
                    (((q_wr_ptr - q_rd_ptr) == addr_bits_wide_1) && rd_en_prot));

    // Detect full state:
    //   1) We were full before and there was no read.
    //   2) We had n-1 entries and there was a write.
    assign d_full  = ((q_full && !rd_en_prot) ||
                    (((q_rd_ptr - q_wr_ptr) == addr_bits_wide_1) && wr_en_prot));

    // Assign output signals to appropriate FFs.
    assign instr     = instr_queue[q_rd_ptr];
    assign npc       = pc_que[q_rd_ptr];
    assign predict_pc_output = predict_pc_queue[q_rd_ptr];
    assign has_instr = rd_en_prot;
    assign full      = q_full;
    assign empty     = q_empty;
    assign access_control = !stall && !q_full;
    assign access_valid_output = _access_valid;
    assign mem_addr  = predict_pc;
endmodule
