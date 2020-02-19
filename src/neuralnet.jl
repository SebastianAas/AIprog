#=
neuralnetwork:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-02-13
=#

using Flux, Random, Zygote

import Zygote: Params, gradient


# Set random seed for replicability
Random.seed!(9);

#Loss function
mse(ŷ, y) = sum((ŷ .- y).^2) * 1 // length(y)

#Chain(layers) = new Chain(layers)

function updateEligibility(e, gradient, xs, δ)
    for x in xs
        if length(e[x]) != gradient
            e[x] = gradient[x]*δ
        else
            e[x] += gradient[x]*δ
        end
    end
    return e
end

function updateEligibility(e, gradient)
    if length(e) != gradient
        e = gradient
    else
        e += gradient
    end
    return e
end

function updateWeights!(agent, input, α, δ)
    totalLoss = 0
    pred = agent.model(input)
    #println("Prediction: ", pred)
    loss = mse(pred, δ)
    totalLoss += loss
    Tracker.back!(loss)
    for layer in agent.model.layers[1:end-1]
        agent.e[input][layer.W] = updateEligibility(agent.e[input][layer.W], layer.W.grad)
        agent.e[input][layer.b] = updateEligibility(agent.e[input][layer.b], layer.b.grad)
        if typeof(agent.e[input][layer.W]) == Tuple{Int64,Int64}
            println("E: ", agent.e[input][layer.W])
            break
        end
        layer.W.data .+= α*δ*layer.W.grad
        layer.b.data .+= α*layer.b.grad
        input = Tracker.data(layer(input))
        layer.W.grad .= 0.0
        layer.b.grad .= 0.0  
    end
    return Tracker.data(totalLoss)
end

function apply!(o::Descent, x, Δ)
  Δ .*= o.eta
end

function update!(opt, x, x̄)
  x .-= apply!(opt, x, x̄)
end

function update!(xs::Params, e, δ, α)
  for x in xs
    e[x] == nothing && continue
    x += e[x]*α
  end
end


function train!(loss, ps, data, e, δ, α)
    ps = Params(ps)
    gs = Zygote.gradient(ps) do
        loss(data...)
    end
    e = updateEligibility(e, gs, ps, δ)
    update!(ps, e, δ, α)
end

"""
m1 = Chain(
    Dense(16,10,relu),
    Dense(10,5,relu),
    Dense(5,1)
)

xs = [rand(784), rand(784), rand(784)]
ys = [rand( 10), rand( 10), rand( 10)]
data = zip(xs, ys)

m = Chain(
  Dense(784, 32, σ),
  Dense(32, 10), softmax)

loss(x, y) = Flux.mse(m1(x), y)
ps = params(m1)

train!(loss, ps, [(rand(16), 0.5)], 0.1, 0.1, 0.1)
"""
