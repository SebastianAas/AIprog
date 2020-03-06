include("game.jl")

mutable struct NIM <: Game
    "Pieces on the board"
    N::Int

    "Maximum number of pieces a player can take on their turn"
	K::Int

	"Starting player"
	player::Int

	"Executed moves in the game"	
	executedMoves::Array{Move}

	NIM(N::Int,K::Int, player::Int) = (N>K) ? new(N, K, player, []) : error("N needs to be larger than K")
end

struct NimMove <: Move
	totalPieces
	removedPieces
end

function getMoves(game::NIM)::Array{NimMove}
	moves = []
	for i = (1:game.K)
        if game.N - i >= 0
			push!(moves, NimMove(game.N,i))
		end
	end
	return moves
end

function executeMove!(game::NIM, move::Move)
	game.N = game.N - move.removedPieces
	push!(game.executedMoves, move)
end

isFinished(game::NIM) = game.N == 0

function Base.show(game::NIM)
	player = getCurrentPlayer(game)
	try  
		move = game.executedMoves[end]
		println("Player $(player) selects $(move.removedPieces): Remaining stones = $(game.N)")
	catch Exception
		if length(game.executedMoves) == 0
			println("Start pile: $(game.N)")
		end
	end
	if isFinished(game)
		println("Player  $(player) wins")
	end
end