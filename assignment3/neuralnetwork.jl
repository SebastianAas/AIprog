import Base: show, deepcopy
using Metalhead
using Flux
using Flux: @epochs
using CuArrays
using CSV
using DataFrames
using BSON: @save


struct NeuralNet
    base::Chain
    value::Chain
    policy::Chain
  end

  
function NeuralNet(boardSize, towerHeight::Int = 7)

    res_block() = Metalhead.ResidualBlock([48,48,48], [3,3], [1,1], [1,1])

    resblocks = [res_block() for i = 1:towerHeight]
    base = Chain(Conv((3,3), 1=>48, pad=(1,1)),
                        BatchNorm(48, relu),
                        resblocks...) #|> gpu

    value = Chain(Conv((1,1), 48=>1),
                BatchNorm(1, relu), 
                x->reshape(x, boardSize^2, :),
                Dense(boardSize^2, 48, relu),
                Dense(48, 1, tanh)) #|> gpu

    policy = Chain(Conv((1,1), 48=>48), 
                    BatchNorm(48,relu),
                    x->reshape(x, :, size(x, 4)),
                    Dense(48*boardSize^2, boardSize^2),
                    softmax) #|> gpu
    NeuralNet(base, value, policy)
end

function flatten(input)
    return reshape(input, :, size(input,4))
end

function createNeuralNet(boardSize, towerHeight::Int = 7)
    
    res_block() = Metalhead.ResidualBlock([48,48,48], [3,3], [1,1], [1,1])

    resblocks = [res_block() for i = 1:towerHeight]
    model = Chain(Conv((3,3), 1=>48, pad=(1,1)),
                        BatchNorm(48, relu),
                        resblocks...,
                    Conv((1,1), 48=>48), 
                    BatchNorm(48,relu),
                    flatten,
                    Dense(48*boardSize^2, boardSize^2),
                    softmax) #|> gpu
    return model
end


function Base.show(io::IO, nn::NeuralNet)
    println("Base: ", nn.base)
    println("Policy: ", nn.policy)
    println("Value: ", nn.value)
end


function (nn::NeuralNet)(input) 
  nnInput = cat(dims=4, input) |> gpu

  baseOutput = nn.base(nnInput)
  π, val = nn.policy(baseOutput), nn.value(baseOutput)
  
  return π
end

function train!(nn::NeuralNet, inputData)
    input = inputData |> gpu
    loss(x,y) = Flux.crossentropy(nn(x), y)
    ps = params(nn.base)
    Flux.Optimise.train!(loss, ps, input, ADAM())
    ps = params(nn.policy)
    Flux.Optimise.train!(loss, ps, input, ADAM())
end

function train!(nn::Chain, inputData)
    input = inputData #|> gpu
    function loss(x,y) 
        l = Flux.crossentropy(nn(x), y)
        #println(l)
        return l
    end
    ps = params(nn)
    @epochs 5 Flux.Optimise.train!(loss, ps, input, RMSProp())
end

function stringToArray(string)
    string = replace(string, r"[^0-9,]" => "")
    array = split(string, ",")
    array = map(x -> parse(Int64, x), array)
    return array
end

function accuracy(nn, x, y)
    sum = 0
    loss(x,y) = Flux.crossentropy(nn(x), y)
    for i in length(x)
        sum += loss(x[i],y[i])
    end
    return sum
end

function normalize(array)
    map(x-> x/sum(array), array)
end

function trainNetwork2()
    df = CSV.read("trainingData.csv")
    data = [cat(dims=4, stringToArray(x.data)[2:end]) for x in eachrow(df)]
    labels = [normalize(stringToArray(x.labels)) for x in eachrow(df)]
    data1 = [(data[i], labels[i]) for i in 1:length(data)]
    train, test = data1[1:((length(data1))*3)÷4], data1[((length(data1))*3)÷4+1:end]
    trainx, trainy = map(x -> x[1], data1[1:50]), map(x-> x[2], data1[1:50])
    testx, testy = map(x -> x[1], test), map(x-> x[2], test)
    nn = createNeuralNet(4,4)
    savedir = 50
    for i in 1:200
        train1 = rand(train, 32)
        train!(nn, train1)
        if i % 50 == 0
            print("saving model...")
            model = nn
            @save "./models3/resnet-$i.bson" model
        end
        println(accuracy(nn,testx,testy))
    end
end

function trainNetwork()
    df = CSV.read("trainingData.csv")
    data = [cat(dims=4, stringToArray(x.data)[2:end]) for x in eachrow(df)]
    labels = [normalize(stringToArray(x.labels)) for x in eachrow(df)]
    data1 = [(data[i], labels[i]) for i in 1:length(data)]
    train, test = data1[1:((length(data1))*3)÷4], data1[((length(data1))*3)÷4+1:end]
    trainx, trainy = map(x -> x[1], data1[1:50]), map(x-> x[2], data1[1:50])
    testx, testy = map(x -> x[1], test), map(x-> x[2], test)
    nn = createNeuralNet(4,4)
    i = 0
    ba = 1000000
    savedir = 50
    for i in 1:200
        train1 = rand(train, 128)
        train!(nn, train1)
        if accuracy(nn, testx, testy) < ba
            ba = accuracy(nn,testx,testy)
            model = nn
            println("saving model...")
            @save "./resnet/neuralnet-$savedir.bson" model
        end
        if i % 50 == 0
            savedir = i + 50
        end
        println(accuracy(nn,testx,testy))
    end
end

trainNetwork2()