// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(input wire clk_in,
           input wire rst_in,
           input wire					 rdy_in,
           input wire [7:0] mem_din,
           output wire [7:0] mem_dout,
           output wire [31:0] mem_a,
           output wire mem_wr,
           input wire io_buffer_full,         // 1 if uart buffer is full
           output wire [31:0]			dbgreg_dout);
    
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
    parameter Q_WIDTH = 5,
    parameter REG_ADDR_WIDTH = 5;
    
    wire IF_access_request,IF_access_valid,IF_has_instr;
    wire [31:0] IF_instr,IF_mem_addr,
    IF _if( .clk_in(clk_in),
            .rst_in(rst_in),
            .rdy_in(rdy_in),
            .access_control(IF_access_request),
            .access_valid(IF_access_valid),
            .mem_addr(IF_mem_addr),
            .mem_din(mem_din),
            .has_instr(IF_has_instr),
            .instr(IF_instr));

    wire issue_has_result,issue_toSLB,issue_toRS;
    wire [31:0] issue_output_V1,issue_output_V2,issue_output_Q1,issue_output_Q2,issue_immediate;
    wire [31:0] issue_input_V1,issue_input_V2,issue_input_Q1,issue_input_Q2;
    wire [REG_ADDR_WIDTH-1:0] rs1,rs2,rd;
    Issue _issue( 
                  .clk_in(clk_in),
                  .rst_in(rst_in),
                  .rdy_in(rdy_in),
                  .instr(IF_instr),
                  .has_instr(IF_has_instr),
                   .V1(issue_input_V1),
                  .V2(issue_input_V2),
                  .Q1(issue_input_Q1),
                  .Q2(issue_input_Q2),
                  .rs1(rs1),
                  .rs2(rs2),
                  .toSLB(issue_toSLB),
                  .toRS(issue_toRS),
                  .hasResult(issue_has_result),
                  //todo output
                );

    regfile _regfile(
                  .clk_in(clk_in),
                  .rst_in(rst_in),
                  .rdy_in(rdy_in),

                  .rs1(rs1),
                  .rs2(rs2),

                  //todo rd

                  );

    EX _ex(

    );

    Rob  _rob(

    );

    SLBuffer _slbuffer(
        
    );

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
            
        end
    end
    
endmodule
