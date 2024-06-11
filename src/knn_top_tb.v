// knn_top_tb.v
//
// This file contains the toplevel testbench for testing
// this design. 
//

module knn_top_tb;

  /* Dump Test Waveform To VPD File */
  initial begin
    $fsdbDumpfile("waveform.fsdb");
    $fsdbDumpvars("+all");
  end

  /* Non-synth clock generator */
  logic clk;
  bsg_nonsynth_clock_gen #(10000) clk_gen_1 (clk);

  /* Non-synth reset generator */
  logic reset;
  bsg_nonsynth_reset_gen #(.num_clocks_p(1),.reset_cycles_lo_p(10),. reset_cycles_hi_p(10))
    reset_gen
      (.clk_i        ( clk )
      ,.async_reset_o( reset )
      );

  localparam WIDTH = 4;
  localparam MEM_SIZE = 1024;
  localparam TAG = 2;
 
  logic [1:0] sel_i;
  logic [(TAG+WIDTH)-1:0] x1_i, x2_i, y1_i, y2_i;
  logic [(TAG+(WIDTH*2))-1:0] dist_o, rem_o;
  logic valid_i, valid_o, ready_o, yumi_i;
  logic dist_v_o;
  logic [$clog2(MEM_SIZE)-1:0] num_i;
  logic [$clog2(MEM_SIZE)-1:0] K_i;
  logic [(TAG+(WIDTH*2))-1:0] sorted_data_o;
  logic sorted_v_data_o;
  logic [TAG-1:0] class_o;
  logic done_o;
 
knn_top #(.TAG(TAG), .WIDTH(WIDTH), .MEM_SIZE(MEM_SIZE)) dut (.clk_i(clk), .rst_i(reset), 
                                .x1_i(x1_i), .y1_i(y1_i), .x2_i(x2_i), .y2_i(y2_i), .sel_i(sel_i), .dist_o(dist_o), .rem_o(rem_o),
                                .valid_i(valid_i), .valid_o(valid_o), .ready_o(ready_o), .yumi_i(yumi_i), .dist_v_o(dist_v_o), 
                                .num_i(num_i), .K_i(K_i), .sorted_data_o(sorted_data_o), .sorted_v_data_o(sorted_v_data_o), .class_o(class_o), .done_o(done_o));


integer i;

logic [TAG-1:0] random_tag;
initial begin
  valid_i <= 0; yumi_i <= 0; @(posedge clk);
  num_i <= 'd10; K_i <= 'd5; @(posedge clk);
  
  repeat(25) @(posedge clk);

  
  // Unknown data location
  x1_i <= 'd5; y1_i <= 'd4; @(posedge clk);

  // squared euclidean distance
  sel_i <= 2'b01; @(posedge clk);

  $display("################### Squared Euclidean Distance ################");
  $display("Unknown Data: (X1, Y1): (%d, %d), TAG: XX", x1_i, y1_i);
  $display("Number of data points: %d", num_i);
  $display("K-value: %d", K_i);
  // known data location
  for (i = 0; i < 20; i++) begin
    random_tag <= $random; @(posedge clk);
    $display("************* Iteration #%d", i);
    if (i < num_i) begin
      wait (ready_o == 1) begin
        
        x2_i[(TAG+WIDTH)-1:WIDTH] <= random_tag; y2_i[(TAG+WIDTH)-1:WIDTH] <= random_tag;
        x2_i[WIDTH-1:0] <= $random; y2_i[WIDTH-1:0] <= $random; valid_i <= 1; @(posedge clk);
        
        $display("Known Data: (X2, Y2): (%d, %d), TAG: %b", x2_i[WIDTH-1:0], y2_i[WIDTH-1:0], x2_i[(TAG+WIDTH)-1:WIDTH]);
        valid_i <= 0; @(posedge clk);
        
        wait(valid_o == 1) yumi_i <= 1; @(posedge clk);
        wait(dist_v_o == 1) $display("Distance: %d, TAG: %b, V: %b", dist_o[WIDTH*2-1:0], dist_o[(TAG+(WIDTH*2))-1:WIDTH*2], dist_v_o);
        $display("Remainder: %d", rem_o[WIDTH*2-1:0]);
        yumi_i <= 0; @(posedge clk);
      end
    end
  end
  
  wait(sorted_v_data_o == 1) begin
    @(posedge clk);
    while(sorted_v_data_o == 1) begin
      $display("Sorted Distances: %d, TAG: %d", sorted_data_o[WIDTH*2-1:0], sorted_data_o[(TAG+(WIDTH*2))-1:WIDTH*2]); @(posedge clk);
    end
  end

  repeat(5) @(posedge clk);
  wait(done_o == 1) $display("TAG of unknown data: %d", class_o);


  
  $finish();
end
  


endmodule
