include("MCTS.jl")
include("config.jl")
include("ledge.jl")
include("NIM.jl")

if gamePlayed == "NIM"
    game = NIM(startPieces, piecesToTake, startingPlayer)
else
    game = Ledge(startPosition, startingPlayer)
end

struct GameSimulator
    "Number of games in a batch"
    G::Int

    "Number of simulations (and hence rollouts) per actual game move"
    M::Int

    "Starting-player option"
	P::Int

    "The game played; either NIM or Ledge"
    game::Game

    "To print the game or not"
    verbose::Bool

    "Win statistics"
    statistics::Dict
end

gameSimulator = GameSimulator(
    numberOfGamesInBatch, 
    numberOfRollouts, 
    startingPlayer,
    game,
    true
)

function main()
    while !isFinished(game)
        show(game)
        moves = getMoves(game)
        executeMove!(game,moves[1])
    end
    show(game)
end

main()
    






