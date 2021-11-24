module IF(
    input   wire          clk_in,
    input   wire          rst_in,
    input   wire          rdy_in,
    
    //1 if ROB is not full
    //in my design, ROB is the same capacity as RS
    input   wire          rd_en,
    //mem access
    input   wire          access_valid, //1 if the mem access is valid
    input   wire [7:0]    mem_din,
    output  wire [31:0]   mem_addr,
    output  wire          access_control, // 1 to request a mem access
    
    output  wire          has_instr,//1 if the instruction is ready
    output  wire [31:0]   instr,
    output  wire [31:0]   npc    
    );
    
    reg  [3:0] q_rd_ptr;
    wire [3:0] d_rd_ptr;
    reg  [3:0] q_wr_ptr;
    wire [3:0] d_wr_ptr;
    reg                  q_empty;
    wire                 d_empty;
    reg                  q_full;
    wire                 d_full;

    reg [31:0] instr_queue [15:0],pc_que[15:0];
    reg [31:0] pc,instr_tmp;
    wire [31:0] _instr;
    reg [31:0] _pc;
    reg [1:0] counter;
    reg _access_valid,_wr_en_prot;
    wire rd_en_prot;
    wire wr_en_prot;
    integer j;
    always @(posedge clk_in) begin
        if (rst_in) begin
            _access_valid <= 0;
            pc<=0;
            _wr_en_prot <= 0;
            counter<=0;
            instr_tmp<=0;
            q_rd_ptr <= 1;
            q_wr_ptr <= 1;
            q_empty  <= 1'b1;
            q_full   <= 1'b0;
            for (j = 0; j<16; j=j+1) begin
                instr_queue[j] <= 0;
                pc_que[j] <= 0;
            end
        end
        else if (!rdy_in) begin
            
        end else begin
            _wr_en_prot <= 0;
            q_full   <= d_full;
            q_empty  <= d_empty;
            q_wr_ptr <= d_wr_ptr;
            q_rd_ptr <= d_rd_ptr;
            instr_queue[q_wr_ptr] <= _instr;
            pc_que[q_wr_ptr] <= _pc;
            _access_valid <= access_valid;
            if (access_valid) begin
                pc <= pc+1;
                if (counter==0) begin
                    _pc <= pc;
                end
            end
            if (_access_valid) begin
                case (counter)
                    0: instr_tmp[7:0] = mem_din;
                    1: instr_tmp[15:8] = mem_din;
                    2: instr_tmp[23:16] = mem_din;
                    3: instr_tmp[31:24] = mem_din;
                endcase
                // if (counter==0) begin
                //     instr_tmp <= {24'b0,mem_din};
                // end else begin
                //   instr_tmp <= instr_tmp<<8 | {24'b0,mem_din};
                // end
                if (counter==3) begin
                    _wr_en_prot<=1;
                end
                counter <= counter+1;
            end
        end
    end

    // Derive "protected" read/write signals.
    assign rd_en_prot = (rd_en && !q_empty);
    assign wr_en_prot = (_wr_en_prot && !q_full);

    // Handle writes.
    assign d_wr_ptr = (wr_en_prot)  ? q_wr_ptr + 1'h1 : q_wr_ptr;
    assign _instr   = (wr_en_prot)  ? instr_tmp : instr_queue[q_wr_ptr];

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
    assign npc       = npc[q_rd_ptr];
    assign has_instr = rd_en_prot;
    assign full      = q_full;
    assign empty     = q_empty;
    assign access_control = !q_full;
    assign mem_addr  = pc;
endmodule
