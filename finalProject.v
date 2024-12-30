module finalProject(clock, reset, keypadCol, keypadRow, dotRow, dotCol, sevenDisplayOne, sevenDisplayTwo, H_SYNC, V_SYNC, Red, Green, Blue);
input clock, reset;
input [3:0] keypadCol;
output [3:0] keypadRow;
output [7:0] dotRow; output [7:0] dotCol;
output [6:0] sevenDisplayOne; output [6:0] sevenDisplayTwo;
output H_SYNC, V_SYNC;
output [3:0] Red; output [3:0] Green; output [3:0] Blue;

wire [2:0] gamePeriod;
wire dotClock, keypadClock, vgaClock;
wire [17:0] state_flat;
wire hasPush;

divFreq dFImp(.clock(clock), .reset(reset), .dotClock(dotClock), .keypadClock(keypadClock), .vgaClock(vgaClock));

keypadCheck kCImp(.keypadClock(keypadClock), .reset(reset), .keypadCol(keypadCol), .keypadRow(keypadRow), .state_flat(state_flat), .hasPush(hasPush));

connectLineCheck cLImp(.state_flat(state_flat), .sDoneOut(sevenDisplayOne), .sDtwoOut(sevenDisplayTwo));

vga vgaImp(.vgaClock(vgaClock), .reset(reset), .state_flat(state_flat), ,gamePeriod(gamePeriod), .H_SYNC(H_SYNC), .V_SYNC(V_SYNC), .Red(Red), .Green(Green), .Blue(Blue));


endmodule


`define DotTimeExpire 2500
`define KeypadTimeExpire 250000
`define VgaTimeExpire 1

module divFreq(clock, reset, dotClock, keypadClock, vgaClock);
input clock, reset;
output reg dotClock, keypadClock, vgaClock;
reg [11:0] dotCounter;
reg [19:0] keypadCounter;

always@(posedge clock) begin
	if (!reset) begin
		dotCounter <= 12'd0;
		keypadCounter <= 20'd0;
		vgaClock <= 1'b0;
	end
	else begin
		if (dotCounter == `DotTimeExpire) begin
			dotCounter <= 12'd0;
			dotClock <= ~dotClock;
		end
		else 
			dotCounter <= dotCounter + 12'd1;
		
		if (keypadCounter == `KeypadTimeExpire) begin
			keypadCounter <= 20'd0;
			keypadClock <= ~keypadClock;
		end
		else
			keypadCounter <= keypadCounter + 20'd1;
			
		if (vgaClock == `VgaTimeExpire)
			vgaClock <= 1'b0;
		else
			vgaClock <= 1'b1;
	end
end
endmodule
 


module keypadCheck(keypadClock, reset, keypadCol, keypadRow, state_flat, hasPush);
input keypadClock, reset;
input [3:0] keypadCol;
output reg [3:0] keypadRow;
output [17:0] state_flat;
reg [1:0] state [0:8]; 			/** state has nine 2 bit reg. */
reg [3:0] queue [0:99]; 			/** queue has a lot of 3 bit reg. Use to record the sequence of queue.*/
reg [7:0] front;
reg [7:0] rear;
initial begin
	state[0] = 2'b0;
	state[1] = 2'b0;
	state[2] = 2'b0;
	state[3] = 2'b0;
	state[4] = 2'b0;
	state[5] = 2'b0;
	state[6] = 2'b0;
	state[7] = 2'b0;
	state[8] = 2'b0;
	
	/*for (int i = 0; i < 100; i++)
		queue[i] <= 2'd0;*/
	
	rear = 3'b0;
end


output reg hasPush; 				/** Record if someone push any button. */

reg target;							/** Record this is a circle or cross. */
initial target = 1'b1;			/** In the beginning, the target is cross.*/

integer i;
always@(posedge keypadClock, negedge reset) begin
	if (!reset) begin
		target = 1'b1;
		keypadRow <= 2'b0;
		state[0] <= 2'b00;
		state[1] <= 2'b00;
		state[2] <= 2'b00;
		state[3] <= 2'b00;
		state[4] <= 2'b00;
		state[5] <= 2'b00;
		state[6] <= 2'b00;
		state[7] <= 2'b00;
		state[8] <= 2'b00;
		
		/*for (int i = 0; i < 100; i++)
			queue[i] <= 2'd0;*/
		
		rear <= 3'b0;
		front <= 3'b0;
		hasPush <= 1'b0;
	
	end
	else begin
		
		/** Detect which button be pushed. And record it is O or X in state.
		/** If someone push the button, set variable "hasPush" to 1, otherwise, 0.
		/** If state[j] == 0, it means nothing, so this state can be set to O or X.
		/** Target is either 0 or 1. Target plus one set to state[j].
		/** Queue is a big matrix recording which states been pushed.
		/** If rear >= 6, set queue[front] to zero. Front point to the state need to be disappeared,
		/** rear point to the space need to be write state.
		*/
		case(keypadRow)
			4'b0111: begin
				case(keypadCol)
					4'b0111: begin
						hasPush <= 1'b1;
						if (state[0] == 2'd0) begin
							state[0] <= target + 2'd1;
							target <= ~target;
							queue[rear] <= 4'd0;
							if (rear >= 3'd6) begin
								state[queue[front]] <= 2'd0;
								front <= front + 8'd1;
							end else
								front <= front;
							rear <= rear + 8'd1;
						end
						else
							state[0] <= state[0];
					end
					4'b1011: begin
						hasPush <= 1'b1;
						if (state[1] == 2'd0) begin
							state[1] <= target + 2'd1;
							target <= ~target;
							queue[rear] <= 4'd1;
							if (rear >= 3'd6) begin
								state[queue[front]] <= 2'd0;
								front <= front + 8'd1;
							end else
								front <= front;
							rear <= rear + 8'd1;
						end
						else
							state[1] <= state[1];
					end
					4'b1101: begin
						hasPush <= 1'b1;
						if (state[2] == 2'd0) begin
							state[2] <= target + 2'd1;
							target <= ~target;
							queue[rear] <= 4'd2;
							if (rear >= 3'd6) begin
								state[queue[front]] <= 2'd0;
								front <= front + 8'd1;
							end else
								front <= front;
							rear <= rear + 8'd1;
						end
						else
							state[2] <= state[2];
					end
					default: begin
						hasPush <= 1'b0;
					end
				endcase
				keypadRow <= 4'b1011;
			end
			4'b1011: begin
				case(keypadCol)
					4'b0111: begin
						hasPush <= 1'b1;
						if (state[3] == 2'd0) begin
							state[3] <= target + 2'd1;
							target <= ~target;
							queue[rear] <= 4'd3;
							if (rear >= 3'd6) begin
								state[queue[front]] <= 2'd0;
								front <= front + 8'd1;
							end else
								front <= front;
							rear <= rear + 8'd1;
						end else
							state[3] <= state[3];
					end
					4'b1011: begin
						hasPush <= 1'b1;
						if (state[4] == 2'd0) begin
							state[4] <= target + 2'd1;
							target <= ~target;
							queue[rear] <= 4'd4;
							if (rear >= 3'd6) begin
								state[queue[front]] <= 2'd0;
								front <= front + 8'd1;
							end else
								front <= front;
							rear <= rear + 8'd1;
						end else
							state[4] <= state[4];
					end
					4'b1101: begin
						hasPush <= 1'b1;
						if (state[5] == 2'd0) begin
							state[5] <= target + 2'd1;
							target <= ~target;
							queue[rear] <= 4'd5;
							if (rear >= 3'd6) begin
								state[queue[front]] <= 2'd0;
								front <= front + 8'd1;
							end else
								front <= front;
							rear <= rear + 8'd1;
						end else
							state[5] <= state[5];
					end
					default: begin
						hasPush <= 1'b0;
					end
				endcase
				keypadRow <= 4'b1101;
			end
			4'b1101: begin
				case(keypadCol)
					4'b0111: begin
						hasPush <= 1'b1;
						if (state[6] == 2'd0) begin
							state[6] <= target + 2'd1;
							target <= ~target;
							queue[rear] <= 4'd6;
							if (rear >= 3'd6) begin
								state[queue[front]] <= 2'd0;
								front <= front + 8'd1;
							end else
								front <= front;
							rear <= rear + 8'd1;
						end else
							state[6] <= state[6];
					end
					4'b1011: begin
						hasPush <= 1'b1;
						if (state[7] == 2'd0) begin
							state[7] <= target + 2'd1;
							target <= ~target;
							queue[rear] <= 4'd7;
							if (rear >= 3'd6) begin
								state[queue[front]] <= 2'd0;
								front <= front + 8'd1;
							end else
								front <= front;
							rear <= rear + 8'd1;
						end else
							state[7] <= state[7];
					end
					4'b1101: begin
						hasPush <= 1'b1;
						if (state[8] == 2'd0) begin
							state[8] <= target + 2'd1;
							target <= ~target;
							queue[rear] <= 4'd8;
							if (rear >= 3'd6) begin
								state[queue[front]] <= 2'd0;
								front <= front + 8'd1;
							end else
								front <= front;
							rear <= rear + 8'd1;
						end else
							state[8] <= state[8];
					end
					default: begin
						hasPush <= 1'b0;
					end
				endcase
				keypadRow <= 4'b0111;
			end
			default: begin
				keypadRow <= 4'b0111;
			end
		endcase
		
	end
end

assign state_flat = {state[8], state[7], state[6], state[5], state[4], state[3], state[2], state[1], state[0]};

endmodule 
 

 
 
 


module vga(vgaClock, reset, state_flat, gamePeriod, H_SYNC, V_SYNC, Red, Green, Blue);
input vgaClock, reset;
input [17:0] state_flat;
input [2:0] gamePeriod;
output reg H_SYNC;
output reg V_SYNC;
output reg [3:0] Red;
output reg [3:0] Green;
output reg [3:0] Blue;
reg [9:0] HCounter;
reg [9:0] VCounter;
reg displayState;


parameter HSyncPulse = 96, HBackPorch = 48, HActive = 640, HFrontPorch = 16, HStartDisplay = 144, HEndDisplay = 784, HAllPeriod = 800;
 
parameter VSyncPulse = 2, VBackPorch = 33, VActive = 480, VFrontPorch = 10, VStartDisplay = 35, VEndDisplay = 515, VAllPeriod = 525;


reg [1:0] state [0:8];
integer i;


always@(posedge vgaClock, negedge reset) begin
	if (!reset) begin
		HCounter <= 10'd0;
		VCounter <= 10'd0;
		displayState <= 1'b0;
	end
	else begin
		/** Unzip the state_flat to state. Since can't pass state between module without systemverilog? */
		state[0] = state_flat[1:0];
		state[1] = state_flat[3:2];
		state[2] = state_flat[5:4];
		state[3] = state_flat[7:6];
		state[4] = state_flat[9:8];
		state[5] = state_flat[11:10];
		state[6] = state_flat[13:12];
		state[7] = state_flat[15:14];
		state[8] = state_flat[17:16];
	
		/** HCounter and VCounter count and recount. */
		if (HCounter == HAllPeriod - 10'd1) begin
			HCounter <= 10'd0;
			
			if (VCounter == VAllPeriod - 10'd1) begin
				VCounter <= 10'd0;
			end
			else begin
				VCounter <= VCounter + 10'd1;
			end
		end
		else
			HCounter <= HCounter + 10'd1;
	
		/** Set H_SYNC and V_SYNC value. */
		if (HCounter < HSyncPulse)
			H_SYNC <= 1'd0;
		else
			H_SYNC <= 1'd1;

		if (VCounter < VSyncPulse)
			V_SYNC <= 1'd0;
		else
			V_SYNC <= 1'd1;
			
			
		/** Determine if this period can display. */
		/** A 480*480 pixel square. */
		if (HCounter >= HStartDisplay +80 && HCounter < HEndDisplay - 80) begin
			if (VCounter >= VStartDisplay && VCounter < VEndDisplay)
				displayState <= 1'd1;
			else 
				displayState <= 1'd0;
		end
		else
			displayState <= 1'd0;
	end
end
		
	
/** Display O or X !!!!!!!*/
/** There are 3 columns and also 3 rows.
/** Each are 160 * 160 pixel square.*/
parameter CELL_SIZE = 160;  
parameter GRID_COLS = 3;		
parameter GRID_ROWS = 3;   	

localparam OFFSET_X = 80;								
localparam GRID_WIDTH = GRID_COLS * CELL_SIZE;	

wire [9:0] h_mod;
assign h_mod = (displayState) ? (HCounter - OFFSET_X - HStartDisplay): 10'd1023;

wire [9:0] v_mod;
assign v_mod = (displayState) ? (VCounter - VStartDisplay) : 10'd1023;

wire [1:0] col = (h_mod < GRID_WIDTH) ? (h_mod / CELL_SIZE) : 2'd3;
wire [1:0] row = (v_mod < GRID_WIDTH) ? (v_mod / CELL_SIZE) : 2'd3;


wire col_valid = (col < GRID_COLS); 
wire row_valid = (row < GRID_ROWS);

/** Count which index is current (x,y) in. */
wire [3:0] index = row * GRID_COLS + col;

wire [9:0] local_x = h_mod - (col * CELL_SIZE); 
wire [9:0] local_y = v_mod - (row * CELL_SIZE);

parameter CELL_THICKNESS = 4;
parameter CELL_OFFSET = 15;


	
always@(posedge vgaClock, negedge reset) begin	
	if (!reset) begin
		Red <= 4'h0;
		Green <= 4'h0;
		Blue <= 4'h0;
		
	end
	else begin
		if (displayState) begin
			if ((HCounter - HStartDisplay >= OFFSET_X + CELL_SIZE - CELL_THICKNESS/2 && HCounter - HStartDisplay <= OFFSET_X + CELL_SIZE + CELL_THICKNESS/2) ||
            (HCounter - HStartDisplay >= OFFSET_X + 2 * CELL_SIZE - CELL_THICKNESS/2 && HCounter - HStartDisplay <= OFFSET_X + 2 * CELL_SIZE + CELL_THICKNESS/2)) begin
				// 加粗垂直線條
            Red <= 4'hF;
            Green <= 4'hF;
            Blue <= 4'hF;
			end 
         else if ((VCounter - VStartDisplay >= CELL_SIZE - CELL_THICKNESS/2 && VCounter - VStartDisplay <= CELL_SIZE + CELL_THICKNESS/2) ||
                 (VCounter - VStartDisplay >= 2 * CELL_SIZE - CELL_THICKNESS/2 && VCounter - VStartDisplay <= 2 * CELL_SIZE + CELL_THICKNESS/2)) begin
            // 加粗水平線條
            Red <= 4'hF;
				Green <= 4'hF;
            Blue <= 4'hF;
         end 
			else if (col_valid && row_valid) begin
				case(state[index])
					2'd1: begin
						if ((((local_x - CELL_SIZE/2)**2 + (local_y - CELL_SIZE/2)**2) >= (CELL_SIZE/3 - 6)**2) &&
                     (((local_x - CELL_SIZE/2)**2 + (local_y - CELL_SIZE/2)**2) <= (CELL_SIZE/3 + 6)**2)) begin    
							Red <= 4'h0; // 綠色
                     Green <= 4'hf;
                     Blue <= 4'h0;
						end else begin
							Red <= 4'h0;
							Green <= 4'h0;
							Blue <= 4'h0;
						end
					end
					2'd2: begin
						if ((local_x >= local_y - CELL_THICKNESS && local_x <= local_y + CELL_THICKNESS && 
                       local_x >= CELL_OFFSET && local_y >= CELL_OFFSET && 
                       local_x < CELL_SIZE - CELL_OFFSET && local_y < CELL_SIZE - CELL_OFFSET) ||
                       (local_x + local_y >= CELL_SIZE - 1 - CELL_THICKNESS && 
                       local_x + local_y <= CELL_SIZE - 1 + CELL_THICKNESS &&
                       local_x >= CELL_OFFSET && local_y >= CELL_OFFSET && 
                       local_x < CELL_SIZE - CELL_OFFSET && local_y < CELL_SIZE - CELL_OFFSET)) begin
							Red <= 4'hff;
                     Green <= 4'hc0;
                     Blue <= 4'hcb;
                  end else begin
							Red <= 4'h0;
							Green <= 4'h0;
							Blue <= 4'h0;
						end
					end
					default: begin
						Red <= 4'h0;
						Green <= 4'h0;
						Blue <= 4'h0;
					end
				endcase
			end else begin
				Red <= 4'h0;
				Green <= 4'h0;
				Blue <= 4'h0;	
			end
		end
		else begin
			Red <= 4'h0;
			Green <= 4'h0;
			Blue <= 4'h0;
		end
	end	
end

endmodule 
 

 
 
connectLineCheck (state_flat, sDoneOut, sDtwoOut, gamePeriod);
input [17:0] state_flat;
output reg [6:0] sDoneOut;
output reg [6:0] sDtwoOut;
output reg [2:0] gamePeriod;

parameter rowNumber = 3;
parameter colNumber = 3;

/** for sevenDisplay. */
reg [3:0] sDoneIn;
reg [3:0] sDtwoIn;
initial sDoneIn = 4'd0;
initial sDtwoIn = 4'd0;

/** Record whether is O or X connect line. */
reg [4:0] someOne;

always@(state_flat)
	state[0] = state_flat[1:0];
	state[1] = state_flat[3:2];
	state[2] = state_flat[5:4];
	state[3] = state_flat[7:6];
	state[4] = state_flat[9:8];
	state[5] = state_flat[11:10];
	state[6] = state_flat[13:12];
	state[7] = state_flat[15:14];
	state[8] = state_flat[17:16];

	/** brute force.*/
	for (int i = 0; i < 3; i++) begin
		if ((state[rowNumber * i] == state[1 + rowNumber * i] && state[1 + rowNumber * i] == state[1 + rowNumber * i)) && state[rowNumber * i] != 2'd0) begin
			someOne <= state[rowNumber * i];
			gamePeriod <= 3'd2;
		
		end else
			gamePeriod <= gamePeriod;
		
		if ((state[i] == state[colNumber * 1 + i] && state[colNumber * 1 + i] == state[colNumber * 2 + 1]) && state[i] != 2'd0) begin
			someOne <= state[i];
			gamePeriod <= 3'd2;
		
		end else
			gamePeriod <= gamePeriod;
			
		if ((state[0] == state[4] && state[4] == state[8]) && state[0] != 2'd0) begin
			someOne <= state[0];
			gamePeriod <= 3'd2;
			
		end else
			gamePeriod <= gamePeriod;
			
		if ((state[2] == state[4] && state[4] == state[6]) && state[2] != 2'd0) begin
			someOne <= state[2];
			gamePeriod <= 3'd2;
			
		end else
			gamePeriod <= gamePeriod;
		
	end

	if (someOne == 2'd1)
		sDoneIn <= sDoneIn + 4'd1;
	else if (someOne == 2'd2)
		sDtwoIn <= sDtwoIn + 4'd1;
	else begin
		sDoneIn <= sDoneIn;
		sDtwoIn <= sDtwoIn;
	end
	
	case(sDoneIn)
		4'd0: sDoneOut <= 7'b1000000;
		4'd1: sDoneOut = 7'b1111001;
		4'd2: sDoneOut = 7'b0100100;
		4'd3: sDoneOut = 7'b0110000;
		default: sDoneOut = 7'b1000000;
	endcase
	
	case(sDtwoIn)
		4'd0: sDtwoOut = 7'b1000000;
		4'd1: sDtwoOut = 7'b1111001;
		4'd2: sDtwoOut = 7'b0100100;
		4'd3: sDtwoOut = 7'b0110000;
		default: sDtwoOut = 7'b1000000;
	endcase
	
end
endmodule
 
 
 
 
 
 
 
 
 
 
 
