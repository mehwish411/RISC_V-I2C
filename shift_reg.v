module shift_reg (
    input wire clk,       // Clock input
    input wire reset,     // Synchronous reset input
    input wire enable,    // Enable input
    input wire D,         // Data input
    output reg Q          // Output
);

    // Synchronous logic for the D Flip-Flop
    always @(posedge clk) begin
        if (reset)            // If reset is high, reset output to 0
            Q <= 0;
        else if (enable)      // If enable is high, store the input D
            Q <= D;
    end

endmodule