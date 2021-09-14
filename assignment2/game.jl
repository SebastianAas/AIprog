
abstract type Game end

abstract type Move end

function getResult(game::Game)::Int
	winner = getPreviousPlayer(game)
	if isFinished(game)
		if game.startingPlayer == winner
			return 1
		else
			return -1
		end
	end
	println("The game is not finished")
end

oppositePlayer(player::Int)::Int = player == 1 ? 2 : 1
getCurrentPlayer(game::Game)::Int = (length(game.executedMoves) % 2) == 0 ? game.startingPlayer : oppositePlayer(game.startingPlayer)
getPreviousPlayer(game::Game)::Int = length(game.executedMoves) % 2 == 0 ? oppositePlayer(game.startingPlayer) : game.startingPlayer





