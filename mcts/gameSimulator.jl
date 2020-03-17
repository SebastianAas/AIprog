using ProgressMeter
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



function createGame(game::String, startingPlayerOption::Int)::Game
	startingPlayer = startingPlayerOption === 3 ? rand(1:2) : startingPlayerOption
	if game == "NIM"
		return NIM(startPieces, piecesToTake, startingPlayer)
	else
		return Ledge(deepcopy(startPosition), startingPlayer)
	end
end

function initTree(gameType::String, startingPlayerOption::Int)::Tuple{Tree,Game}
	game = createGame(gameType, startingPlayerOption)
	tree = newTree(game)
	return tree, game
end

function main(gameSim::GameSimulator)
	if !verbose ; prog = Progress(gameSim.G,1) end
	tree, game = initTree(gameSim.gameType, gameSim.P)
	for i = (1:gameSim.G)
		node = tree.root
		if verbose ; show(game) end
		while !isFinished(game)
			node = uctSearch(tree,node)
			executeMove!(game, node.move)
			if verbose ; show(game) end
		end
		winner = getPreviousPlayer(game)
		tree, game = initTree(gameSim.gameType, gameSim.P)
		updateStatistics!(gameSim.statistics, winner)
		if !verbose ; next!(prog) end
	end
	printStatistics!(gameSim.statistics)
end

function updateStatistics!(stats::Dict, winner)
	if haskey(stats, winner) 
		stats[winner] += 1
	else 
		stats[winner] = 1
	end
end

function printStatistics!(stats::Dict)
	mostWins = argmax(stats)
	playedGames = sum([stats[key] for key in keys(stats)])
	winPercentage = round((stats[mostWins]/playedGames * 100),digits=2)
	println("Player $(mostWins) wins $(stats[mostWins]) of $playedGames games ($winPercentage %) ")
end


gameSimulator = GameSimulator(
    numberOfGamesInBatch, 
    numberOfRollouts, 
    startingPlayerOption,
    gameType,
	true,
	Dict()
)


main(gameSimulator)
    






