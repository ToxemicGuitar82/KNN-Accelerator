
module knn_top #(parameter WIDTH = 4 
                ,parameter MEM_SIZE = 1024
                ,parameter TAG = 2)
(
    input logic clk_i,
    input logic rst_i,

    // x1 and y1 correspond to the location of the unkown data
    input logic [(TAG+WIDTH)-1:0] x1_i,    
    input logic [(TAG+WIDTH)-1:0] y1_i,   

    // x2 and y2 correspond to the known data 
    input logic  [(TAG+WIDTH)-1:0] x2_i, 
    input logic  [(TAG+WIDTH)-1:0] y2_i, 

    // distance selector
    input logic  [1:0]       sel_i,

    // Number of inputs 
    input logic [$clog2(MEM_SIZE)-1:0] num_i,
    // K nearest neighbors
    input logic [$clog2(MEM_SIZE)-1:0] K_i,

    // interface inputs for distance
    input logic valid_i,
    input logic yumi_i,
    // interface outputs for distance
    output logic valid_o,
    output logic ready_o,

    // distance output
    output logic [(TAG+(WIDTH*2)) - 1:0] dist_o,
    output logic dist_v_o,
    output logic [(TAG+(WIDTH*2)) - 1:0] rem_o,

    // sorted output
    output logic [(TAG+(WIDTH*2))-1:0] sorted_data_o,
    output logic sorted_v_data_o,

    // classifier output
    output logic [TAG-1:0] class_o,
    output logic done_o
);

logic [(TAG+WIDTH)-1:0] x1_buff, y1_buff, x2_buff, y2_buff; 
logic  [1:0] sel_buff;
logic [$clog2(MEM_SIZE)-1:0] num_buff;
logic [$clog2(MEM_SIZE)-1:0] K_buff;
logic valid_i_buff, yumi_i_buff, valid_o_buff, ready_o_buff;

always_ff @(posedge clk_i) begin
    if (rst_i) begin
        x1_buff <= 0;
        y1_buff <= 0;
        x2_buff <= 0;
        y2_buff <= 0;
        sel_buff <= 0;
        num_buff <= 0;
        K_buff <= 0;
        valid_i_buff <= 0;
        yumi_i_buff <= 0;
    end else begin
        x1_buff <= x1_i;
        y1_buff <= y1_i;
        x2_buff <= x2_i;
        y2_buff <= y2_i;
        sel_buff <= sel_i;
        num_buff <= num_i;
        K_buff <= K_i;
        valid_i_buff <= valid_i;
        yumi_i_buff <= yumi_i;
    end
end

dist_top #(.WIDTH(WIDTH), .MEM_SIZE(MEM_SIZE), .TAG(TAG))
    dist_top_inst (.clk_i(clk_i), .rst_i(rst_i), .x1_i(x1_buff), .y1_i(y1_buff), .x2_i(x2_buff), .y2_i(y2_buff), 
                   .sel_i(sel_buff), .num_i(num_buff), .valid_i(valid_i_buff), .yumi_i(yumi_i_buff), .valid_o(valid_o), .ready_o(ready_o),
                   .dist_o(dist_o), .dist_v_o(dist_v_o), .rem_o(rem_o));

logic sorter_ready, sorter_done;

sorter #(.TAG(TAG), .WIDTH(WIDTH*2), .MEM_SIZE(MEM_SIZE)) 
    sorter_inst (.clk_i(clk_i), .rst_i(rst_i), .data_i(dist_o), .data_v_i(dist_v_o), .ready_o(sorter_ready), 
                 .done(sorter_done), .data_o(sorted_data_o), .K_i(K_i), .num_i(num_i), .stream_data_o(sorted_v_data_o));

classifier #(.TAG(TAG), .WIDTH(WIDTH*2), .MEM_SIZE(MEM_SIZE))
    classifier_inst (.clk_i(clk_i), .rst_i(rst_i), .data_i(sorted_data_o), .start_i(sorted_v_data_o), .K_i(K_i),
                     .class_o(class_o), .done_o(done_o));

    
endmodule