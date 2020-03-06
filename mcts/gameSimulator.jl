include("MCTS.jl")
include("config.jl")
include("ledge.jl")
include("NIM.jl")

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
    #statistics::Dict
end



function createGame(game::String, startingPlayerOption::Int)
	startingPlayer = if startingPlayerOption === 3 ? rand(2) : startingPlayerOption
	if gamePlayed == "NIM"
		game = NIM(startPieces, piecesToTake, startingPlayer)
	else
		game = Ledge(startPosition, startingPlayer)
	end
end

gameSimulator = GameSimulator(
    numberOfGamesInBatch, 
    numberOfRollouts, 
    startingPlayer,
    game,
    true
)

solver = MCTSSolver(game, numberOfIterations, numberOfRollouts, exploration)

function main()
	tree = initializeMCTSTree()
	for i = (1:numberOfGamesInBatch)
		game = createGame(gamePlayed, startingPlayerOption)
		node = search(tree, solver)
		if verbose ; show(game) end
		executeMove!(node.move)
    end
    show(game)
end

main()
    






