/* 
*
*   Squared Euclidean distance accelerator
*
*   eq: (x1 - x2)^2 + (y1 - y2)^2
*
*/ 



module dist_sq_euc #(parameter WIDTH = 4) (
    input  logic             clk_i,  // Clock input
    input  logic             rst_i,  // reset input

    // x1 and y1 correspond to the location of the unkown data
    input  logic [WIDTH-1:0] x1_i,    
    input  logic [WIDTH-1:0] y1_i,   

    // x2 and y2 correspond to the known data 
    input  logic [WIDTH-1:0] x2_i, 
    input  logic [WIDTH-1:0] y2_i, 

    // interface signals
    input logic valid_i,
    input logic yumi_i,

    output logic valid_o,
    output logic ready_o,

    // distance output
    output logic [WIDTH*2 - 1:0] dist_o
);

// present state and next state
enum logic [2:0] {S_WAIT, S_COMPUTE, S_SQUARE, S_ADD, S_DONE} ps, ns; // present state, next state, previous state

// next state logic
always_comb begin
    case(ps)
        S_WAIT: ns = (valid_i & ready_o) ? S_COMPUTE : S_WAIT;
        S_COMPUTE: ns = S_SQUARE;
        S_SQUARE: ns = S_ADD;
        S_ADD: ns = S_DONE;
        S_DONE: ns = (valid_o & yumi_i) ? S_WAIT : S_DONE;
        default: ns = S_WAIT;
    endcase
end

// state reset and cycle
always_ff @(posedge clk_i) begin
    if (rst_i) ps <= S_WAIT;
    else ps <= ns;
end

logic comp, load, square, done;
logic valid_o_buff, ready_o_buff;

assign load = (ps == S_WAIT) & valid_i & ready_o;
assign comp = (ps == S_COMPUTE);
assign square = (ps == S_SQUARE);
assign add = (ps == S_ADD);
assign valid_o = (ps == S_DONE);
assign ready_o = (ps == S_WAIT);

// stores delta x and y
logic [WIDTH-1:0] x1_buff, x2_buff, y1_buff, y2_buff;

logic [WIDTH-1:0] sub_x, sub_y, sub_x_buff, sub_y_buff;
logic [WIDTH*2 - 1:0] mult_x, mult_y, mult_x_buff, mult_y_buff;
logic [WIDTH*2 - 1:0] dist_o_buff, sum_lo;

// reset and dff block
always_ff @(posedge clk_i) begin
    if (load) begin
        x1_buff <= x1_i;
        y1_buff <= y1_i;
        x2_buff <= x2_i;
        y2_buff <= y2_i;
    end
    if (comp) begin
        sub_x_buff <= sub_x;
        sub_y_buff <= sub_y;
    end
    if (square) begin
        mult_x_buff <= mult_x;
        mult_y_buff <= mult_y;
    end
    if (add) begin
        dist_o_buff <= sum_lo;
    end
        
end
assign sub_x = (x1_buff > x2_buff) ? (x1_buff - x2_buff) : (x2_buff - x1_buff);
assign sub_y = (y1_buff > y2_buff) ? (y1_buff - y2_buff) : (y2_buff - y1_buff);
assign mult_x = sub_x_buff * sub_x_buff;
assign mult_y = sub_y_buff * sub_y_buff;
assign sum_lo = mult_x + mult_y;

assign dist_o = dist_o_buff;


endmodule


