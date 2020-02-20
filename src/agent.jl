using DataStructures
using Flux
include("board.jl")
include("config.jl")
include("neuralnet.jl")

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
    neuralNet ? agent.e = DefaultDict(DefaultDict(0)) : agent.e = DefaultDict(0)
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
    for i in (1:length(layers)-2)
        push!(l, Dense(layers[i], layers[i+1], NNlib.relu))
    end
    push!(l,Dense(layers[length(layers)-1], layers[end]))
    return l
end

function train!(agent::Critic, state, δ, α)
    loss(x, y) = Flux.mse(agent.model(x), y)
    ps = params(agent.model)
    opt = Descent(α)
    train!(loss, ps, (state, δ), agent.e[state], δ, opt)
end







