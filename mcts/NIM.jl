include("game.jl")

mutable struct NIM <: Game
    "Pieces on the board"
    N::Int

    "Maximum number of pieces a player can take on their turn"
	K::Int
	NIM(N::Int,K::Int) = (N>K) ? new(N,K) : error("N needs to be larger than K")
end

struct NimMove <: Move
	totalPieces
	removedPieces
end

function getMoves(game::NIM)::Array{NimMove}
	moves = []
	for i = (1:game.K)
        if game.N - i > 0
			push!(moves, NimMove(game.N,i))
		end
	end
	return moves
end

function executeMove!(game::NIM, move::Move)
	game.N = game.N - move.removedPieces
end

isFinished(game::NIM) = game.N == 1
