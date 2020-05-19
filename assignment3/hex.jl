#=
board:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-03-18
=#

using Plots, DataStructures, ProgressMeter
include("game.jl")

mutable struct Hex <: Game
    boardSize::Int
    board::Array{Int,2}
    legalMoves::Array{Move}
    executedMoves::Array{Move}
    disjointSet1::IntDisjointSets
    disjointSet2::IntDisjointSets
    startingPlayer::Int
end

struct HexMove <: Move
    y::Int
    x::Int
end

function createGame(size::Int, startingPlayer::Int)::Hex
    grid = fill(0, (size, size))
    legalMoves = [HexMove(0,1), HexMove(1,0), HexMove(-1,1), HexMove(1,-1), HexMove(0, -1), HexMove(-1,0)]
    return Hex(size, grid, legalMoves ,[], IntDisjointSets(size^2 + 4), IntDisjointSets(size^2 + 4), startingPlayer)
end

function getExecutedMovesFromState(size, state)
    player1 = mapMoves(state, 1)
    player2 = mapMoves(state, 2)
    movesPlayer1 = map(x -> HexMove(x ÷ size + 1, x % size + 1), player1)
    movesPlayer2 = map(x -> HexMove(x ÷ size + 1, x % size + 1), player2)
    if length(movesPlayer1) == length(movesPlayer2)
        return collect(Iterators.flatten(zip(movesPlayer1, movesPlayer2))), true
    else
        longestArray = length(player1) > length(player2) ? movesPlayer1 : movesPlayer2
        shortestArray = length(player1) > length(player2) ? movesPlayer2 : movesPlayer1
        a = collect(Iterators.flatten(zip(longestArray, shortestArray)))
        return vcat(a, longestArray[end]), false
    end
end

function mapMoves(state, player)
    moves = []
    for i=(1:length(state))
        if state[i] == player
            push!(moves, i - 1)
        end
    end
    return moves
end

function createGameBasedOnState(state)::Hex
    size = convert(Int64,sqrt(length(state)-1))
    executedMoves, startPlayer = getExecutedMovesFromState(size, state[2:end])
    startingPlayer = startPlayer ? state[1] : oppositePlayer(state[1])
    game = createGame(size, startingPlayer)
    for move in executedMoves
        executeMove!(game, move)
    end
    return game
end

function getMoves(game::Hex)::Array{Move}
    availableMoves = []
    for i in (1:game.boardSize)
        for j in (1:game.boardSize)
            if game.board[i,j] === 0
                push!(availableMoves, HexMove(i,j))
            end
        end
    end
    return availableMoves
end

function getNeighbors(game::Hex, position::Move, player::Int)::Set{Int}
    neighbors = Set()
    for move in game.legalMoves
        try
            if hasNeighbor(game, position, move, player)
                #Map from coordinate to single value 
                y = position.y + move.y
                x = position.x + move.x
                value = coordToPoint(game, HexMove(y,x))
                union!(neighbors, value)
            end
        catch BoundsError
            value = getEdge(game, position, move, player)
            if value != nothing
                union!(neighbors, value)
            end
            continue
        end
    end
    return neighbors
end


function hasNeighbor(game::Hex, position::Move, move::Move, player::Int)
    return game.board[position.y + move.y, position.x + move.x] === player
end

coordToPoint(game::Game, move::Move) = (move.y-1)*game.boardSize + move.x

function getEdge(game::Hex, position::Move, move::Move, player::Int)::Union{Int, Nothing}
    if player == 1
        if position.y + move.y <= 0
            return game.boardSize^2 + 1
        end
        if position.y + move.y > game.boardSize
            return game.boardSize^2 + 2
        end
    elseif player == 2
        if position.x + move.x <= 0
            return game.boardSize^2 + 3
        end
        if position.x + move.x > game.boardSize
            return game.boardSize^2 + 4
        end
    else
        println("Somethings wrong...")
        return nothing
    end
end

function executeMove!(game::Hex, move::Move)
    player = getCurrentPlayer(game)
    neighbors = getNeighbors(game, move, player)
    disjointSet = player == 1 ? game.disjointSet1 : game.disjointSet2
    for neighbor in neighbors
        value = coordToPoint(game, move)
        union!(disjointSet, value, neighbor) 
    end
    push!(game.executedMoves, move)
    game.board[move.y, move.x] = player
end

function isFinished(game::Hex)
    if in_same_set(game.disjointSet1, game.boardSize^2 + 1, game.boardSize^2 + 2)
        return true
    elseif in_same_set(game.disjointSet2, game.boardSize^2 + 3, game.boardSize^2 + 4)
        return true
    else
        return false
    end
end

function printBoardTerminal(game::Hex)
    for row in game.board
        for j in row
            if(j == 1)
                print("🔵")
            elseif (j == 2)
                print("🟠")
            else 
                print("⚪")
            end
            print("  ")
        end
        println("")
    end
end


function printBoard(game::Hex)
    redMoves = Tuple{Int,Int}[]
    blueMoves = Tuple{Int,Int}[]
    emptySpaces = Tuple{Int,Int}[]
    gw = 2*game.boardSize
    for i in (1:game.boardSize)
        for j in (1:game.boardSize)
            if game.board[i, j] == 1
                push!(redMoves,toCoord(game, i,j))
            end
            if game.board[i,j] == 2
                push!(blueMoves,toCoord(game, i,j))
            end
            if game.board[i,j] == 0
                push!(emptySpaces, toCoord(game,i,j))
            end
        end
    end
    plotMoveLines(game)
    plotEmptySpaces(emptySpaces)
    plotLines(game)
    plotRedPieces(redMoves)
    plotBluePieces(blueMoves)
end

function toCoord(game::Hex, i::Int, j::Int)::Tuple{Int,Int}
    y = game.boardSize - i + j 
    x = game.boardSize*2 - (i + j)
    return (y,x)
end

function plotMoveLines(game)
    default(lab="")
    gw = 2*game.boardSize
    Plots.plot([(game.boardSize*2,1),(game.boardSize*2,1)])
    for i=(1:game.boardSize)
        Plots.plot!([toCoord(game,1,i), toCoord(game,game.boardSize,i)], c = :black) 
        Plots.plot!([toCoord(game,i,1), toCoord(game,i,game.boardSize)], c = :black)
        Plots.plot!([toCoord(game,i,1), toCoord(game,1,i)], c= :black)
        Plots.plot!([toCoord(game,game.boardSize, i), toCoord(game,i, game.boardSize)], c=:black) 
    end
end

function plotEmptySpaces(coords)
    Plots.plot!(coords,
        seriestype = :scatter,
        c = :grey,
        markersize = 16)
end

function plotLines(game)
    midHeight = 2*game.boardSize - (1 + game.boardSize)
    maxHeight = 2*game.boardSize - (1 + 1)
    Plots.plot!([0.5,game.boardSize], [midHeight, -0.5], c=:red)    
    Plots.plot!([game.boardSize, 2*game.boardSize - 1 + 0.5], [maxHeight + 0.5, midHeight], c=:red)    
    Plots.plot!([0.5,game.boardSize], [midHeight, maxHeight+0.5], c=:blue)    
    Plots.plot!([game.boardSize, 2*game.boardSize - 1 + 0.5], [-0.5, midHeight], c=:blue)
end

function plotRedPieces(coords)
    Plots.plot!(coords,
        seriestype = :scatter,
        c = :red,
        markersize = 16)
end

function plotBluePieces(coords)
    Plots.plot!(coords,
        seriestype = :scatter,
        c = :blue,
        markersize = 16)
end


function visualize(game::Hex)
    actions = game.executedMoves
    game = createGame(game.boardSize, game.startingPlayer)
    animation = @animate for i in (1:length(actions) + 1)
        try
            printBoard(game)
            executeMove!(game, actions[i])
        catch
            printBoard(game)
        end
    end
    savefig("C:\\Users\\sebas\\dev\\AIprog\\assignment3\\animations\\hex.png")
    gif(animation, "C:\\Users\\sebas\\dev\\AIprog\\assignment3\\animations\\hex.gif" ,fps=1)
end

"""
hex = createGame(5, 1)
moves = [8, 16, 7, 20, 15, 0, 1, 9, 6, 21, 5, 11, 14, 2, 17, 18, 3, 24, 19, 22, 13, 10, 23] 
for move in moves
    executeMove!(hex, HexMove(convert(Int64,move ÷ hex.boardSize + 1), convert(Int64, move % hex.boardSize + 1)))
end
println(length(hex.executedMoves))
println("Winner: ", getPreviousPlayer(hex))
visualize(hex)
"""
