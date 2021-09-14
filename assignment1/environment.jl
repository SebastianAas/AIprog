#=
environment:
- Julia version: 
- Author: sebas
- Date: 2020-02-10
=#

include("board.jl")
include("agent.jl")

mutable struct Environment
    board::Board
end

function getState(env::Environment)
    return getState(env.board)
end

function getLegalMoves(env::Environment)
    return getAvailableMoves(env.board)
end

function move!(env::Environment, move::Move)
    a = env.board
    env.board = executeMove!(env.board, move::Move)
    b = env.board
    return getState(env.board), getReward(env)
end

function getReward(env::Environment)
    return getReward(env.board)
end

function notDone(env::Environment)
    return notDone(env.board)
end

function getRemainingPegs(env::Environment)::Int
    return getNumberOfRemainingPegs(env.board)
end

