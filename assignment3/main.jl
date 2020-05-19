using Pkg
#Pkg.add("Flux")
#Pkg.add("BSON")
#Pkg.add("DataStructures")
#Pkg.add("ProgressMeter")
#Pkg.add("PyCall")
using CSV
using DataFrames
using BSON: @save, @load
using Flux, ProgressMeter
using Random
include("neuralnet.jl")
include("mcts.jl")
include("config.jl")


struct GameSimulator
    "Episodes"
    G::Int

    "Number of simulations (and hence rollouts) per actual game move"
    M::Int

    "Starting-player option"
	P::Int

    "To print the game or not"
    verbose::Bool

    "Win statistics"
	statistics::Dict{Int,Int}
	
	"How many neural nets to save"
	numberOfNets
end


function initTree(startingPlayerOption::Int, neuralNet::Union{NeuralNet,Chain}, σ::Float64)::Tuple{Tree,Game}
	startingPlayer = startingPlayerOption === 3 ? rand(1:2) : startingPlayerOption
	game = createGame(boardSize, startingPlayer)
	tree = newTree(game, neuralNet, σ)
	return tree, game
end

function next_move(state)
	size = convert(Int64,sqrt(length(state)-1))
	game = createGameBasedOnState(state)
	@load "C:\\Users\\sebas\\dev\\AIprog\\assignment3\\trainedModels6x6\\neuralnet-100.bson" model
	predictions = model(state)
	move = chooseBestPossibleMove(game, predictions)
	bestMove = (move.y - 1, move.x - 1)	
	return bestMove
end

function nextMove(state)
	game = createGameBasedOnState(state)
	node = createNewNode(nothing, nothing, game)
	@load "C:\\Users\\sebas\\dev\\AIprog\\assignment3\\trainedModels6x6\\neuralnet-100.bson" model
	tree = newTree(game, model, 0.0)
	node = search!(tree, node)
	return (node.move.y-1, node.move.x-1)
end

function main(gameSim::GameSimulator)
	if !verbose ; prog = Progress(gameSim.G,1) end
	neuralNet = NeuralNet(boardSize)
	saveInterval = gameSim.G / gameSim.numberOfNets
	replayBuffer = CircularBuffer{Tuple{Array,Array}}(500)
	tree, game = initTree(gameSim.P, neuralNet, 1.0)
	for i = (1:gameSim.G)
		tree, game = initTree(gameSim.P, neuralNet, tree.σ*0.99)
		node = tree.root
		while !isFinished(game)
			currentPlayer = getCurrentPlayer(game)
			node = search!(tree, node)
			D = getDistribution(node.parent)
			println("D: ", D)
			push!(replayBuffer, (vcat(currentPlayer,vec(permutedims(game.board))),D))
			executeMove!(game, node.move)
		end
		winner = getPreviousPlayer(game)
		updateStatistics!(gameSim.statistics, winner)
		println("training...")
		trainingData = rand(replayBuffer, min(length(replayBuffer), 32))
		train!(neuralNet, trainingData)
		println("Done training")
		if i % saveInterval == 0
			model = neuralNet
			@save "./trainedModels6x6/neuralnet-$(i).bson" model
		end
		if !verbose ; next!(prog) end
	end
	df = DataFrame(
		data = map(x -> x[1], replayBuffer), 
		labels = map(x -> x[2], replayBuffer)
	)

	CSV.write("data6x6.csv",df)
	println(game.executedMoves)
	printStatistics!(gameSim.statistics)
	visualize(game)
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

function getDistribution(node::Node)
	D = zeros(node.game.boardSize^2)
	for child in node.children
		moveIndex = coordToPoint(node.game, child.move)
		D[moveIndex] = child.visits
	end
	return D
end


gameSimulator = GameSimulator(
    episodes, 
    searchPerGame, 
    startingPlayerOption,
	true,
	Dict(),
	numberOfNets
)



#main(gameSimulator)