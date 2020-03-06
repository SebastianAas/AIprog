
abstract type Game end

abstract type Move end


function getResult(game::Game, player::Int)::Int
	winner = getCurrentPlayer(game)
	if isFinished(game)
		if player == winner
			return 1
		else
			return -1
		end
	end
	println("The game is not finished")
end

oppositePlayer(player::Int) = player == 1 ? 2 : 1
getCurrentPlayer(game::Game) = (length(game.executedMoves) % 2) == 0 ? oppositePlayer(game.player) : game.player





