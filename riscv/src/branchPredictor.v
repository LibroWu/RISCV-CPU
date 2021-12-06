module branchPredictor
#(
    parameter  PREDICTOR_WIDTH=12,
    parameter  HISTORY_WIDTH = 2
)
(
    input  wire          clk_in,
    input  wire          rst_in,
    input  wire          rdy_in,
    input  wire [31:0]   now_pc,
    input  wire          update_control,
    input  wire          update_jump,
    input  wire [31:0]   update_pc,
    output wire          jump
);
    reg [HISTORY_WIDTH-1:0] history[2**PREDICTOR_WIDTH-1:0];
    reg [2**HISTORY_WIDTH-1:0] predict_table[2**PREDICTOR_WIDTH-1:0];
    integer j;
    always @(posedge clk_in)
    begin
        if (rst_in)
        begin
            for (j = 0; j<2**PREDICTOR_WIDTH; j=j+1) begin
                history[j] <= 0;
                predict_table[j] <= 0;
            end
        end
        else if (!rdy_in)
        begin
            
        end
        else
        begin
            if (update_control) begin
                predict_table[update_pc[PREDICTOR_WIDTH+1:2]][history[update_pc[PREDICTOR_WIDTH+1:2]]]<=update_jump;
                history[update_pc[PREDICTOR_WIDTH+1:2]] <= (history[update_pc[PREDICTOR_WIDTH+1:2]]<<1) ^ update_jump;
            end
        end
    end
    wire [HISTORY_WIDTH-1:0] local_history;
    assign local_history = history[now_pc[PREDICTOR_WIDTH+1:2]];
    assign jump = predict_table[now_pc[PREDICTOR_WIDTH+1:2]][local_history];
endmodule