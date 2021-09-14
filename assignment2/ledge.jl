import Base.show
include("game.jl")

mutable struct Ledge <: Game
	"Initial board configuration"
    board::Array{Int}

    "Array of executedMoves"
    executedMoves::Array{Move}

    "Starting player"
    startingPlayer::Int

    function Ledge(board::Array{Int}, player)
        if 2 in board
            new(board, [], player)
        else
            error("Board doesn't contain a gold coin")
        end
    end
end

struct LedgeMove <: Move
    type::Int
	from::Int
	to::Int
end

function getMoves(game::Ledge)::Array{LedgeMove}
    moves = []
    board = game.board

    "Checks if can be removed a coin from the ledge"
    if board[1] != 0
        push!(moves, LedgeMove(board[1], 1,-1))
    end
    "Checks if there can be moved coins"
    for i = (length(board):-1:2)
        if board[i] != 0
            j = i-1
            while(j >= 1 && board[j] == 0)
                push!(moves, LedgeMove(board[i], i, j))
                j -= 1
            end
        end
    end
    return moves
end

function executeMove!(game::Ledge, move::LedgeMove)
    game.board[move.from] = 0
    if !(move.to == -1)
        game.board[move.to] = move.type
    end
    push!(game.executedMoves, move)
end

"Checks if the gold coin is one the ledge"
isFinished(game::Ledge) = !(2 in game.board)
getState(game::Ledge) = game.board

function Base.show(game::Ledge)
    player = oppositePlayer(getCurrentPlayer(game))
    coins = ["Copper", "Gold"]
    try 
        move = game.executedMoves[end]            
        if move.to == -1 
                println("P$(player) picks up $(coins[move.type])")
            else
                println("P$(player) moves $(coins[move.type]) from $(move.from) to $(move.to): $(game.board)") 
            end
        if isFinished(game)
            println("Player P$(player) wins")
        end
    catch Exception
        println("Start board: $(game.board)")
    end
end


        