/*
*
* Square root_o calculator
*
* Can calculate approximations based on
* number of fixed bits. Implemented using
* digit by digit algorithm
*
*/
module sqrt #(parameter WIDTH=4,  // width of radicand
            parameter FIXED=0   // fractional bits (for fixed point)
    ) (
        input  logic clk_i,               // clock
        input  logic rst_i,               // rst_i

        // interface signals
        input  logic valid_i,
        input  logic yumi_i,

        output logic valid_o, 
        output logic ready_o,   
        
        // input data
        input  logic [WIDTH-1:0] data_i,   

        // output root_o and remainder
        output logic [WIDTH-1:0] root_o,  // root_o
        output logic [WIDTH-1:0] rem_o    // remainder
    );

    // radicand
    logic [WIDTH-1:0] X, X_next;
    // root
    logic [WIDTH-1:0] Q, Q_next;
    // remainder
    logic [WIDTH+1:0] A, A_next; 
    // Sign test
    logic [WIDTH+1:0] T;     

    // total number of iterations
    localparam ITER = (WIDTH+FIXED) >> 1;  
    // counter
    logic [$clog2(ITER)-1:0] i;
  
    // state logic
    enum logic [1:0] {S_WAIT, S_COMP, S_DONE} ps, ns;
  
    // status signals
    logic i_done;
  
    // state logic
    always_comb begin
        case(ps)
        S_WAIT: ns = (valid_i & ready_o) ? S_COMP : S_WAIT;
        S_COMP: ns = (i_done) ? S_DONE : S_COMP;
        S_DONE: ns = (valid_o & yumi_i) ? S_WAIT: S_DONE;
        default: ns = S_WAIT;
        endcase
    end

    // state logic
    always_ff @(posedge clk_i) begin
        if (rst_i) ps <= S_WAIT;
        else ps <= ns;
    end

    // controller signals
    logic load, incr_i, comp;
  
    assign i_done = (i == ITER - 1);
    assign load = (ps == S_WAIT) & valid_i;
    assign incr_i = (ps == S_COMP) & ~i_done;
    assign comp = (ps == S_COMP);
    assign valid_o = (ps == S_DONE);
    assign ready_o = (ps == S_WAIT);
  
    // datapath logic
    always_ff @(posedge clk_i) begin
        if (load) begin
            i <= 0;
            {A, X} <= {{WIDTH{1'b0}}, data_i, 2'b0};
            Q <= 0;
        end
        if (incr_i) i <= i + 1;
        if (comp) begin
            X <= X_next;
            A <= A_next;
            Q <= Q_next;
        end
    end
  
    // datapath logic
    always_comb begin
        T = A - {Q, 2'b01};
        if (T[WIDTH+1] == 0) begin
            {A_next, X_next} = {T[WIDTH-1:0], X, 2'b0};
            Q_next = {Q[WIDTH-2:0], 1'b1};
        end else begin
            {A_next, X_next} = {A[WIDTH-1:0], X, 2'b0};
            Q_next = Q << 1;
        end  
    end
  
    // output
    assign root_o = Q;
    assign rem_o = A[WIDTH+1:2];
  
  
endmodule