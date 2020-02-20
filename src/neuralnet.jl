#=
neuralnetwork:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-02-13
=#

using Flux, Random, Zygote

import Zygote: Params, gradient


# Set random seed for replicability
#Random.seed!(9);

#Loss function
mse(ŷ, y) = sum((ŷ .- y).^2) * 1 // length(y)

#Chain(layers::Array{Dense}) = new Chain(layers)

function updateEligibility(e, gradient, xs)
    for x in xs
        if length(e[x]) != gradient
            e[x] = gradient[x]
        else
            e[x] += gradient[x]
        end
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
    for layer in agent.model.layers
        agent.e[input][layer.W] = updateEligibility(agent.e[input][layer.W], layer.W.grad)
        agent.e[input][layer.b] = updateEligibility(agent.e[input][layer.b], layer.b.grad)
        if typeof(agent.e[input][layer.W]) == Tuple{Int64,Int64}
            println("E: ", agent.e[input][layer.W])
            break
        end
        layer.W.data .+= α*δ*agent.e[input][layer.W]
        layer.b.data .+= α*δ*agent.e[input][layer.b]
        input = Tracker.data(layer(input))
        layer.W.grad .= 0.0
        layer.b.grad .= 0.0  
    end
    return Tracker.data(totalLoss)
end

function update!(xs::Params, e, δ, α)
  for x in xs
    e[x] == nothing && continue
    x += e[x]*α
  end
end


function train!(loss, ps, data, e, δ, opt)
    ps = Params(ps)
    gs = Zygote.gradient(ps) do
        loss(data...)
    end
    for p in ps
        if length(e[p]) != length(gs[p])
            continue
        end
        gs[p] .+= e[p]
    end
    e = updateEligibility(e, gs, ps)    
    Flux.Optimise.update!(opt, ps, gs)
end

