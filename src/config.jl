#=
config:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-02-12
=#
module Config
    export boardSize,
    shape,
    startPosition,
    learningRateCritic,
    learningRateActor,
    discountRate,
    traceDecay,
    episodes,
    greedyValueActor,
    fps


    #GLOBAL CONFIG VALUES
    boardSize = 4
    shape = "Diamond"
    startPositions = [(3,2)]
    layers = [16,20,10,1]
    neuralNet = true
    learningRateCritic = 0.5
    learningRateActor = 0.5
    discountRate =  0.99
    traceDecay = 0.99
    episodes = 1000
    greedyValueActor = 1
    fps = 1
end
