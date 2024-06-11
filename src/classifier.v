module classifier #(parameter TAG=2, parameter WIDTH=4, parameter MEM_SIZE=1024) 
(
    input logic clk_i,
    input logic rst_i,

    input logic [(TAG+WIDTH)-1:0] data_i,
    input logic start_i,
    input logic [$clog2(MEM_SIZE)-1:0] K_i,

    output logic [TAG-1:0] class_o,
    output logic done_o
);
    /* 
    * for example:
    * 2 tag bits and 8 numbers
    * So, for a tag of 00, max possible count is 8, therefore 3 bits
    * 2 tag bits means 4 possible different tags
    *
    */
    logic [0:(2**TAG)-1][$clog2(MEM_SIZE)-1:0] tag_ctr;
    logic [$clog2(MEM_SIZE)-1:0] K_ctr;
    logic [TAG-1:0] tag_in;
    logic [$clog2(MEM_SIZE)-1:0] max_tag, max_tag_new;
    logic [TAG-1:0] class_local, class_local_new;
    // localparam N = K_i;
    logic start_buff;
    // integer i;
    logic [2**TAG - 1:0] i, j;
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            j <= '0;
            i <= '0;
            K_ctr <= '0;
            done_o <= '0;
            tag_ctr[0:(2**TAG)-1] <= '0;
            tag_in <= '0;
            max_tag_new <= '0;
            class_local_new <= '0;
            start_buff <= start_i;
        end else if (start_buff & (K_ctr < K_i)) begin
            tag_ctr[tag_in] <= tag_ctr[tag_in] + 1;
            K_ctr <= K_ctr + 1;
        end else if (K_ctr == K_i) begin
            if (tag_ctr[j] >= max_tag) begin
                max_tag_new <= max_tag;
                class_local_new <= class_local;
            end
            j <= j + 1;
            i <= i + 1;
            if (i == K_i) K_ctr <= K_i + 1; 
        end else if (K_ctr > K_i) begin
            done_o <= 1;
        end
        start_buff <= start_i;
        tag_in <= data_i[(TAG+WIDTH)-1 : WIDTH];
    end
    always_comb begin
        if ((K_ctr == K_i) & (tag_ctr[j] > max_tag)) begin
            max_tag = tag_ctr[j];
            class_local = j;
        end else begin
            max_tag = max_tag_new;
            class_local = class_local_new;
        end
    end
    assign class_o = class_local_new;
endmodule
