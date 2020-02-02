#=
tests:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-02-02
=#

include("board.jl")


board = generateBoard("Triangle", 4, [(2,2)])

@test
secondNeigborEmpty(board, (1,1))