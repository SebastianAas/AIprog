using DataStructures
include("board.jl")
include("config.jl")
include("neuralnetwork.jl")

abstract type Agent end

mutable struct Critic <: Agent
    V::DefaultDict
    e::DefaultDict
    model::Chain
end

mutable struct Actor <: Agent
    Π::DefaultDict
    e::DefaultDict
end

function resetEligibilities!(agent::Agent, neuralNet)
    neuralNet ? agent.e = DefaultDict(DefaultDict((0,0))) : agent.e = DefaultDict(0)
end

pickRandomMove(possibleMoves::Array{Move}) = possibleMoves[rand(1:length(possibleMoves))]

function getMove(actor::Actor, state, possibleMoves::Array{Move}, ε)::Move
    if length(possibleMoves) == 0
        return Move((0,0),(0,0))
    end
    if (ε > rand())
        move = pickRandomMove(possibleMoves)
    else 
        move = getBestMove(actor, state, possibleMoves)
    end
    return move
end

function getBestMove(actor::Actor, state, possibleMoves::Array{Move})::Move
    maxValue = -Inf
    bestMove = NaN
    for move in possibleMoves
        if actor.Π[state][move] >= maxValue
            bestMove = move
            maxValue = actor.Π[state][move]
        end
    end
    return bestMove
end

function initLayers(layers)
    l = []
    for i in (1:length(layers)-1)
        push!(l, Dense(layers[i], layers[i+1]))
    end
    return l
end

"""
l = Config.layers
critic = Critic(DefaultDict(0), DefaultDict(DefaultDict((0,0))), Chain(initLayers(l)))

updateWeights!(critic, rand(16), 0.5, 0.5)

"""





