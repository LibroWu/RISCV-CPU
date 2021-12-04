module icache#(
            parameter TAG_WIDTH = 20,
            parameter INDEX_WIDTH = 10
        )
        (
           input wire           clk_in,
           input wire           rst_in,
           input wire           rdy_in,
           input wire           input_valid,
           input wire           request_valid,
           input wire  [31:0]   pc_request,
           input wire  [31:0]   pc_update,
           input wire  [31:0]   instr_update,
           output wire          output_valid,
           output wire [31:0]   instr_output
        );
    reg [31:0] instr_cache[2**INDEX_WIDTH-1:0];
    reg [TAG_WIDTH-1:0] tag_cache[2**INDEX_WIDTH-1:0];
    reg [2**INDEX_WIDTH-1:0] valid;
    wire [TAG_WIDTH-1:0] tags_request,tags_update;
    wire [INDEX_WIDTH-1:0] indexs_request,indexs_update;
    always @(posedge clk_in)
    begin
        if (rst_in)
        begin
            valid <= 0;
        end
        else if (!rdy_in)
        begin
            
        end
        else
        begin
            if (input_valid) begin
                instr_cache[indexs_update] <= instr_update;
                tag_cache[indexs_update] <= tags_update;
                valid[indexs_update] <= 1;
            end
        end
    end
    assign tags_request = pc_request[31:32-TAG_WIDTH];
    assign indexs_request = pc_request[31-TAG_WIDTH:32-TAG_WIDTH-INDEX_WIDTH];
    assign tags_update = pc_update[31:32-TAG_WIDTH];
    assign indexs_update = pc_update[31-TAG_WIDTH:32-TAG_WIDTH-INDEX_WIDTH];
    assign output_valid = request_valid && valid[indexs_request] && (tag_cache[indexs_request] == tags_request);
    assign instr_output = instr_cache[indexs_request];
endmodule