include("main.jl")


function sortName(string)
    array = split(string, "-")
    number = split(array[2],".")[1]
    return parse(Int64, number)
end

function playTournament(modeldir)
    stats = []
    models = readdir(modeldir)
    sortedModels = sort(models, by=sortName)
    println(sortedModels)
    for name in sortedModels
        s = []
        @load "./$modeldir/$name" model
        nn1 = model
        for opponent in sortedModels
             @load "./$modeldir/$opponent" model
             nn2 = model
             results = playGame(nn1, nn2)
             push!(s, results)
        end
        push!(stats, s)
    end
    println(stats)
    plotHeatmap(sortedModels, stats)
end

function plotHeatmap(models, stats)
    stats = hcat(stats...)
    println(stats)
    heatmap(1:size(stats,1),
        1:size(stats,2), stats,
        xlabel= "Models", ylabel="Models",
        title="Topp Tournament")
    savefig("C:\\Users\\sebas\\dev\\AIprog\\assignment3\\animations\\heatmap.png")
end



function playGame(nn1, nn2)
    if !verbose ; prog = Progress(gamesInTournament,1) end
    player1Wins = 0
	game = createGame(boardSize, 1)
    for i = (1:gamesInTournament)
	    game = createGame(boardSize, 1)
		while !isFinished(game)
            currentPlayer = getCurrentPlayer(game)
            if currentPlayer == 1
                predictions = nn1(vcat(currentPlayer,vec(permutedims(game.board))))
                move = chooseBestPossibleMove(game, predictions)
            else
                predictions = nn2(vcat(currentPlayer,vec(permutedims(game.board))))
                move = chooseBestPossibleMove(game, predictions)
            end
            if length(game.executedMoves) <= 0
                move = pickRandomMove(game)
            end
			executeMove!(game, move)
		end
        winner = getPreviousPlayer(game)
        if winner == 1
            player1Wins += 1
        end
		if !verbose ; next!(prog) end
    end
    visualize(game)
    return player1Wins
end


playTournament("trainedModels/")

