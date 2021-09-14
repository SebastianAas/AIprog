#=
tests:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-02-02
=#
using Test
include("board.jl")
include("environment.jl")
include("config.jl")

@testset "Check if find available moves method works" begin
    board = generateBoard("Triangle", 4, [(2,2)])
    @testset "Find empty second neighbor" begin
        @test secondNeighborEmpty(board, (-1,-1), 4, 4) == true
    end
    @test getAvailableMoves(board) == [Move((4,2), (2,2)), Move((4,4),(2,2))]
end

@testset "Check if endcondition works" begin
    board = generateBoard("Diamond", 2, [(2,2), (1,1), (2,1)])
    @test isDone(board) == true
    board2 = generateBoard("Triangle", 3, [(1,1), (2,1), (3,1), (3,2), (3,3)])
    @test isDone(board2) == true
end

@testset "Check if board state changes" begin
    e = Environment(generateBoard("Diamond", 3, [(1,1)]))
    state = getState(e)
    m = Move((1,3), (1,1))
    newState, r = move!(e,m)
    @test state != newState
end


