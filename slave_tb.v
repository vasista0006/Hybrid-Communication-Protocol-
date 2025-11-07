`timescale 1ns/1ps
//////////////////////////////////////////test bench /////////////////////////////////////////////////////////////

//module Slave_tb();
//reg clk;
//reg sbda_out;
//reg wr;
//wire sbda;
//wire Data_Signal;
//wire [7:0]Data;

//assign sbda = wr? sbda_out:1'bz; // Bidirectional signal handling
//Slave test(clk, sbda, Data_Signal, Data);

// Debug
module slave_tb();
reg clk;
reg sbda_out;
reg wr;
wire sbda;
wire Data_Signal;
wire [7:0]Data;
wire [1:0] P_ACK,P_ACK_Reg, N_ACK, N_ACK_Reg;
wire [7:0] GID;
wire [3:0] P_bits_count, P_Byte, N_bits_count, N_Byte;
wire P_start, P_add_EN, P_main_EN, P_No_Once, N_No_Once, N_start, N_add_EN, N_main_EN, GID_write;

assign sbda = wr? sbda_out:1'bZ; // Bidirectional signal handling

Hcp_slave test(clk, sbda, Data_Signal, Data, P_ACK,P_ACK_Reg, N_ACK, N_ACK_Reg, GID, P_bits_count, P_Byte, N_bits_count, N_Byte, P_start, P_add_EN, P_main_EN, P_No_Once, N_No_Once, N_start, N_add_EN, N_main_EN, GID_write);
initial begin
        clk = 0;
        sbda_out = 1'bZ;
        wr = 1;
        #100;
        // sending the data
//        send_byte_n(8'b01111110); // start frame
//        send_byte_n(8'hAC); // 0xAC Slave Address
//        wait_ack(2);
//        send_byte_n(8'b01111110); // data 0x55
//        wait_ack(1);
//        send_byte_n(8'b10101010); // data 0xAA
//        wait_ack(1);
//        send_byte_n(8'b11111110); // End frame
        
//        // sending the GID and then the data
//        send_byte_n(8'b00111110); // start frame GID
//        send_byte_n(8'hAC); // 0xAC Slave Address
//        wait_ack(2);
//        send_byte_n(8'hE5); // updating 0xFA as a Group Address
//        wait_ack(1);
//        send_byte_n(8'b11111110); // End frame
        
//        send_byte_n(8'b01111110); // start frame 
//        send_byte_n(8'hE5); // Group Address 11111010
//        wait_ack(2);
//        send_byte_n(8'b01010101); // data 0x55
//        wait_ack(1);
//        send_byte_n(8'b10101010); // data 0xAA
//        wait_ack(1);
//        send_byte_n(8'b11111110); // End frame
        
    end
    
    initial begin
        #105;
        // sending the data
//        send_byte_p(8'b01111110); // start frame
//        send_byte_p(8'hAC); // 0xAC Slave Address
//        wait_ack(2);
//        send_byte_p(8'b10101010); // data 0xAA
//        wait_ack(1);
//        send_byte_p(8'b11111110); // End frame
        
        // sending the GID and then the data
        send_byte_p(8'b00111110); // start frame GID
        send_byte_p(8'hAC); // 0xAC Slave Address
        wait_ack(2);
        send_byte_p(8'hE5); // updating 0xFA as a Group Address
        wait_ack(1);
        send_byte_p(8'b11111110); // End frame
        
        send_byte_p(8'b01111110); // start frame 
        send_byte_p(8'hE5); // Group Address 11111010
        wait_ack(2);
        send_byte_p(8'b01010101); // data 0x55
        wait_ack(1);
        send_byte_p(8'b10101010); // data 0xAA
        wait_ack(1);
        send_byte_p(8'b11111110); // End frame
        
    end
    
    initial begin
    // Clock generation
    forever #5 clk = ~clk;
    end
   
    // Task to send a byte over the sbda line
    task send_byte_p;
        input [7:0] byte;
        integer i;
        begin
            wr =1;
            for (i = 0; i < 8; i = i + 1) begin
                #10 sbda_out = byte[i];
            end
            //wr =0;
        end
    endtask
    task send_byte_n;
        input [7:0] byte;
        integer i;
        begin
            wr =1;
            for (i = 0; i < 8; i = i + 1) begin
                #10 sbda_out = byte[i];
            end
            //wr =0;
        end
    endtask
    // Task to wait for a certain number of ACKs
    task wait_ack;
        input integer num_ack;
        integer i;
        begin
            wr =1;
            for (i = 0; i < num_ack; i = i + 1) begin
                #10 sbda_out = 1'bZ; // Adjust this delay to match your system timing
            end
        end
    endtask
endmodule