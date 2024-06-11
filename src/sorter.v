
// Code your design here
module sorter #(parameter TAG = 2, parameter WIDTH = 4, parameter MEM_SIZE = 1024) (clk_i, rst_i, data_i, data_v_i, ready_o, done, data_o, K_i, num_i, stream_data_o);
  input logic [(TAG+WIDTH)-1:0] data_i;
  input logic clk_i;
  input logic rst_i;
  input logic data_v_i;
  input logic [$clog2(MEM_SIZE)-1:0] K_i;
  input logic [$clog2(MEM_SIZE)-1:0] num_i;
  
  output logic ready_o;
  output logic done;
  output logic [(TAG+WIDTH)-1:0] data_o;
  output logic stream_data_o;

  

  enum logic [3:0] {S_MEM, S_WAIT, S_LOAD_A, S_LOAD_B, S_SWAP_1, S_SWAP_2, S_SWAP_3, S_COMPARE, S_SORT, S_STREAM, S_DONE} ps, ns;
  
  
  logic init_mem;
  logic init_i; 
  logic load_A, initi_j;
  logic load_B;
  logic store_B;
  logic store_A;
  logic incr_i;
  logic incr_j;
  // logic stream_data;
  
  logic B_lt_A;
  logic j_done;
  logic i_done;
  logic ctr_done;
  logic start;
  logic stream_done;
  
  always_comb begin
    case(ps)
      S_MEM:      ns = (ctr_done) ? S_WAIT : S_MEM;
      S_WAIT: 	  ns = (start) ? S_LOAD_A : S_WAIT;
      S_LOAD_A: 	ns = S_LOAD_B;
      S_LOAD_B: 	ns = S_COMPARE;
      S_COMPARE: 	ns = (B_lt_A) ? S_SWAP_1 : S_SWAP_3;
      S_SWAP_1:	  ns = S_SWAP_2;
      S_SWAP_2:	  ns = S_SWAP_3;
      S_SWAP_3: begin
        if (j_done == 0) ns = S_LOAD_B;
        else if ( (j_done == 1) & (i_done == 0) ) ns = S_LOAD_A;
        else ns = S_SORT;
      end
      S_SORT:    ns = S_STREAM;
      S_STREAM: ns = (stream_done) ? S_DONE : S_STREAM;
      S_DONE: ns = S_DONE;
      default: ns = S_MEM;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) ps <= S_MEM;
    else ps <= ns;
  end
  
  assign init_mem = (ps == S_MEM);
  assign incr_ctr = (ps == S_MEM) & ~ctr_done & data_v_i;
  assign init_i = (ps == S_WAIT) & start;
  assign start = ctr_done;
  assign load_A = (ps == S_LOAD_A) | (ps == S_SWAP_3);
  assign init_j = (ps == S_LOAD_A);
  assign load_B = (ps == S_LOAD_B);
  assign store_B = (ps == S_SWAP_1);
  assign store_A = (ps == S_SWAP_2);
  assign incr_j = (ps == S_SWAP_3) & ~j_done;
  assign incr_i = (ps == S_SWAP_3) & j_done & ~i_done;
  assign done = (ps == S_SORT);
  assign ready_o = (ps == S_WAIT);
  assign stream_data = (ps == S_STREAM);
  // assign stream_data_o = (ps == S_STREAM);
  

  logic [$clog2(MEM_SIZE)-1:0] i, j;
  logic [(TAG+WIDTH)-1:0] A, B;
  logic [$clog2(MEM_SIZE):0] addr_ctr, addr_stream;

  logic mem_w_v, mem_r_sync_v;
  logic [$clog2(MEM_SIZE)-1:0] mem_read_addr, mem_write_addr;
  logic [(TAG+WIDTH)-1:0] mem_data_i;
  logic [(TAG+WIDTH)-1:0] mem_data_lo, mem_sync_data_o, mem_async_data_o, data_buff;


  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      addr_ctr <= '0;
      addr_stream <= '0;
    end
    // if (init_mem) mem_data_i <= data_i;
    if (incr_ctr) addr_ctr <= addr_ctr + 1'b1;
    if (init_i) i <= '0;
    if (load_A) A <= mem_data_lo;
    if (init_j) j <= i + 1'b1;
    if (load_B) B <= mem_data_lo;
    // if (store_B) mem_data_i <= B;
    // if (store_A) mem_data_i <= A;
    if (incr_j) j <= j + 1'b1;
    if (incr_i) i <= i + 1'b1;
    if (stream_data) addr_stream <= addr_stream + 1'b1;
  end

  always_comb begin
    if (init_mem) begin
      mem_w_v = data_v_i & ~ctr_done;
      mem_read_addr = '0;
      mem_write_addr = addr_ctr;
      mem_data_i = data_i;
      mem_r_sync_v = 1'b0;
    end else if (load_A) begin
      mem_w_v = 1'b0;
      mem_read_addr = i;
      mem_write_addr = '0;
      mem_data_i = '0;
      mem_r_sync_v = 1'b0;
    end else if (load_B) begin
      mem_w_v = 1'b0;
      mem_read_addr = j;
      mem_write_addr = '0;
      mem_data_i = '0;
      mem_r_sync_v = 1'b0;
    end else if (store_B) begin
      mem_w_v = 1'b1;
      mem_read_addr = '0;
      mem_write_addr = i;
      mem_data_i = B;
      mem_r_sync_v = 1'b0;
    end else if (store_A) begin
      mem_w_v = 1'b1;
      mem_read_addr = '0;
      mem_write_addr = j;
      mem_data_i = A;
      mem_r_sync_v = 1'b0;
    end else if (stream_data) begin
      mem_w_v = 1'b0;
      mem_read_addr = addr_stream;
      mem_write_addr = '0;
      mem_data_i = '0;
      mem_r_sync_v = 1'b1;
    end else begin
      mem_w_v = 1'b0;
      mem_read_addr = '0;
      mem_write_addr = '0;
      mem_data_i = '0;
      mem_r_sync_v = 1'b0;
    end
  end
  
  assign B_lt_A = B[WIDTH-1:0] < A[WIDTH-1:0];
  assign j_done = (j == num_i - 1);
  assign i_done = (i == num_i - 2);
  assign ctr_done = (addr_ctr == num_i);
  assign stream_done = (addr_stream == K_i);

  // bsg_mem_1r1w_sync #(.width_p((TAG+WIDTH)), .els_p(MEM_SIZE)) mem (.clk_i(clk_i), .reset_i(rst_i), .w_v_i(mem_w_v), 
  //                                                         .w_addr_i(mem_write_addr), .w_data_i(mem_data_i), .r_v_i(mem_r_sync_v), 
  //                                                         .r_addr_i(mem_read_addr), .r_data_o(mem_data_lo));

  // bsg_mem_1r1w #(.width_p((TAG+WIDTH)), .els_p(MEM_SIZE)) mem (.w_clk_i(clk_i), .w_reset_i(rst_i), .w_v_i(mem_w_v), 
  //                                                         .w_addr_i(mem_write_addr), .w_data_i(mem_data_i), .r_v_i(1'b0), 
  //                                                         .r_addr_i(mem_read_addr), .r_data_o(mem_data_lo));


  logic [(TAG+WIDTH)-1:0]    mem [MEM_SIZE-1:0];
  
  always_ff @(posedge clk_i) begin
    if (mem_w_v) mem[mem_write_addr] <= mem_data_i;
  end
  always_ff @(posedge clk_i) begin
    if (mem_r_sync_v) mem_sync_data_o <= mem[mem_read_addr];
  end

  assign mem_async_data_o = mem[mem_read_addr];
  assign mem_data_lo = (mem_r_sync_v) ? mem_sync_data_o : mem_async_data_o;
  
  logic stream_data_buff; 



  always_ff @(posedge clk_i) begin
    stream_data_buff <= stream_data;
  end

  assign data_o = (stream_data) ? mem_data_lo : '0;
  assign stream_data_o = stream_data & stream_data_buff;

  
endmodule

