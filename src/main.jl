using DataStructures, Flux
include("board.jl")
include("agent.jl")
include("environment.jl")
include("config.jl")
include("neuralnet.jl")

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
model = Chain(Dense(16,10,sigmoid), Dense(10,5,sigmoid), Dense(5,1))
critic = Critic(
    DefaultDict(0),
    neuralNet ? DefaultDict(DefaultDict((0,0))) : DefaultDict(0),
    model
)
actor =  Actor(DefaultDict(DefaultDict(0)), DefaultDict(0))

function runEpisode(ε)
    resetEligibilities!(actor, false)
    resetEligibilities!(critic, neuralNet)
    env = Environment(generateBoard(shape, boardSize, startPositions))
    s = getState(env)
    currentEpisode = []
    states = []
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
    push!(currentEpisode, (s,a))
    while length(getLegalMoves(env)) != 0
        new_s, r = move!(env, a)
        push!(executedMoves, a)
        possibleMoves = getLegalMoves(env)
        new_a = getMove(actor, new_s, possibleMoves, ε)
        actor.e[s,a] = 1
        δ = neuralNet ? ((r+γ*critic.model(new_s)[1]) - critic.model(s)[1]) : ((r+γ*critic.V[new_s]) - critic.V[s])
        push!(states, (s, δ))
        #println("TD ERROR: ", δ)
        if !neuralNet 
            critic.e[s] = 1
        else 
            critic.e[s] = DefaultDict(0)
        end
        for (s,a) in currentEpisode
            if neuralNet
                train!(critic, s, δ, α_c)
            else
                critic.V[s] = critic.V[s] + α_c*δ*critic.e[s]
                critic.e[s] = γ*λ*critic.e[s]
            end
            actor.Π[s][a] = actor.Π[s][a] + α_a*δ*actor.e[s,a]
            #println("Elgibility actor: ", actor.e[s,a])
            actor.e[s,a] = γ*λ*actor.e[s,a]
        end
        s = new_s
        a = new_a
        push!(currentEpisode, (new_s,new_a))
    end
    return executedMoves, getRemainingPegs(env), states
end

function main(episodes::Int, ε)
    prog = Progress(episodes,1)
    remainingPegs = []
    states = []
    for i in (1:episodes)
        ε *= 0.99
        e,r,s = runEpisode(ε)
        push!(states, s)
        push!(remainingPegs, r)
        next!(prog)
    end
    executedMoves, r = runEpisode(ε)
    println("ε: ", ε)
    board = generateBoard(shape,boardSize, startPositions)
    visualize(board,executedMoves, startPositions, fps)
    Plots.plot([i for i in (1:episodes)], remainingPegs, seriestype= :scatter, title= "Remaining Pegs")
    Plots.savefig("C:\\Users\\sebas\\dev\\AIprog\\src\\animations\\remainingPegsDiamond.png")
end

main(episodes, ε)

