using Test
include("ledge.jl")
include("nim.jl")

@testset "Tests for Ledge game" begin
    ledge = Ledge([1,2,0,0,0,0,1,0,0,1])
    @test getMoves(ledge) == [LedgeMove(1, 1, -1), 
        LedgeMove(1, 10, 9), 
        LedgeMove(1, 10, 8), 
        LedgeMove(1, 7, 6), 
        LedgeMove(1, 7, 5), 
        LedgeMove(1, 7, 4), 
        LedgeMove(1, 7, 3)]
    ledge = Ledge([0,2,0,0,0,1])
    @test getMoves(ledge) == LedgeMove[LedgeMove(1, 6, 5), LedgeMove(1, 6, 4), LedgeMove(1, 6, 3), LedgeMove(2, 2, 1)] 
end

@testset "Test for NIM game" begin
    nim = NIM(100, 10)
    @test length(getMoves(nim)) == 10
    nim = NIM(4,6)
    @test length(getMoves(nim)) == 3
end