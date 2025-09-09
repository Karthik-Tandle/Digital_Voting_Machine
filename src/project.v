// 4-Bit Digital Voting Machine
// TinyTapeout compliant: 8 inputs, 8 outputs

module tt_um_voting_machine (
    input  wire [7:0] ui_in,   // 8 input pins
    output wire [7:0] uo_out,  // 8 output pins
    input  wire [7:0] uio_in,  // unused
    output wire [7:0] uio_out, // unused
    output wire [7:0] uio_oe,  // unused
    input  wire       ena,     // enable
    input  wire       clk,     // system clock
    input  wire       rst_n    // active-low reset
);

    //-----------------------------------------
    // Signal assignments
    //-----------------------------------------
    wire [3:0] voter   = ui_in[3:0];
    wire       confirm = ui_in[4];
    wire       rst     = ui_in[5];
    wire [1:0] mode    = ui_in[7:6];

    reg  [3:0] winner;
    reg        voting_complete;
    reg  [2:0] debug;

    //-----------------------------------------
    // Vote counters
    //-----------------------------------------
    reg [7:0] cnt0, cnt1, cnt2, cnt3;
    reg [11:0] total_votes;

    //-----------------------------------------
    // Confirm edge detection
    //-----------------------------------------
    reg confirm_d;
    wire confirm_rising = confirm & ~confirm_d;

    //-----------------------------------------
    // One-hot valid voter detection
    //-----------------------------------------
    wire onehot_valid = (voter == 4'b0001) ||
                        (voter == 4'b0010) ||
                        (voter == 4'b0100) ||
                        (voter == 4'b1000);

    wire [1:0] sel_index =
        (voter == 4'b0001) ? 2'd0 :
        (voter == 4'b0010) ? 2'd1 :
        (voter == 4'b0100) ? 2'd2 :
        (voter == 4'b1000) ? 2'd3 : 2'd0;

    //-----------------------------------------
    // Winner combinational logic
    //-----------------------------------------
    reg [3:0] winner_next;
    reg [7:0] max_cnt;
        reg [1:0] idx;

    always @(*) begin
        
        max_cnt = cnt0;
        idx = 2'd0;

        if (cnt1 > max_cnt) begin max_cnt = cnt1; idx = 2'd1; end
        if (cnt2 > max_cnt) begin max_cnt = cnt2; idx = 2'd2; end
        if (cnt3 > max_cnt) begin max_cnt = cnt3; idx = 2'd3; end

        if (max_cnt == 8'd0)
            winner_next = 4'b0000;  // no votes yet
        else begin
            case (idx)
                2'd0: winner_next = 4'b0001;
                2'd1: winner_next = 4'b0010;
                2'd2: winner_next = 4'b0100;
                2'd3: winner_next = 4'b1000;
                default: winner_next = 4'b0000;
            endcase
        end
    end

    //-----------------------------------------
    // Main sequential logic
    //-----------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt0 <= 8'd0;
            cnt1 <= 8'd0;
            cnt2 <= 8'd0;
            cnt3 <= 8'd0;
            total_votes <= 12'd0;
            confirm_d <= 1'b0;
            voting_complete <= 1'b0;
            winner <= 4'd0;
            debug <= 3'd0;
        end else begin
            // track confirm for edge detection
            confirm_d <= confirm;

            case (mode)
                2'b00: begin
                    // Voting Mode
                    voting_complete <= 1'b0;
                    if (confirm_rising && onehot_valid) begin
                        case (sel_index)
                            2'd0: cnt0 <= cnt0 + 1'b1;
                            2'd1: cnt1 <= cnt1 + 1'b1;
                            2'd2: cnt2 <= cnt2 + 1'b1;
                            2'd3: cnt3 <= cnt3 + 1'b1;
                        endcase
                        total_votes <= total_votes + 1'b1;
                    end
                    debug <= total_votes[2:0];
                    winner <= 4'b0000; // hide winner until counting
                end

                2'b01: begin
                    // Counting Mode
                    voting_complete <= 1'b1;
                    debug <= total_votes[2:0];
                    winner <= winner_next;
                end

                2'b10: begin
                    // Reset Mode
                    cnt0 <= 8'd0;
                    cnt1 <= 8'd0;
                    cnt2 <= 8'd0;
                    cnt3 <= 8'd0;
                    total_votes <= 12'd0;
                    voting_complete <= 1'b0;
                    winner <= 4'b0000;
                    debug <= 3'd0;
                end

                2'b11: begin
                    // Test Mode
                    voting_complete <= 1'b0;
                    debug <= total_votes[2:0];
                    winner <= 4'b0000; // no winner in test mode
                end
            endcase
        end
    end

    //-----------------------------------------
    // Assign outputs
    //-----------------------------------------
    assign uo_out = {debug, voting_complete, winner};
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

endmodule
