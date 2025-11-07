`timescale 1ns/1ps
// This is with ACK
//////////////////////////////////////////////////////////////////////////////////
// 1. fetch the pose/neg Edge data 
// 2. compare it with the start frame of UID or GID
// 3. i] if it match with Start frame UID   
//          * then if next Byte will be matched with UID /GID Address
// [NEW]       - Ask for double Ack i.e 1 to check respective slave is available or not another to check whether the slave is busy or free.
//             - from 2nd Byte onwords it will be consider as a Data
// [NEW]       - after each byte of data it will ask for the ACK
//          * else do nothing and start from the 1st stage again
//   ii] else if it match with Start frame GID 
//          * then if 1st Byte will be matched with UID /GID Address
// [NEW]       - Ask for double Ack i.e 1 to check respective slave is available or not another to check whether the slave is busy or free.
//             - 2nd Byte will be consider as a new GID
// [NEW]       - after each byte of data it will ask for the ACK
// [NEW]       - it after the 2nd byte the data won't be usefull.
//          * else do nothing and start from the 1st stage again
//  iii] else do nothing
//4. if any of the Edge has started accepting the data then it should signal (main_EN) the other edge.
//5. so that the other edge can tell the master that the slave device is busy and come later.
// [NEW]       -  through the 2nd ACK it can determine the slave is busy or free.



module Hcp_slave(
    input clk,
    inout sbda,
    output reg Data_Signal,
    output reg [7:0]Data,
        // Debug
    output reg [1:0] P_ACK,P_ACK_Reg, N_ACK, N_ACK_Reg,
    output reg [7:0] GID,
    output reg [3:0] P_bits_count, P_Byte, N_bits_count, N_Byte,
    output reg P_start, P_add_EN, P_main_EN, P_No_Once, N_No_Once, N_start, N_add_EN, N_main_EN, GID_write
);
    wire sbda_in;
    reg sbda_out,sbda_Output_enable; 
    reg [7:0]P_data, N_data;
    
//    reg[1:0] P_ACK,P_ACK_Reg, N_ACK, N_ACK_Reg;
//    reg [7:0] GID;
//    reg [3:0] P_bits_count, P_Byte, N_bits_count, N_Byte;
//    reg P_start, P_add_EN, P_main_EN, P_No_Once, N_No_Once, N_start, N_add_EN, N_main_EN, GID_write;
    parameter UID = 8'hAC; 
    parameter Start_frame_UID = 8'b01111110; // 01111110
    parameter Start_frame_GID = 8'b00111110; // 01111100
    parameter Stop_frame = 8'b11111110; // 01111111
    
    initial begin
        P_ACK_Reg <=0;
        N_ACK_Reg <=0;
        GID <= 0;
        N_ACK <=0;
        P_ACK <=0;
        Data <= 0;
        Data_Signal <= 0;
        N_data <= 0;
        P_bits_count <= 0;
        P_Byte <= 0;
        N_bits_count<=0;
        N_Byte<=0;
        P_start<=0;
        P_add_EN<=0;
        P_main_EN<=0;
        P_No_Once<=0;
        N_No_Once<=0;
        N_start<=0;
        N_add_EN<=0;
        N_main_EN<=0;
        GID_write<=0;
        sbda_out <= 1'bz;
        sbda_Output_enable <= 0;
    end
    
    assign sbda = sbda_Output_enable ? sbda_out : 1'bz; // sbda as output when sbda_oe is high
    assign sbda_in = sbda; // sbda as input
    
    // PosEdge
    //1
    always@(posedge clk)begin
    sbda_Output_enable = 0;
        if(P_ACK > 0)begin //Ack
            sbda_Output_enable <= 1;
            case({P_ACK,P_ACK_Reg})
            4'b0100:begin // One time ACK with no respond
            //this is used not to ACK when address doesn't match
                        P_ACK <= 0;
                        P_ACK_Reg <= 0;
                    end
            4'b0101:begin // One time ACK with respond, P_ACK = 1 P_ACK_Reg = 1, 
                       sbda_out <= 0;
                       P_ACK <= 0;
                       P_ACK_Reg <= 0;
                    end
            4'b1010:begin // two time ACK with two time respond, P_ACK = 2 P_ACK_Reg = 2, 
            //this is used to ACK address and also to indicate its free
                       sbda_out <= 0;
                       P_ACK <= 1;
                       P_ACK_Reg <= 1;
                    end
            4'b1001:begin // two time ACK with one time respond and one time no respond, P_ACK = 2 P_ACK_Reg = 1, 
            //this is used to ACK address and also to indicate its not free
                       sbda_out <= 0;
                       P_ACK <= 1;
                       P_ACK_Reg <= 0;
                    end
            endcase
            
        end
        else if(P_ACK == 0) begin 
            
            P_data = {sbda_in, P_data[7:1]}; //fetch the Raisingedge data  
            if((P_data == Start_frame_UID) && (P_main_EN == 0))begin // check for the UID start frame
                P_start = 1;
                P_add_EN = 1;
            end 
            else if((P_data == Start_frame_GID) && (P_main_EN == 0))begin // check for the GID start frame
                P_start = 1;
                P_add_EN = 1;
                GID_write = 1;
            end 
            else if(P_data == Stop_frame)begin // check for the stop frame
                P_start = 0;
                P_main_EN = 0;
                P_bits_count = 0;
                P_Byte = 0;
                GID_write = 0;
            end 
          // once start frame is detected it starts counting the Number of bits fetched in every Raising edge
          // but if it detects the stop frame it won't trigger the Data_Signal hence the current BYte won't be accepted as the data
            else if(P_start == 1)begin 
                P_bits_count = P_bits_count + 1'b1;
                if(P_bits_count == 9)begin //after each Byte of data
                    P_bits_count = 1;
                end 
                if(P_bits_count == 8)begin //after each Byte of data  
                    P_Byte = P_Byte + 1;
                    if((P_main_EN == 1)&& (GID_write == 0))begin // once the address has been matched then the next Bytes will be consider as a Data
                        Data <= P_data;
                        Data_Signal <= 1; // giving the signal to the Slave device/sensor that Byte of data has been received
                        P_ACK = 1;//ACK
                        P_ACK_Reg = 1; // 1 time ACK
                        #2 Data_Signal <= 0; 
                    end
                end
            end
        end
    end
    always@(posedge clk)begin
        if(N_ACK == 0 && N_ACK_Reg == 0)begin //Ack
            sbda_out = 1'bZ;
         end
    end
    //2
    always@* begin // after start frame is detected
        if(P_start == 1)begin
            if((P_Byte == 1) && (P_add_EN == 1))begin // after the start frame the 1st Byte will be matched with the UID or GID
                if((P_data == UID)||(P_data == GID))begin
                    if(N_main_EN == 0)begin
                        P_main_EN = 1;
                        P_add_EN = 0;
                        P_ACK = 2;//ACK
                        P_ACK_Reg = 2;//double ACK [0,0] available, free
                    end
                    else begin
                        P_add_EN = 0;
                        P_ACK = 2;//ACK
                        P_ACK_Reg = 1;//double ACK [0,1] available, busy
                    end 
                end 
                else begin // if the 1st Byte doesn't match with UID or GID then everything starts again
                   P_start = 0; 
                   P_add_EN = 0;
                   P_bits_count = 0;
                   P_Byte = 0;
                   P_ACK = 1;//ACK
                   P_ACK_Reg = 0;//No ACK [1] NOT available
                end
            end
          //if it detects the GID start frame and address then 2nd Byte will be consider as a new GID
            else if((P_Byte == 2) && (P_main_EN == 1) && (GID_write == 1))begin 
                GID = P_data;
                GID_write = 0;
                P_ACK = 1;//ACK
                P_ACK_Reg = 1; // 1 time ACK
            end 
        end
    end

    // NegEdge
    //1
    always@(negedge clk)begin
    sbda_Output_enable = 0;
        if(N_ACK > 0)begin //Ack
            sbda_Output_enable <= 1;
            case({N_ACK,N_ACK_Reg})
            4'b0100:begin // One time ACK with no respond
            //this is used not to ACK when address doesn't match
                       N_ACK = 0;
                       N_ACK_Reg = 0;
                    end
            4'b0101:begin // One time ACK with respond, P_ACK = 1 P_ACK_Reg = 1, 
            //this is used to ACK 1 Byte of data
                       sbda_out = 0;
                       N_ACK = 0;
                       N_ACK_Reg = 0;
                           //#5 sbda_out = 1'bz;
                    end
            4'b1010:begin // two time ACK with two time respond, P_ACK = 2 P_ACK_Reg = 2, 
            //this is used to ACK address and also to indicate its free
                       sbda_out = 0; 
                       N_ACK = 1;
                       N_ACK_Reg = 1;
                    end
            4'b1001:begin // two time ACK with one time respond and one time no respond, P_ACK = 2 P_ACK_Reg = 1, 
            //this is used to ACK address and also to indicate its not free 
                       sbda_out <= 0;
                       N_ACK <= 1;
                       N_ACK_Reg <= 0;
                    end
            endcase
            
        end
        else if(N_ACK ==0) begin 
            N_data = {sbda_in, N_data[7:1]}; //fetch the Raisingedge data  
            if((N_data == Start_frame_UID) && (N_main_EN == 0))begin // check for the UID start frame
                N_start = 1;
                N_add_EN = 1;
            end 
            else if((N_data == Start_frame_GID) && (N_main_EN == 0))begin // check for the GID start frame
                N_start = 1;
                N_add_EN = 1;
                GID_write = 1;
            end 
            else if(N_data == Stop_frame)begin // check for the stop frame
                N_start = 0;
                N_main_EN = 0;
                N_bits_count = 0;
                N_Byte = 0;
                GID_write = 0;
            end 
          // once start frame is detected it starts counting the Number of bits fetched in every Raising edge
          // but if it detects the stop frame it won't trigger the Data_Signal hence the current BYte won't be accepted as the data
            else if(N_start == 1)begin 
                N_bits_count = N_bits_count + 1'b1;
                if(N_bits_count == 9)begin //after each Byte of data
                    N_bits_count = 1;
                end 
                if(N_bits_count == 8)begin //after each Byte of data  
                    N_Byte = N_Byte + 1;
                    if((N_main_EN == 1)&& (GID_write == 0))begin // once the address has been matched then the next Bytes will be consider as a Data
                        Data <= N_data;
                        Data_Signal <= 1; // giving the signal to the Slave device/sensor that Byte of data has been received
                        N_ACK = 1;//ACK
                        N_ACK_Reg = 1; // 1 time ACK
                        #2 Data_Signal <= 0; 
                    end
                end
            end
        end
    end
    
    //2
    always@* begin // after start frame is detected
        if(N_start == 1)begin
            if((N_Byte == 1) && (N_add_EN == 1))begin // after the start frame the 1st Byte will be matched with the UID or GID
                if((N_data == UID)||(N_data == GID))begin
                    if(P_main_EN == 0)begin
                        N_main_EN = 1;
                        N_add_EN = 0;
                        N_ACK = 2;//ACK
                        N_ACK_Reg = 2;//double ACK [0,0] available, free
                    end
                    else begin
                        N_add_EN = 0;
                        N_ACK = 2;//ACK
                        N_ACK_Reg = 1;//double ACK [0,1] available, busy
                    end 
                end 
                else begin // if the 1st Byte doesn't match with UID or GID then everything starts again
                   N_start = 0; 
                   N_add_EN = 0;
                   N_bits_count = 0;
                   N_Byte = 0;
                   N_ACK = 1;//ACK
                   N_ACK_Reg = 0;//No ACK [1] NOT available
                end
            end
          //if it detects the GID start frame and address then 2nd Byte will be consider as a new GID
            else if((N_Byte == 2) && (N_main_EN == 1) && (GID_write == 1))begin 
                GID = N_data;
                GID_write = 0;
                N_ACK = 1;//ACK
                N_ACK_Reg = 1; // 1 time ACK
            end 
        end
    end
    always@(negedge clk)begin
        if(P_ACK == 0 && P_ACK_Reg == 0)begin //Ack
            sbda_out = 1'bZ;
         end
    end
endmodule
