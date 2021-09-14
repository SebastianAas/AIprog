#=
peg_solitaire:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-01-13
=#
using Plots
using Colors

mutable struct Cell
    occupied::Bool
    neighbors::Array{Cell}
    position::Tuple{Int64,Int64}
end


abstract type Shape end
struct Diamond <:Shape end
struct  Triangle <: Shape end

mutable struct Board
    grid::Array
    shape
end

function setOccupiedValue!(cell::Cell, value::Bool)
    cell.occupied = value
end

function getPreviousMadeNeighbors(x, y, grid::Array, shape)
    neighbors = []
    legal_moves = [(0,1), (1,0), (1,1)]
    for cell in grid
        #up
        if x - cell.position[1] == 0 && y - cell.position[2] == 1
            push!(neighbors, cell)
        end
        #left
        if x - cell.position[1] == 1 && y - cell.position[2] == 0
            push!(neighbors, cell)
        end
        #diagonal left
        if shape <: Triangle
            if x - cell.position[1] == 1 && y - cell.position[2] == 1
                push!(neighbors, cell)
            end
        end
        if shape <: Diamond
            if x - cell.position[1] == 1 && y - cell.position[2] == -1
                push!(neighbors, cell)
            end
        end
    end
    neighbors
end

function updateNeighborDependecy!(neighbors::Array, cell::Cell)
    for neighbor in neighbors
        push!(neighbor.neighbors,cell)
    end
end


function generateBoard(size::Int, shape, startPosition)
    grid = []
    for i in (1:size)
        rows = []
        numberOfColumns = (shape <: Triangle ? i : size)
        for j in (1:numberOfColumns)
            neighbors = []
            if !isempty(grid)
                neighbors = getPreviousMadeNeighbors(i,j, grid[i-1], shape)
            end
            if !isempty(rows)
                push!(neighbors, rows[j-1])
            end
            pegValue = !(startPosition == (i,j))
            cell = Cell(pegValue, neighbors, (i,j))
            if !isempty(neighbors)
                updateNeighborDependecy!(neighbors, cell)
            end
            push!(rows, cell)
        end
        push!(grid,rows)
    end
    return Board(grid, shape)
end

function isDone(board::Board)
    length(getAvailableMoves(board)) == 0
end

function executeMove(board::Board, startPos, endPos)
    Δx = endPos[1] - startPos[1]
    Δy = endPos[2] - startPos[2]
    setOccupiedValue!(board.grid[startPos[1]][startPos[2]], false)
    setOccupiedValue!(board.grid[startPos[1] + convert(Int,Δx/2)][startPos[2] + convert(Int,Δy/2)], false)
    setOccupiedValue!(board.grid[endPos[1]][endPos[2]], true)
end

function getAvailableMoves(board::Board)
    availableMoves = []
    for row in board.grid
        for cell in row
            available = getAvailableMoves(board, cell)
            if length(available) > 0
                push!(availableMoves, (cell.position, available))
            end
        end
    end
    availableMoves
end

function getAvailableMoves(board::Board, cell::Cell)
    availableMoves = []
    if cell.occupied == false
        return availableMoves
    end
    for neighbor in cell.neighbors
        if (neighbor.occupied == false)
            continue
        end
        direction = findDirection(cell, neighbor)
        for secondNeighbor in neighbor.neighbors
            if (secondNeighbor.occupied == true)
                continue
            end
            if  direction == findDirection(neighbor, secondNeighbor)
                push!(availableMoves, secondNeighbor.position )
            end
        end
    end
    availableMoves
end

function findDirection(cell::Cell, neighbor::Cell)
    Δx = cell.position[2] - neighbor.position[2]
    Δy = cell.position[1] - neighbor.position[1]
    return (Δx, Δy)
end



function printBoard(board::Board)
    for row in board.grid
        for cell in row
            if(cell.occupied)
                print("⚫")
            else
                print("⚪")
            end
            print("  ")
        end
        println("")
    end
end


function printBoard(board::Board, debug::Bool, savepath::String)
    path = "./animations/$(savepath)"
    if board.shape <: Triangle
        printTriangleBoard(board, debug, path)
    end
    if board.shape <: Diamond
        printDiamondBoard(board, debug, path)
    end
end


function printTriangleBoard(board::Board, debug::Bool, savepath::String)
    gr()
    x, y, i, j = [], [], [], []
    for cells in board.grid
        for cell in cells
            if cell.occupied == true
                if debug
                    push!(x, -cell.position[1])
                    push!(y, cell.position[2])
                else
                    push!(x, -cell.position[1])
                    push!(y, cell.position[2] + (1/2 * (length(board.grid) - length(cells))))
                end
            end
            push!(i, - cell.position[1] + cell.position[2])
            push!(j, (cell.position[2] + (1/2 * length(board.grid) - length(cells))))
        end
    end
    plot(j,i,
    seriestype=:scatter,
    markersize=10,
    c=:grey,
    )
    plot(y,x,
    seriestype=:scatter,
    markersize=10,
    c=:orange,
    )
    savefig(savepath)
end

function printDiamondBoard(board::Board, debug::Bool, savepath::String)
    gr()
    x , y, i, j= [], [], [], []
    gw = 2*length(board.grid) - 2
    for cells in board.grid
        for cell in cells
            if cell.occupied == true
                if debug
                    push!(x, -cell.position[1])
                    push!(y, cell.position[2])
                else
                    push!(x, gw/2 - cell.position[1] + cell.position[2])
                    push!(y, gw - (cell.position[1] + cell.position[2]))
                end
            end
            push!(i, gw/2 - cell.position[1] + cell.position[2])
            push!(j, gw - (cell.position[1] + cell.position[2]))
        end
    end
    plot(i,j,
    seriestype=:scatter,
    markersize=10,
    c=:grey,
    )
    plot!(x,y,
    seriestype=:scatter,
    markersize=10,
    c=:orange,
    )
    savefig(savepath)
end

function printNeighbors(board::Board)
    for row in board.grid
        for cell in row
            println("Position " ,cell.position)
            for neighbor in cell.neighbors
                print(neighbor.position)
                print(" ")
            end
            println("")
        end
        println("")
    end
end



board = generateBoard(5, Diamond, (2,2))
print(getBoardState(board))
#printBoard(board, false, "board2.png")
