`timescale 1ns / 1ps

module block_controller(
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input bright,
	input up, down, left, right,
	input rst,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background
   );
	wire grid_fill;
	reg num_fill;
	reg [11:0] Matrix[15:0];
	reg [3:0] mi;
	reg vga_r, vga_g, vga_b;
	reg [10:0] randCount;
	reg [1:0] counterMove, counterMerge;
	reg [3:0] buttonValue; 
	reg [5:0] state;
	reg flagDone;  
	reg [3:0] randNum;
	wire [191:0] MatrixCopy;   //Flatten out Matrix
	wire Reset, Start, SymClk, Ack;
	wire DPB, MCEN, CCEN, DbtnU, DbtnD, DbtnL, DbtnR;
	
	integer i, j, r, c, quit;

	//BUF BUF1 (SymClk, clk); 	
	//BUF BUF2 (rst, );	
	//BUF BUF3 (Start, Sw1);
	//BUF BUF4 (Ack, Sw2);

	localparam
	INI 	= 6'b000001,
	Gen     = 6'b000100,
	Wait	= 6'b001000,
	Merge	= 6'b010000,
	Done	= 6'b100000;
	
	
	//Check for Win/Lose
	assign check_over = ((Matrix[0] != Matrix[1]) && (Matrix[0] != Matrix[4]) && (Matrix[1] != Matrix[5]) && (Matrix[1] != Matrix[2]) &&(Matrix[2] != Matrix[6]) &&
		(Matrix[2] != Matrix[3]) && (Matrix[3] != Matrix[7]) && (Matrix[4] != Matrix[5]) && (Matrix[4] != Matrix[8]) && (Matrix[5] != Matrix[9]) && 
		(Matrix[5] != Matrix[6]) && (Matrix[6] != Matrix[7]) && (Matrix[6] != Matrix[10]) && (Matrix[7] != Matrix[11]) && (Matrix[8] != Matrix[9]) && 
		(Matrix[8] != Matrix[12]) && (Matrix[9] != Matrix[10]) && (Matrix[9] != Matrix[13]) && (Matrix[10] != Matrix[14]) && (Matrix[10] != Matrix[11]) && 
		(Matrix[11] != Matrix[15]) && (Matrix[12] != Matrix[13]) && (Matrix[13] != Matrix[14]) && (Matrix[14] != Matrix[15])&&(Matrix[0] != 0)&&
		(Matrix[1] != 0)&&(Matrix[2] != 0)&&(Matrix[3] != 0)&&(Matrix[4] != 0)&&(Matrix[5] != 0)
		&&(Matrix[6] != 0)&&(Matrix[7] != 0)&&(Matrix[8] != 0)&&(Matrix[9] != 0)&&(Matrix[10] != 0)
		&&(Matrix[11] != 0)&&(Matrix[12] != 0)&&(Matrix[13] != 0)&&(Matrix[14] != 0)&&(Matrix[15] != 0));

	assign checkWin = ((Matrix[0] == 256) || (Matrix[1] == 256) || (Matrix[2] == 256) || (Matrix[3] == 256) || (Matrix[4] == 256) || (Matrix[5] == 256) || (Matrix[6] == 256) || (Matrix[7] == 256) || 
	(Matrix[8] == 256) || (Matrix[9] == 256) || (Matrix[10] == 256) || (Matrix[11] == 256) || (Matrix[12] == 256) || (Matrix[13] == 256) || (Matrix[14] == 256) || (Matrix[15] == 256));
	
	//Flatten out the Matrix
	assign MatrixCopy = {Matrix[15],Matrix[14],Matrix[13],Matrix[12],Matrix[11],Matrix[10],Matrix[9], Matrix[8],Matrix[7],Matrix[6],Matrix[5],Matrix[4],Matrix[3],Matrix[2],Matrix[1],Matrix[0]};

	//Connection. Instantation
	ee354_debouncer ButtonDown(.CLK(clk), .RESET(rst), .PB(down), .DPB(DPB), .SCEN(DbtnD), .MCEN(MCEN), .CCEN(CCEN));
	ee354_debouncer ButtonUp(.CLK(clk), .RESET(rst), .PB(up), .DPB(DPB), .SCEN(DbtnU), .MCEN(MCEN), .CCEN(CCEN));
	ee354_debouncer ButtonLeft(.CLK(clk), .RESET(rst), .PB(left), .DPB(DPB), .SCEN(DbtnL), .MCEN(MCEN), .CCEN(CCEN));
	ee354_debouncer ButtonRight(.CLK(clk), .RESET(rst), .PB(right), .DPB(DPB), .SCEN(DbtnR), .MCEN(MCEN), .CCEN(CCEN));
	
	//Counter for Random Number
	always @ (posedge clk, posedge rst)
		begin
			if (rst)
				randCount <= 0;
			else if (randCount == 4'b1111)
				randCount <= 0;
			else
				randCount <= randCount + 1;
		end

	
always @ (posedge clk, posedge rst) 
	begin
		if (rst)
			state <= INI;
		else
			begin
				case(state)
					INI:
						begin
							//state transition
							//if (Start) 
							state <= Gen;
								
							//RTL
							randNum <= randCount[3:0];
							
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
						begin
							if (DbtnU || DbtnD || DbtnL || DbtnR)
								state <= Merge;

							if (DbtnU)
								buttonValue <= 4'b0001;
							if (DbtnD) 
								buttonValue <= 4'b0010;
							if (DbtnL) 
								buttonValue <= 4'b0100;
							if (DbtnR) 
								buttonValue <= 4'b1000;

							counterMove <= 0;
							counterMerge <= 0;
						end
					Merge:
						begin
							//state transition
							state <= Gen;							
							
							//RTL
							// counterMove = 1; // How many 
							//UP MOVE
							if (buttonValue == 4'b0001)  //UP Pressed
								begin
									for (c = 0; c < 4; c = c + 1)
										begin
											for (r = 0; r < 3; r = r + 1)
												begin
													if (Matrix[4*r+c] == 0)
														begin
															quit = 0;
															for (i = r + 1; i < 4; i = i + 1)
																begin
																	if ((Matrix[4*i+c] != 0) && (quit == 0))
																		begin
																			Matrix[4*r+c] = Matrix[4*i+c];
																			Matrix[4*i+c] = 0;
																			quit = 1;
																		end
																end
														end
												end
											
											for (r = 0; r < 3; r = r + 1)
												begin
													if (Matrix[4*r+c] == Matrix[4*(r+1)+c])
														begin
															Matrix[4*r+c] = 2 * Matrix[4*r+c];
															for (i = r + 2; i < 4; i = i + 1)
																begin
																	Matrix[4*(i-1)+c] = Matrix[4*i+c];
																	Matrix[4*i+c] = 0;
																end
														end
												end
										end
								end
								
							//DOWN MOVE
							if (buttonValue == 4'b0010)  //DOWN Pressed
								begin
									for (c = 0; c < 4; c = c + 1)
										begin
											for (r = 3; r > 0; r = r - 1)
												begin
													if (Matrix[4*r+c] == 0)
														begin
															quit = 0;
															for (i = r - 1; i >= 0; i = i - 1)
																begin
																	if ((Matrix[4*i+c] != 0) && (quit == 0))
																		begin
																			Matrix[4*r+c] = Matrix[4*i+c];
																			Matrix[4*i+c] = 0;
																			quit = 1;
																		end
																end
														end
												end
											
											for (r = 3; r > 0; r = r - 1)
												begin
													if (Matrix[4*r+c] == Matrix[4*(r-1)+c])
														begin
															Matrix[4*r+c] = 2 * Matrix[4*r+c];
															for (i = r - 2; i >= 0; i = i - 1)
																begin
																	Matrix[4*(i+1)+c] = Matrix[4*i+c];
																	Matrix[4*i+c] = 0;
																end
														end
												end
										end
								end
								
							//LEFT MOVE
							if (buttonValue == 4'b0100)  //LEFT Pressed
								begin
									for (r = 0; r < 4; r = r + 1)
										begin
											for (c = 0; c < 3; c = c + 1)
												begin
													if (Matrix[4*r+c] == 0)
														begin
															quit = 0;
															for (i = c + 1; i < 4; i = i + 1)
																begin
																	if ((Matrix[4*r+i] != 0) && (quit == 0))
																		begin
																			Matrix[4*r+c] = Matrix[4*r+i];
																			Matrix[4*r+i] = 0;
																			quit = 1;
																		end
																end
														end
												end
											
											for (c = 0; c < 3; c = c + 1)
												begin
													if (Matrix[4*r+c] == Matrix[4*r+c+1])
														begin
															Matrix[4*r+c] = 2 * Matrix[4*r+c];
															for (i = c + 2; i < 4; i = i + 1)
																begin
																	Matrix[4*r+i-1] = Matrix[4*r+i];
																	Matrix[4*r+i] = 0;
																end
														end
												end
										end
								end
								
							//RIGHT MOVE
							if (buttonValue == 4'b1000)  //RIGHT Pressed
								begin
									for (r = 0; r < 4; r = r + 1)
										begin
											for (c = 3; c > 0; c = c - 1)
												begin
													if (Matrix[4*r+c] == 0)
														begin
															quit = 0;
															for (i = c - 1; i >= 0; i = i - 1)
																begin
																	if ((Matrix[4*r+i] != 0) && (quit == 0))
																		begin
																			Matrix[4*r+c] = Matrix[4*r+i];
																			Matrix[4*r+i] = 0;
																			quit = 1;
																		end
																end
														end
												end
											
											for (c = 3; c > 0; c = c - 1)
												begin
													if (Matrix[4*r+c] == Matrix[4*r+c-1])
														begin
															Matrix[4*r+c] = 2 * Matrix[4*r+c];
															for (i = c - 2; i >= 0; i = i - 1)
																begin
																	Matrix[4*r+i+1] = Matrix[4*r+i];
																	Matrix[4*r+i] = 0;
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
	
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	reg [10:0] positionX, positionY;
	
	parameter RED   = 12'b1111_0000_0000;
	parameter BLUE = 12'b0000_0000_1111;
	
	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000;
		else if (grid_fill) 
			rgb = RED; 
		else if (num_fill)
			rgb=BLUE;
		else
			rgb = 12'b1111_1111_1111;
	end
		
		
	// Grid Fill Boolean Calculation Starts Here Added 194 to Hcount, 35 to vCount
	assign grid_fill = (((hCount>194 && hCount<674&& vCount>=35 && vCount<=40)
	||(hCount>194 && hCount<674 && vCount>=150 && vCount<=160)
	||(hCount>194 && hCount<674 && vCount>=270 && vCount<=280)
	||(hCount>194 && hCount<674 && vCount>=390 && vCount<=400)
	||(hCount>194 && hCount<674 && vCount>=510 && vCount<=520))
	||((vCount>35&& vCount<515 && hCount>=194 && hCount<=199)
	||(vCount>35 && vCount<515 && hCount>=309 && hCount<=319)
	||(vCount>35&& vCount<515 && hCount>=429 && hCount<=439)
	||(vCount>35 && vCount<515 && hCount>=549 && hCount<=559)
	||(vCount>35&& vCount<515 && hCount>=669 && hCount<=679)));
	
	
	// Number Fill Boolean Calculation
	always @(hCount, vCount, Matrix)
		begin

			if ((hCount <314) && (vCount < 155))
				begin
					positionX = 194;
					positionY = 35;
					i = 0;
				end
			
			if ((hCount <434) && (hCount >314) && (vCount < 155)) 
				begin
					positionX = 314;
					positionY = 35;
					i = 1;
				end
			
			if ((hCount <554) && (hCount >434) && (vCount < 155)) 
				begin
					positionX = 434;
					positionY = 35;
					i = 2;
				end
			
			if ((hCount <674) && (hCount >554) && (vCount < 155) )
			begin
				positionX = 554;
				positionY = 35;
				i = 3 ;
			end
			//Second ROW
			if ((hCount <314) && (vCount >155) && (vCount <275)) 
			begin
				positionX = 194;
				positionY = 155;
				i = 4;
			end
			
			if ((hCount <434) && (hCount >314) && (vCount >155) && (vCount <275)) 
			begin
				positionX = 314;
				positionY = 155;
				i = 5;
			end
			
			if ((hCount <554) && (hCount >434) && (vCount >155) && (vCount <275)) 
			begin
				positionX = 434;
				positionY = 155;
				i = 6;
			end
			
			if ((hCount <674) && (hCount >554) && (vCount >155) && (vCount <275))
			begin
				positionX = 554;
				positionY = 155;
				i = 7;
			end

			//Third Row
			if ((hCount <314) && (vCount >275) && (vCount <395)) 
			begin
				positionX = 194;
				positionY = 275;
				i = 8;
			end	
			if ((hCount <434) && (hCount >314) && (vCount >275) && (vCount <395)) 
			begin
				positionX = 314;
				positionY = 275;
				i = 9;
			end
			
			if ((hCount <554) && (hCount >434) && (vCount >275) && (vCount <395)) 
			begin
				positionX = 434;
				positionY = 275;
				i = 10;
			end
			
			if ((hCount <674) && (hCount >554) && (vCount >275) && (vCount <395))
			begin
				positionX = 554;
				positionY = 275;
				i = 11;
			end
			
			//Fourth Row
			if ((hCount <314) && (vCount >395) && (vCount <515)) 
			begin
				positionX = 194;
				positionY = 395;
				i = 12;
			end
			
			if ((hCount <434) && (hCount >314) && (vCount >395) && (vCount <515) )
			begin
				positionX = 314;
				positionY = 395;
				i = 13;
			end
			
			if ((hCount <554) && (hCount >434) && (vCount >395) && (vCount <515)) 
			begin
				positionX = 434;
				positionY = 395;
				i = 14;
			end
			
			if ((hCount <674) && (hCount >554) && (vCount >395) && (vCount <515))
			begin
				positionX = 554;
				positionY = 395;
				i = 15;
			end


			//CASE for Numbers
			case(Matrix[i])
				2:  num_fill = ((hCount>=(positionX+40) && hCount<=(positionX+80) && vCount>=(10+positionY) && vCount<=(14+positionY))
				||(hCount>=(positionX+40) && hCount<=(positionX+80) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+40) && hCount<=(positionX+80) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+40) && hCount<=(positionX+44) && vCount>=(58+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+76) && hCount<=(positionX+80) && vCount>=(10+positionY) && vCount<=(62+positionY))
					); 				   
				
				4:  num_fill = ((hCount>=(positionX+40) && hCount<=(positionX+80) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+40) && hCount<=(positionX+44) && vCount>=(10+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+76) && hCount<=(positionX+80) && vCount>=(10+positionY) && vCount<=(104+positionY))
					);

				8:  num_fill = ((hCount>=(positionX+40) && hCount<=(positionX+80) && vCount>=(10+positionY) && vCount<=(14+positionY))
				||(hCount>=(positionX+40) && hCount<=(positionX+80) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+40) && hCount<=(positionX+80) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+40) && hCount<=(positionX+44) && vCount>=(10+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+76) && hCount<=(positionX+80) && vCount>=(10+positionY) && vCount<=(104+positionY))
					); 
				16:  num_fill = ((hCount>=(positionX+50) && hCount<=(positionX+80) && vCount>=(10+positionY) && vCount<=(14+positionY)) //6
				||(hCount>=(positionX+50) && hCount<=(positionX+80) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+50) && hCount<=(positionX+80) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+50) && hCount<=(positionX+54) && vCount>=(10+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+76) && hCount<=(positionX+80) && vCount>=(58+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+30) && hCount<=(positionX+34) && vCount>=(10+positionY) && vCount<=(104+positionY)) //1
					); 		
				32:  num_fill = ((hCount>=(positionX+55) && hCount<=(positionX+100) && vCount>=(10+positionY) && vCount<=(14+positionY))
				||(hCount>=(positionX+55) && hCount<=(positionX+100) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+55) && hCount<=(positionX+100) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+55) && hCount<=(positionX+59) && vCount>=(58+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+96) && hCount<=(positionX+100) && vCount>=(10+positionY) && vCount<=(62+positionY)) //2
				||(hCount>=(positionX+10) && hCount<=(positionX+45) && vCount>=(10+positionY) && vCount<=(14+positionY))
				||(hCount>=(positionX+10) && hCount<=(positionX+45) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+10) && hCount<=(positionX+45) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+41) && hCount<=(positionX+45) && vCount>=(10+positionY) && vCount<=(104+positionY))
					);		
				64: num_fill = ((hCount>=(positionX+10) && hCount<=(positionX+45) && vCount>=(10+positionY) && vCount<=(14+positionY)) //6
				||(hCount>=(positionX+10) && hCount<=(positionX+45) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+10) && hCount<=(positionX+45) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+10) && hCount<=(positionX+14) && vCount>=(10+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+41) && hCount<=(positionX+45) && vCount>=(58+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+55) && hCount<=(positionX+100) && vCount>=(58+positionY) && vCount<=(62+positionY)) //4
				||(hCount>=(positionX+55) && hCount<=(positionX+59) && vCount>=(10+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+96) && hCount<=(positionX+100) && vCount>=(10+positionY) && vCount<=(104+positionY)));
			
				128: num_fill=((hCount>=(positionX+10)&& hCount<=(positionX+15)&& vCount>=(10+positionY) && vCount<=(100+positionY))//1
				||(hCount>=(positionX+33) && hCount<=(positionX+70) && vCount>=(10+positionY) && vCount<=(14+positionY)) //2
				||(hCount>=(positionX+33) && hCount<=(positionX+70) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+33) && hCount<=(positionX+70) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+33) && hCount<=(positionX+37) && vCount>=(62+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+66) && hCount<=(positionX+70) && vCount>=(10+positionY) && vCount<=(59+positionY))
				||(hCount>=(positionX+80) && hCount<=(positionX+115) && vCount>=(10+positionY) && vCount<=(14+positionY)) //8
				||(hCount>=(positionX+80) && hCount<=(positionX+115) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+80) && hCount<=(positionX+115) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+80) && hCount<=(positionX+84) && vCount>=(10+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+111) && hCount<=(positionX+115) && vCount>=(10+positionY) && vCount<=(104+positionY))
				);
				256: num_fill=((hCount>=(positionX+10) && hCount<=(positionX+35) && vCount>=(10+positionY) && vCount<=(14+positionY)) //2
				||(hCount>=(positionX+10) && hCount<=(positionX+35) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+10) && hCount<=(positionX+35) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+10) && hCount<=(positionX+14) && vCount>=(62+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+31) && hCount<=(positionX+35) && vCount>=(10+positionY) && vCount<=(59+positionY))
				||(hCount>=(positionX+45) && hCount<=(positionX+70) && vCount>=(10+positionY) && vCount<=(14+positionY)) //5
				||(hCount>=(positionX+45) && hCount<=(positionX+70) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+45) && hCount<=(positionX+70) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+66) && hCount<=(positionX+70) && vCount>=(62+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+45) && hCount<=(positionX+49) && vCount>=(10+positionY) && vCount<=(59+positionY))
				||(hCount>=(positionX+80) && hCount<=(positionX+105) && vCount>=(10+positionY) && vCount<=(14+positionY)) //6
				||(hCount>=(positionX+80) && hCount<=(positionX+105) && vCount>=(58+positionY) && vCount<=(62+positionY))
				||(hCount>=(positionX+80) && hCount<=(positionX+105) && vCount>=(100+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+80) && hCount<=(positionX+84) && vCount>=(10+positionY) && vCount<=(104+positionY))
				||(hCount>=(positionX+101) && hCount<=(positionX+105) && vCount>=(58+positionY) && vCount<=(104+positionY))
				);	
				default:
					begin
						num_fill = 0;
					end
			endcase
		end
	
	
endmodule
