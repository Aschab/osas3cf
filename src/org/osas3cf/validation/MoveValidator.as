package org.osas3cf.validation
{
	import flash.geom.Point;
	
	import org.osas3cf.board.ChessPieces;
	import org.osas3cf.core.Client;
	import org.osas3cf.core.data.ClientVO;
	import org.osas3cf.core.data.MetaData;
	import org.osas3cf.core.data.StateVO;
	import org.osas3cf.data.BitBoard;
	import org.osas3cf.data.BitBoardMetaData;
	import org.osas3cf.data.BitBoardTypes;
	import org.osas3cf.data.BoardState;
	import org.osas3cf.data.MoveMetaData;
	import org.osas3cf.data.MoveVO;
	import org.osas3cf.utility.BitOper;
	import org.osas3cf.utility.BoardUtil;
	import org.osas3cf.utility.Debug;
	
	public class MoveValidator extends Client
	{
		public static const NAME:String = "MoveValidator";
		
		private var currentBoard:BitBoard;
		private var currentColor:String;
		private var bitBoards:Array;
		private var move:MoveVO;
		
		public function MoveValidator(){}
		
		override public function onMetaData(metaData:MetaData):void
		{
			switch(metaData.type)
			{
				case MetaData.CLIENT_ADDED:
					var clientVO:ClientVO = metaData.data as ClientVO;
					if(clientVO.client is MoveValidator)
						sendMetaData(new MetaData(MetaData.ADD_CLIENT, new ClientVO(new ChessBitBoardManger())));
					break;				
				case MetaData.STATE_CHANGE:
					var state:StateVO = metaData.data as StateVO
					if(state.type == BoardState.PIECES)
					{
						currentBoard = state.newState as BitBoard;
						move = null;
						currentColor = null;
					}
					break;
				case MoveMetaData.SUBMIT_MOVE:
					move = metaData.data as MoveVO;
					currentColor = move.piece.indexOf(ChessPieces.WHITE) != -1 ? ChessPieces.WHITE : ChessPieces.BLACK;
					//Invalid if new square is not in move bitboard
					if(!BoardUtil.isTrue(move.newSquare, bitBoards[move.currentSquare + BitBoardTypes.MOVE]))
					{
						sendMetaData(new MoveMetaData(MoveMetaData.INVALID_MOVE, move));
						return;
					}
					//Need to evaluate if the move puts king in check
					var newBoard:BitBoard = new BitBoard(currentBoard);
					var oldPoint:Point = BoardUtil.squareToArrayNote(move.currentSquare);
					var newPoint:Point = BoardUtil.squareToArrayNote(move.newSquare);
					
					newBoard[oldPoint.x][oldPoint.y] = 0;
					newBoard[newPoint.x][newPoint.y] = move.piece;
					
					sendMetaData(new BitBoardMetaData(BitBoardMetaData.EVALUATE, newBoard));
					break;
				case BitBoardMetaData.EVALUATED:
					bitBoards = metaData.data as Array;
					//Invalid if move puts own king in check
					var oppositeColor:String = (currentColor == ChessPieces.WHITE) ? ChessPieces.BLACK : ChessPieces.WHITE;
					var kingSquare:String = BoardUtil.getTrueSquares(BitOper.and(bitBoards[currentColor + BitBoardTypes.S], bitBoards[ChessPieces.KING + BitBoardTypes.S]))[0];
					if(BoardUtil.isTrue(kingSquare, bitBoards[oppositeColor + BitBoardTypes.ATTACK]))
					{
						sendMetaData(new MoveMetaData(MoveMetaData.INVALID_MOVE, move));
						return;
					}
					//Valid move
					sendMetaData(new MoveMetaData(MoveMetaData.MOVE_PIECE, move));					
					break;
				case BitBoardMetaData.UPDATED:
					bitBoards = metaData.data as Array;				
					break;				
			}
		}
		
		override public function get name():String{return NAME;}
	}
}