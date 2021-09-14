using ProgressMeter
include("uctSearch.jl")
include("config.jl")
include("ledge.jl")
include("NIM.jl")

struct GameSimulator
    "Number of games in a batch"
    G::Int

    "Number of simulations (and hence rollouts) per actual game move"
    M::Int

    "Starting-player option"
	P::Int

    "The game played; either NIM or Ledge"
    gameType::String

    "To print the game or not"
    verbose::Bool

    "Win statistics"
    statistics::Dict{Int,Int}
end




    






