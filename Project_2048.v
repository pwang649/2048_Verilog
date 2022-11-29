`timescale 1ns / 1ps

module Project_2048 (ClkPort,vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, Sw0, Sw1, Sw2, btnU, btnD, btnL, btnR, St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar); // , Done

input ClkPort, Sw0, Sw1, Sw2, btnU, btnD, btnL, btnR, Sw2;
output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar; //Done,


reg [11:0] Matrix[15:0];

reg [10:0] randCount;
reg [1:0] counterMove, counterMerge;
reg [3:0] buttonValue; 
reg [5:0] state;
reg flagDone;  
reg [3:0] randNum;

wire [191:0] MatrixCopy;   //Flatten out Matrix
wire Reset, Start, SymClk, Ack;
wire DPB, MCEN, CCEN, DbtnU, DbtnD, DbtnL, DbtnR;
wire vga_r, vga_g, vga_b; 
//Flag may be needed for Moved and Merged to generate new number

integer i, j;

BUF BUF1 (SymClk, ClkPort); 	
BUF BUF2 (Reset, Sw0);
BUF BUF3 (Start, Sw1);
BUF BUF4 (Ack, Sw2);	

localparam
INI 	= 6'b000001,
Gen     = 6'b000100,
Wait	= 6'b001000,
Merge	= 6'b010000,
Done	= 6'b100000;


//Check for Win/Lose
assign check_over = ((Matrix[0] !== Matrix[1]) && (Matrix[0] !== Matrix[4]) && (Matrix[1] !== Matrix[5]) && (Matrix[1] !== Matrix[2]) &&(Matrix[2] !== Matrix[6]) &&
	(Matrix[2] !== Matrix[3]) && (Matrix[3] !== Matrix[7]) && (Matrix[4] !== Matrix[5]) && (Matrix[4] !== Matrix[8]) && (Matrix[5] !== Matrix[9]) && 
	(Matrix[5] !== Matrix[6]) && (Matrix[6] !== Matrix[7]) && (Matrix[6] !== Matrix[10]) && (Matrix[7] !== Matrix[11]) && (Matrix[8] !== Matrix[9]) && 
	(Matrix[8] !== Matrix[12]) && (Matrix[9] !== Matrix[10]) && (Matrix[9] !== Matrix[13]) && (Matrix[10] !== Matrix[14]) && (Matrix[10] !== Matrix[11]) && 
	(Matrix[11] !== Matrix[15]) && (Matrix[12] !== Matrix[13]) && (Matrix[13] !== Matrix[14]) && (Matrix[14] !== Matrix[15])&&(Matrix[0] !== 0)&&
	(Matrix[1] !== 0)&&(Matrix[2] !== 0)&&(Matrix[3] !== 0)&&(Matrix[4] !== 0)&&(Matrix[5] !== 0)
	&&(Matrix[6] !== 0)&&(Matrix[7] !== 0)&&(Matrix[8] !== 0)&&(Matrix[9] !== 0)&&(Matrix[10] !== 0)
	&&(Matrix[11] !== 0)&&(Matrix[12] !== 0)&&(Matrix[13] !== 0)&&(Matrix[14] !== 0)&&(Matrix[15] !== 0));

assign checkWin = ((Matrix[0] == 256) || (Matrix[1] == 256) || (Matrix[2] == 256) || (Matrix[3] == 256) || (Matrix[4] == 256) || (Matrix[5] == 256) || (Matrix[6] == 256) || (Matrix[7] == 256) || 
(Matrix[8] == 256) || (Matrix[9] == 256) || (Matrix[10] == 256) || (Matrix[11] == 256) || (Matrix[12] == 256) || (Matrix[13] == 256) || (Matrix[14] == 256) || (Matrix[15] == 256));
	

//Flatten out the Matrix
assign MatrixCopy = {Matrix[15],Matrix[14],Matrix[13],Matrix[12],Matrix[11],Matrix[10],Matrix[9],
						Matrix[8],Matrix[7],Matrix[6],Matrix[5],Matrix[4],Matrix[3],Matrix[2],Matrix[1],Matrix[0]};



//Connection. Instantation
ee201_debouncer ButtonDown(.CLK(SymClk), .RESET(Reset), .PB(btnD), .DPB(DPB), .SCEN(DbtnD), .MCEN(MCEN), .CCEN(CCEN));
ee201_debouncer ButtonUp(.CLK(SymClk), .RESET(Reset), .PB(btnU), .DPB(DPB), .SCEN(DbtnU), .MCEN(MCEN), .CCEN(CCEN));
ee201_debouncer ButtonLeft(.CLK(SymClk), .RESET(Reset), .PB(btnL), .DPB(DPB), .SCEN(DbtnL), .MCEN(MCEN), .CCEN(CCEN));
ee201_debouncer ButtonRight(.CLK(SymClk), .RESET(Reset), .PB(btnR), .DPB(DPB), .SCEN(DbtnR), .MCEN(MCEN), .CCEN(CCEN));
	
vga_demo VGATEST (.board_clk(SymClk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync),
 .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b), .reset(Reset),.Done(flagDone),.MatrixCopy(MatrixCopy),
 .St_ce_bar(St_ce_bar), .St_rp_bar(St_rp_bar), .Mt_ce_bar(Mt_ce_bar), .Mt_St_oe_bar(Mt_St_oe_bar), .Mt_St_we_bar(Mt_St_we_bar));  //
	
	
//Counter for Random Number
always @ (posedge SymClk, posedge Reset)
	begin
		if (Reset)
			randCount <= 0;
		else if (randCount == 4'b1111)
			randCount <= 0;
		else
			randCount <= randCount + 1;
	end



always @ (posedge SymClk, posedge Reset) 
	begin
		if (Reset)
			state <= INI;
		else
			begin
				case(state)
					INI:
						begin
							//state transition
							if (Start) 
								state <= Gen;
								
							//RTL
							randNum <= randCount[3:0];
							
							flagGen <= 1;
							buttonValue <= 0;
							flagDone <= 0;
							for (i=0; i<16; i= i+1)
								Matrix[i] <= 0;
							Matrix[randCount[3:0]] <= 2;
						end				
					Gen:
						begin
							//state transition
							if (check_over || checkWin)
								state <= Done;
							else if (Matrix[randNum] == 0)
								state <= Wait;
							//RTL
							randNum <= randCount[3:0];
							if (Matrix[randNum] == 0)
								Matrix[randNum] <= 2;
						end
					
					Wait:
						if (DbtnU || DbtnD || DbtnL || DbtnR)
							state <= Merge;

						if (DbtnU) buttonValue <= 4'b0001;
						if (DbtnD) buttonValue <= 4'b0010;
						if (DbtnL) buttonValue <= 4'b0100;
						if (DbtnR) buttonValue <= 4'b1000;

						counterMove <= 0;
						counterMerge <= 0;

					Merge:
						begin
							//state transition
							state <= Wait;							
							
							//RTL
							// counterMove = 1; // How many 
							//UP MOVE
							if (buttonValue == 4'b0001)  //UP Pressed
								begin
									for (c = 0; c < 4; c = c + 1) // Check for every row
										begin
											for (r = 0; r < 4; r = r + 1) // Check for every column
												begin
												if (Matrix[4*r+c] != 0) // If this square is not empty
													begin 
													counterMove = 1;  // A counter for how many numbered squares are on the right of this square
													for (i = r + 1; i <= 3; i = i + 1) // Check all square on the right of our square
														begin
															if (Matrix[4*i+c] != 0) // If there is a square on our right that filled
																begin
																	if (Matrix[4*r+c] == Matrix[4*i+c]) // If that square is the same as ours, 
																		begin
																			// We merge
																			Matrix[4*r+c] = Matrix[4*r+c] * 2; // Merging into our square
																			Matrix[4*i+c] = 0; // Clearing that square
																		end
																	else // If that square is NOT the same as ours
																		// Instead of merging, we move that square to the left
																		begin
																			Matrix[4*(r + counterMove)+c] = Matrix[4*i+c]; // Move that square to the CORRECT location
																			Matrix[4*i+c] = 0; // Clear that square's original location
																			counterMove = counterMove + 1; // Increment counter to mark CORRECT location for the next square on the right
																		end
																end
														end 
													end 
												end
										end
								end
								
							//DOWN MOVE
							if (buttonValue == 4'b0010)  //DOWN Pressed
								begin
									for (c = 0; c < 4; c = c + 1) // Check for every row
										begin
											for (r = 3; r >= 0; r = r - 1) // Check for every column
												begin
												if (Matrix[4*r+c] != 0) // If this square is not empty
													begin 
													counterMove = 1;  // A counter for how many numbered squares are on the right of this square
													for (i = r - 1; i >= 0; i = i - 1) // Check all square on the right of our square
														begin
															if (Matrix[4*i+c] != 0) // If there is a square on our right that filled
																begin
																	if (Matrix[4*r+c] == Matrix[4*i+c]) // If that square is the same as ours, 
																		begin
																			// We merge
																			Matrix[4*r+c] = Matrix[4*r+c] * 2; // Merging into our square
																			Matrix[4*i+c] = 0; // Clearing that square
																		end
																	else // If that square is NOT the same as ours
																		// Instead of merging, we move that square to the left
																		begin
																			Matrix[4*(r - counterMove)+c] = Matrix[4*i+c]; // Move that square to the CORRECT location
																			Matrix[4*i+c] = 0; // Clear that square's original location
																			counterMove = counterMove + 1; // Increment counter to mark CORRECT location for the next square on the right
																		end
																end
														end 
													end 
												end
										end
								end
								
							//LEFT MOVE
							if (buttonValue == 4'b0100)  //LEFT Pressed
								begin
									for (r = 0; r < 4; r = r + 1) // Check for every row
										begin
											for (c = 0; c < 4; c = c + 1) // Check for every column
												begin
												if (Matrix[4*r+c] != 0) // If this square is not empty
													begin 
													counterMove = 1;  // A counter for how many numbered squares are on the right of this square
													for (i = c + 1; i <= 3; i = i + 1) // Check all square on the right of our square
														begin
															if (Matrix[4*r+i] != 0) // If there is a square on our right that filled
																begin
																	if (Matrix[4*r+c] == Matrix[4*r+i]) // If that square is the same as ours, 
																		begin
																			// We merge
																			Matrix[4*r+c] = Matrix[4*r+c] * 2; // Merging into our square
																			Matrix[4*r+i] = 0; // Clearing that square
																		end
																	else // If that square is NOT the same as ours
																		// Instead of merging, we move that square to the left
																		begin
																			Matrix[4*r+c + counterMove] = Matrix[4*r+i]; // Move that square to the CORRECT location
																			Matrix[4*r+i] = 0; // Clear that square's original location
																			counterMove = counterMove + 1; // Increment counter to mark CORRECT location for the next square on the right
																		end
																end
														end 
													end 
												end
										end
								end
								
							//RIGHT MOVE
							if (buttonValue == 4'b1000)  //RIGHT Pressed
								begin
									for (r = 0; r < 4; r = r + 1) // Check for every row
										begin
											for (c = 3; c >= 0; c = c - 1) // Check for every column
												begin
												if (Matrix[4*r+c] != 0) // If this square is not empty
													begin 
													counterMove = 1;  // A counter for how many numbered squares are on the right of this square
													for (i = c - 1; i >= 0; i = i - 1) // Check all square on the right of our square
														begin
															if (Matrix[4*r+i] != 0) // If there is a square on our right that filled
																begin
																	if (Matrix[4*r+c] == Matrix[4*r+i]) // If that square is the same as ours, 
																		begin
																			// We merge
																			Matrix[4*r+c] = Matrix[4*r+c] * 2; // Merging into our square
																			Matrix[4*r+i] = 0; // Clearing that square
																		end
																	else // If that square is NOT the same as ours
																		// Instead of merging, we move that square to the left
																		begin
																			Matrix[4*r+c - counterMove] = Matrix[4*r+i]; // Move that square to the CORRECT location
																			Matrix[4*r+i] = 0; // Clear that square's original location
																			counterMove = counterMove + 1; // Increment counter to mark CORRECT location for the next square on the right
																		end
																end
														end 
													end 
												end
										end
								end
						end
						
					Done:
						begin
							//state transition
							if (Ack)
								state <= INI;

							flagDone <= 1;
						end
					
				endcase		
			end				
							
	end					
			
endmodule
