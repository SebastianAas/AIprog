"Config values for the game"
global boardSize = 5

"Config values for neural network"
global learningRate = 0.001
global layers = [128,64]
global activation = NNlib.relu

"""
Optimisers: 
    SGD(params, η = 0.1; decay = 0)
    ADAM(params, η = 0.001; β1 = 0.9, β2 = 0.999, ϵ = 1e-08, decay = 0)
    ADAGrad(ps, η = 0.01; ϵ = 1e-8, decay = 0)
    RMSProp(params, η = 0.001; ρ = 0.9, ϵ = 1e-8, decay = 0)
"""
global optimizer = ADAM(learningRate)

"Config values for Game Simulator"

global episodes = 100
global searchPerGame = 500
global verbose = false
global startingPlayerOption = 1
global exploration = 1.0


"Config values for TOPP"
global numberOfNets = 4
global gamesInTournament = 25
