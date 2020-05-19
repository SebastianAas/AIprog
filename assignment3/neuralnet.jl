using Flux
using CuArrays
using CUDAdrv
using CSV
using DataFrames
using BSON: @save
using IterTools: ncycle

struct NeuralNet
    model::Chain
end

function NeuralNet(boardSize, layers =  [128, 64])
    blocks = [Dense(layers[i-1],layers[i], relu) for i = 2:length(layers)]

    model = Chain(
        Dense(boardSize^2 + 1, layers[1], relu),
        blocks...,
        Dense(layers[end], boardSize^2),
        softmax) #|> gpu
    
    NeuralNet(model)
end
    

function (nn::NeuralNet)(input)
  nnInput = vec(input) #|> gpu

  output = nn.model(nnInput)
  
  return output
end

function train!(nn::NeuralNet, input)
    loss(x,y) = Flux.crossentropy(nn(x), y)
    data = ncycle(input, 3)
    ps = params(nn.model)
    Flux.Optimise.train!(loss, ps, data, optimizer)
end

function stringToArray(string)
    string = replace(string, r"[^0-9,]" => "")
    array = split(string, ",")
    array = map(x -> parse(Int64, x), array)
    return array
end

function normalize(array)
    map(x-> x/sum(array), array)
end


"""
nlayers = createLayers(4, layers, NNlib.sigmoid)
m = Chain(nlayers...)
nn = NeuralNet(Chain(nlayers...), ADAM())
#loss(x, y) = Flux.mse(m(x), y)
#ps = Flux.params(m)
#xs = [rand(36)]
#data = zip(xs, ys)

df = CSV.read("randomData.csv")
data = [stringToArray(x.data) for x in eachrow(df)]
labels = [normalize(stringToArray(x.labels)) for x in eachrow(df)]
data1 = [(data[i], labels[i]) for i in 1:length(data)]
train, test = data1[1:((length(data1))*3)÷4], data1[((length(data1))*3)÷4+1:end]
testx, testy = map(x -> x[1], test), map(x-> x[2], test)
i = 0
nn = NeuralNet(5)
for i in 1:200
    trainData = rand(train, 64)
    train!(nn, trainData)
    if i % 50 == 0
		model = nn
		@save "./models2/neuralnet-.bson" model
    end
    println(accuracy(nn,testx,testy))
end
"""