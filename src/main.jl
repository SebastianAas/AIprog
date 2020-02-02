using JSON

include("board.jl")
include("agent.jl")

configValues = JSON.parsefile("config.json")

shape = configValues["shape"]
size = configValues["boardSize"]
startPositions = [(2,2), (4,4)]
println(startPositions)
γ = configValues["discountRate"]
α_c = configValues["learningRateCritic"]
α_a = configValues["learningRateActor"]
λ = configValues["traceDecay"]
episodes = configValues["episodes"]
board = generateBoard(shape, size, startPositions)
critic = Critic(rand(length(board.grid)), fill(0, length(board.grid)))
actor = Actor(fill(0,(board.size, board.size)), fill(0, (board.size,board.size)))

function main()
    s = getState(board)
    while notDone(board)
        println("First loop: ")
        display(board.grid)
        possibleMoves = getAvailableMoves(board)
        println("Possible Moves: ", possibleMoves)
        a = possibleMoves[1]
        currentEpisode = [(s,a)]
        while length(possibleMoves) > 0
            print("State : ", s)
            new_s = getState(executeMove!(board, a))
            new_a = argmax(actor.Π[new_s, a])
            r = 1
            actor.e[new_s, new_a] = 1
            δ = r + γV[new_s] - V[s]
            critic.e[s] = 1
            for (s,a) in currentEpisode
                critic.V[s] = critic.V[s] + α_c*δ*critic.e[s]
                critic.e[s] = γ*λ*actor.e[s]
                actor.Π[s,a] = actor.Π[s,a] + α_a*δ*actor.e[s,a]
                actor.e[s,a] = γ*λ*actor.e[s,a]
            end
        s = new_s
        a = new_a
        push!(currentEpisode, (new_s, new_a))
        end
    end
    print("Done")
end

main()

