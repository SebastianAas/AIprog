include("uctSearch.jl")
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
    gameType::String

    "To print the game or not"
    verbose::Bool

    "Win statistics"
    statistics::Dict{Int,Int}
end



function createGame(game::String, startingPlayerOption::Int)
	startingPlayer = startingPlayerOption === 3 ? rand(2) : startingPlayerOption
	if game == "NIM"
		return NIM(startPieces, piecesToTake, startingPlayer)
	else
		return Ledge(startPosition, startingPlayer)
	end
end

gameSimulator = GameSimulator(
    numberOfGamesInBatch, 
    numberOfRollouts, 
    startingPlayerOption,
    gameType,
	true,
	Dict()
)


function main()
	game = createGame(gameType, startingPlayerOption)
	root = createNewNode(nothing, nothing, game)
	tree = Tree(root, [])
	node = root
	for i = (1:numberOfGamesInBatch)
		while !isFinished(game)
			node = uctSearch(tree,node)
			if verbose ; show(game) end
			executeMove!(game, node.move)
		end
		if verbose; show(game) end
		player = getCurrentPlayer(game)
		if haskey(gameSimulator.statistics, player) 
			gameSimulator.statistics[player] += 1
		else 
			gameSimulator.statistics[player] = 1
		end
		game = createGame(gameType, startingPlayerOption)
		node = tree.root
	end
	println(gameSimulator.statistics)
end

main()
    






