/*
*
*   Top level to select between distance calculation methods
*   
*   sel 00 -> euclidean
*   sel 01 -> squared euclidean
*   sel 10 -> manhattan
*
*/

module dist_top #(parameter WIDTH = 4
                 ,parameter TAG = 2
                 ,parameter MEM_SIZE = 1024) (
    input   logic            clk_i,  // Clock input
    input   logic            rst_i,  // reset input

    // x1 and y1 correspond to the location of the unkown data
    input  logic [(TAG+WIDTH)-1:0] x1_i,    
    input  logic [(TAG+WIDTH)-1:0] y1_i,   

    // x2 and y2 correspond to the known data 
    input  logic [(TAG+WIDTH)-1:0] x2_i, 
    input  logic [(TAG+WIDTH)-1:0] y2_i, 

    // distance selector
    input  logic [1:0]       sel_i,
    input logic [$clog2(MEM_SIZE)-1:0] num_i,

    // interface inputs
    input logic valid_i,
    input logic yumi_i,
    // interface outputs
    output logic valid_o,
    output logic ready_o,

    // distance output
    output logic [(TAG+(WIDTH)*2) - 1:0] dist_o,
    output logic dist_v_o,
    output logic [(TAG+(WIDTH)*2) - 1:0] rem_o
    );


logic [(TAG+(WIDTH)*2) - 1:0] dist_buff, dist_o_sq_euc, dist_o_man, dist_o_sqrt;
logic valid_o_buff, valid_o_sq_euc, valid_o_man, valid_o_SQRT;
logic ready_o_buff, ready_o_sq_euc, ready_o_man, ready_o_SQRT;

logic [(TAG+(WIDTH)*2) - 1:0] rem_buff, dist_rem;

logic [TAG-1:0] tag_buff;

logic [1:0] sel_buff;
logic valid_i_buff, yumi_i_buff;

logic [$clog2(MEM_SIZE)-1:0] num_ctr;


always_ff @(posedge clk_i) begin
    if (rst_i) begin
        num_ctr <= 0;
        tag_buff <= 0;
    end else begin
        if (valid_o) tag_buff <= x2_i[(TAG+WIDTH)-1:WIDTH];
        if ((num_ctr <= num_i) & valid_i) num_ctr <= num_ctr + 1;
    end
end

logic valid_i_sq_euc, valid_i_man;
assign valid_i_sq_euc = valid_i & ((sel_i == 2'b00) | (sel_i == 2'b01)) & (num_ctr <= num_i);
assign valid_i_man = valid_i & (sel_i == 2'b10) & (num_ctr <= num_i);

dist_sq_euc #(.WIDTH(WIDTH)) sq_euc (.clk_i(clk_i), .rst_i(rst_i), .x1_i(x1_i[WIDTH-1:0]), .y1_i(y1_i[WIDTH-1:0]), 
                                     .x2_i(x2_i[WIDTH-1:0]), .y2_i(y2_i[WIDTH-1:0]), .dist_o(dist_o_sq_euc[(WIDTH*2)-1:0]), 
                                     .valid_i(valid_i_sq_euc), .valid_o(valid_o_sq_euc), .ready_o(ready_o_sq_euc), .yumi_i(yumi_i));

dist_man #(.WIDTH(WIDTH)) man       (.clk_i(clk_i), .rst_i(rst_i), .x1_i(x1_i[WIDTH-1:0]), .y1_i(y1_i[WIDTH-1:0]), 
                                     .x2_i(x2_i[WIDTH-1:0]), .y2_i(y2_i[WIDTH-1:0]), .dist_o(dist_o_man[(WIDTH*2)-1:0]),
                                     .valid_i(valid_i_man), .valid_o(valid_o_man), .ready_o(ready_o_man), .yumi_i(yumi_i));

sqrt #(.WIDTH(WIDTH*2), .FIXED(0)) sqrt_inst (.clk_i(clk_i), .rst_i(rst_i), .valid_i(valid_o_sq_euc), .valid_o(valid_o_SQRT), 
                                            .ready_o(ready_o_SQRT), .yumi_i(yumi_i),    
                                            .data_i(dist_o_sq_euc[(WIDTH*2)-1:0]), .root_o(dist_o_sqrt[(WIDTH*2)-1:0]), .rem_o(dist_rem[(WIDTH*2)-1:0]));

always_comb begin
    case(sel_i)
        2'b00: begin                // Euclidean distance
            dist_buff = {tag_buff, dist_o_sqrt[(WIDTH*2)-1:0]};
            rem_buff = dist_rem;
            valid_o_buff = valid_o_SQRT;
            ready_o_buff = ready_o_SQRT;
        end
        2'b01: begin            // squared euclidean dist
            dist_buff = {tag_buff, dist_o_sq_euc[(WIDTH*2)-1:0]};
            rem_buff = 'x;
            valid_o_buff = valid_o_sq_euc;
            ready_o_buff = ready_o_sq_euc;
        end
        2'b10: begin            // manhattan dist
            dist_buff = {tag_buff, dist_o_man[(WIDTH*2)-1:0]};
            rem_buff = 'x;
            valid_o_buff = valid_o_man;
            ready_o_buff = ready_o_man;
        end
        default: begin
            dist_buff = '0;
            rem_buff = '0;
            valid_o_buff = '0;
            ready_o_buff = '0;
        end
    endcase
end

logic dist_v_o_buff;

always_ff @(posedge clk_i) begin
    dist_v_o_buff <= valid_o_buff;
end

assign valid_o = valid_o_buff;
assign ready_o = ready_o_buff;
assign dist_o = dist_buff;
assign rem_o = rem_buff;
assign dist_v_o = dist_v_o_buff & valid_o_buff;


endmodule