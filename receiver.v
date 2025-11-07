`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// College: RV college of Engineering
// Engineers: 
// Create Date: 07/28/2024
// Design Name: 
// Module Name: Receiver
// Project Name: HCP
// Target Devices: 
// Tool Versions: 
// Description: Receiver module that monitors the data line, recognizes start and end frames,
//              stores data with and without bit stuffing.
//////////////////////////////////////////////////////////////////////////////////

module receiver(
    input clk,
    input [7:0] sbda,
    input receiving, // Enable pin from the slave
    output reg [7:0] data, // Data register to store received data
    output reg data_valid // Signal to indicate valid data reception
);

    parameter Start_frame = 8'b01111110;
    parameter Stop_frame = 8'b11111110;
    reg [2:0] bit_count; // Counter for the number of bits received
    reg [7:0] temp_data; // Temporary storage for incoming data
    reg [7:0] processed_data; // Register to store data after bit stuffing removal
    reg receiving_data; // Flag to indicate whether the module is in receiving state
    reg [2:0] one_count; // Counter for consecutive ones (for bit stuffing)

    initial begin
        data <= 8'b0;
        data_valid <= 0;
        bit_count <= 0;
        temp_data <= 8'b0;
        processed_data <= 8'b0;
        receiving_data <= 0;
        one_count <= 0;
    end

    always @(posedge clk) begin
        if (receiving) begin
            if (!receiving_data) begin
                // Check for start frame when not already receiving data
                if (sbda == Start_frame) begin
                    receiving_data <= 1;
                    bit_count <= 0;
                    temp_data <= 8'b0;
                    processed_data <= 8'b0;
                    one_count <= 0;
                end
            end else begin
                // Data reception logic
                temp_data <= sbda;

                // Handle bit stuffing
                for (integer i = 0; i < 8; i = i + 1) begin
                    if (temp_data[i] == 1)
                        one_count <= one_count + 1;
                    else
                        one_count <= 0;

                    if (one_count == 5) begin
                        // Skip the next bit (bit stuffing removal)
                        i = i + 1;
                        one_count <= 0;
                    end else begin
                        processed_data <= {processed_data[6:0], temp_data[i]};
                    end
                end

                // Stop frame detection
                if (temp_data == Stop_frame) begin
                    // Stop frame detected
                    data <= processed_data;
                    data_valid <= 1;
                    receiving_data <= 0;
                    bit_count <= 0;
                    one_count <= 0;
                end
            end
        end else begin
            // If not receiving, reset everything
            receiving_data <= 0;
            bit_count <= 0;
            one_count <= 0;
            temp_data <= 8'b0;
            processed_data <= 8'b0;
            data_valid <= 0;
        end
    end
endmodule
