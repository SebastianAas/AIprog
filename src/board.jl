#=
board:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-01-20
=#

using Plots, PyPlot, NaNMath, ProgressMeter

abstract type Shape end
struct Diamond <: Shape end
struct  Triangle <: Shape end

mutable struct Board
    shape::String
    size::Int
    grid::Array
    legalMoves::Array
end

struct Move
    from::Tuple{Int,Int}
    to::Tuple{Int,Int}
end


function generateBoard(shape::String, size::Int, startPositionArray)
    grid = fill(NaN, size,size)
    for i in (1:size)
        numberOfColumns = (shape == "Triangle" ? i : size)
        for j in (1:numberOfColumns)
            if (i,j) in startPositionArray
                grid[i, j] = 0
            else
                grid[i, j] = 1
            end
        end
    end
    legalMoves = if (shape == "Triangle")
        [(0,1), (0,-1), (1,0), (-1,0), (1,1), (-1,-1)]
    else
        [(0,1), (1,0), (-1,1), (1,-1), (0, -1), (-1,0)]
    end
    return Board(shape, size, grid, legalMoves)
end

function getAvailableMoves(board::Board)::Array{Move}
    availableMoves = []
    for i in (1:board.size)
        for j in (1:board.size)
            if board.grid[i,j] !== 1.0
                continue
            else
                possibleMoves = getAvailableMoves(board, (i,j))
                if length(possibleMoves) > 0
                    possibleMoves = getAvailableMoves(board, (i,j))
                    for move in possibleMoves
                        push!(availableMoves, move)
                    end
                end
            end
        end
    end
    return availableMoves
end

function getAvailableMoves(board::Board, position::Tuple{Int,Int})::Array{Move}
    i,j = position
    availableMoves = []
    for move in board.legalMoves
        try
            #Check if the neighbor not has a pin => break
            if !neighborHasPin(board, move, i, j)
                continue
            else
                if secondNeighborEmpty(board, move, i, j)
                    push!(availableMoves, Move((i,j), (i + 2*move[1], j + 2*move[2])))
                end
            end
        catch BoundsError
            continue
        end
    end
    return availableMoves
end

function getReward(board::Board)::Int
    if isDone(board)
        return r = 1
    elseif length(getAvailableMoves(board)) == 0
        return r = 0
    else
        return r = 0
    end
end

function isDone(board::Board)::Bool
    return NaNMath.sum(board.grid) == 1
end

function notDone(board::Board)::Bool
    return NaNMath.sum(board.grid) != 1
end

function neighborHasPin(board::Board, move::Tuple{Int,Int}, i::Int,j::Int)
   return board.grid[i+move[1], j+move[2]] == 1
end

function secondNeighborEmpty(board::Board, move::Tuple{Int,Int}, i::Int, j::Int)
    try
        if board.grid[i + 2*move[1], j + 2*move[2]] == 0.0
            return true
        end
    catch BoundsError
        return false
    end
    return false
end

function executeMove!(board::Board, move::Move)
    newBoard = deepcopy(board)
    Δx = move.to[1] - move.from[1]
    Δy = move.to[2] - move.from[2]
    newBoard.grid[move.from[1], move.from[2]] = 0
    newBoard.grid[move.from[1] + convert(Int,Δx/2), move.from[2] + convert(Int,Δy/2)] = 0
    newBoard.grid[move.to[1], move.to[2]] = 1
    return newBoard
end

function getIndexMove(move::Move)
    return (move.from, move.to)
end

function getState(board::Board)
    s = (board.size * (board.size+1))/2
    state = zeros(convert(Int,s))
    count = 1
    if board.shape == "Triangle"
        for i in (1:board.size)
            for j in (1:i)
                state[count] = board.grid[i,j]
                count += 1
            end
        end
    else
        state = board.grid
    end
    return vec(state)
end

function getNumberOfRemainingPegs(board::Board)
   return NaNMath.sum(board.grid)
end


function printBoardTerminal(board::Board)
    for row in board.grid
        for j in row
            if(j == 1)
                print("⚫")
            else
                print("⚪")
            end
            print("  ")
        end
        println("")
    end
end

function printBoard(board::Board)
    gr()
    if board.shape == "Triangle"
        printTriangleBoard(board)
    else
        printDiamondBoard(board)
    end
end

function printTriangleBoard(board::Board)
    x, y, m, n = [], [], [], []
    for i in (1:board.size)
        for j in (1:board.size)
            if board.grid[i, j] == 1
               push!(x, -i)
               push!(y, j + 1/2*(board.size - i))
            end
            if board.grid[i,j] == 0
                push!(m, -i)
                push!(n, j + 1/2*(board.size - i))
            end
        end
    end
    plotEmptySpaces(n,m)
    plotPins(y,x)
end

function printDiamondBoard(board::Board)
    x, y, m, n = [], [], [], []
    neighborgraph = []
    gw = 2*board.size - 2
    for i in (1:board.size)
        for j in (1:board.size)
            if board.grid[i, j] == 1
                push!(x, gw/2 - i + j)
                push!(y, gw - (i + j))
            end
            if board.grid[i,j] == 0
                push!(m, gw/2 - i + j)
                push!(n, gw - (i + j))
            end
        end
    end
    plotEmptySpaces(m,n)
    plotPins(x,y)
end

function plotEmptySpaces(x, y)
    Plots.plot(x, y,
        seriestype = :scatter,
        c = :grey,
        markersize = 16)
end

function plotPins(x, y)
    Plots.plot!(x, y,
        seriestype = :scatter,
        c = :orange,
        markersize = 16)
end

function plotNeighborGraphs(x,y)
    Plots.plot!(x,y,
    c= :grey)
end

function visualize(board::Board, actions::Array{Move}, startPositions, fps)
    new_board = generateBoard(board.shape, board.size, startPositions)
    animation = @animate for i in (1:length(actions) + 1)
        try
            printBoard(board)
            board = executeMove!(board,actions[i])
        catch
            printBoard(board)
        end
    end
    gif(animation, "C:\\Users\\sebas\\dev\\AIprog\\src\\animations\\animationDiamond.gif" ,fps=1)
end

