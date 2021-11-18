module IF(
    input   wire          clk_in,
    input   wire          rst_in,
    input   wire          rdy_in,
    
    //mem access
    input   wire          access_valid, //1 if the mem access is valid
    input   wire [7:0]   mem_din,
    output  wire [31:0]   mem_addr,
    output  wire          access_control, // 1 to request a mem access
    
    output  wire          has_instr,//1 if the instruction is ready
    output  wire [31:0]   instr,
    
    )
    
    
endmodule
