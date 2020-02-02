#=
board:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-01-20
=#

using Plots, PyPlot, NaNMath

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
        [(0,1), (1,0), (-1,-1), (1,1), (0, -1), (-1,0)]
    end
    return Board(shape, size, grid, legalMoves)
end

function getAvailableMoves(board::Board)
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
    availableMoves
end

function getAvailableMoves(board::Board, position::Tuple{Int,Int})
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
    availableMoves
end

function notDone(board::Board)
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
    Δx = move.to[1] - move.from[1]
    Δy = move.to[2] - move.from[2]
    board.grid[move.from[1], move.from[2]] = 0
    board.grid[move.from[1] + convert(Int,Δx/2), move.from[2] + convert(Int,Δy/2)] = 0
    board.grid[move.to[1], move.to[2]] = 1
    return board
end

function getState(board::Board)
    return board.grid
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
    if board.shape == "Triangle"
        printTriangleBoard(board)
    else
        printDiamondBoard(board)
    end
end


function printTriangleBoard(board::Board)
    pyplot()
    x, y, m, n = [], [], [], []
    for i in (1:board.size)
        for j in (1:board.size)
            if board.grid[i, j] == 1
                push!(x, -i)
                push!(y, j)
            end
            if board.grid[i,j] == 0
                push!(m, -i)
                push!(n, j)
            end
        end
    end
    plotEmptySpaces(m,n)
    plotPins(x,y)
    Plots.savefig("./animations/board.png")
end

function printDiamondBoard(board::Board)
    pyplot()
    x, y, m, n = [], [], [], []
    gw = 2*size(board.grid,1) - 2
    for i in (1:board.size)
        for j in (1:board.size)
            if board.grid[i, j] == 1
                push!(x, gw/2 - i + j)
                push!(y, gw - (i + j))
            end
            push!(m, gw/2 - i + j)
            push!(n, gw - (i + j))
        end
    end
    plotEmptySpaces(m,n)
    plotPins(x,y)
    Plots.savefig("./animations/board.png")
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



#board = generateBoard("Triangle", 4, [(4,4)])
#executeMove!(board, Move((2,2), (4,4)))
#display(board.grid)
#println(getAvailableMoves(board))
#printBoardTerminal(board)
#printBoard(board)
