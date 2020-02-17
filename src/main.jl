using DataStructures
include("board.jl")
include("agent.jl")
include("environment.jl")
include("config.jl")
include("neuralnetwork.jl")

@info("Loading config variables...")
shape = Config.shape
boardSize = Config.boardSize
startPositions = Config.startPositions
neuralNet = Config.neuralNet
layers = Config.layers
α_c = Config.learningRateCritic
α_a = Config.learningRateActor
γ = Config.discountRate
λ = Config.traceDecay
episodes = Config.episodes
ε = Config.greedyValueActor
fps = Config.fps
critic = Critic(
    DefaultDict(0),
    neuralNet ? DefaultDict(DefaultDict((0,0))) : DefaultDict(0),
    Chain(initLayers(layers))
)
actor =  Actor(DefaultDict(DefaultDict(0)), DefaultDict(0))

function runEpisode(ε)
    resetEligibilities!(actor, false)
    resetEligibilities!(critic, neuralNet)
    env = Environment(generateBoard(shape, boardSize, startPositions))
    s = getState(env)
    currentEpisode = []
    executedMoves = Move[]
    possibleMoves = getLegalMoves(env)
    if length(possibleMoves) == 0
        println("No possible moves from the start")
        printBoard(env.board)
        Plots.savefig("C:\\Users\\sebas\\dev\\AIprog\\src\\animations\\NoPossibleMoves.png")
        return executedMoves
    else
        a = getMove(actor, s, possibleMoves, ε)
    end
    δ = 0
    push!(currentEpisode, (s,a))
    while length(getLegalMoves(env)) != 0
        new_s, r = move!(env, a)
        push!(executedMoves, a)
        possibleMoves = getLegalMoves(env)
        new_a = getMove(actor, new_s, possibleMoves, ε)
        actor.e[new_s, new_a] = 1
        δ = r + γ*(neuralNet ? (critic.model(vec(new_s)) - critic.model(vec(s)))[1] : critic.V[new_s] - critic.V[s])
        if !neuralNet 
            critic.e[s] = 1
        end
        for (s,a) in currentEpisode
            if neuralNet
                updateWeights!(critic, vec(s), α_c, δ)
            else
                critic.V[s] = critic.V[s] + α_c*δ*critic.e[s]
                critic.e[s] = γ*λ*actor.e[s]
            end
            actor.Π[s][a] = actor.Π[s][a] + α_a*δ*actor.e[s,a]
            actor.e[s,a] = γ*λ*actor.e[s,a]
        end
        s = new_s
        a = new_a
        push!(currentEpisode, (new_s,new_a))
    end
    return executedMoves, getRemainingPegs(env), mse(critic.model(vec(s)), δ)
end

function main(episodes::Int, ε)
    prog = Progress(episodes,1)
    remainingPegs = []
    loss = []
    for i in (1:episodes)
        ε *= 0.99
        e,r, l= runEpisode(ε)
        push!(remainingPegs, r)
        push!(loss,l)
        next!(prog)
    end
    executedMoves, r = runEpisode(ε)
    println("ε: ", ε)
    board = generateBoard(shape,boardSize, startPositions)
    visualize(board,executedMoves, startPositions, fps)
    Plots.plot([i for i in (1:episodes)], remainingPegs, seriestype= :scatter, title= "Remaining Pegs")
    Plots.savefig("C:\\Users\\sebas\\dev\\AIprog\\src\\animations\\remainingPegsDiamond.png")
    Plots.plot([i for i in (1:episodes)], loss, title= "Loss")
    Plots.savefig("C:\\Users\\sebas\\dev\\AIprog\\src\\animations\\loss.png")
end

main(episodes, ε)

