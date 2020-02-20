#=
neuralnetwork:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-02-13
=#

using Knet, Random, IterTools


# Set random seed for replicability
#Random.seed!(9);

#Loss function
mse(ŷ, y) = sum((ŷ .- y).^2) * 1 // length(y)

# Define dense layer:
struct Dense; w; b; f; end
(d::Dense)(x) = d.f.(d.w * x .+ d.b)
(d::Dense)(x,y) = mse(x, y) #Loss function 
Dense(i::Int,o::Int,f=sigm) = Dense(Param(randn(o,i)), Param(zeros(o)), f);

# Define a chain of layers:
struct Chain; layers end
(c::Chain)(x) = (for l in c.layers; x = l(x); end; x)
(c::Chain)(x,y) = mse(c(x),y)

#Function for finding the gradient of a layer
lossgradient = grad(mse)

function updateEligibility(e, gradient, w, δ)
    if length(e) != length(w)
        e = gradient
    else
        e += gradient
    end
    return e
end

function updateWeights!(layer::Dense, α, δ, e)
    for i in (1:length(e[1]))
        layer.w[i,:] .+= α*δ*e[1][i]
    end
    layer.b .+= α*δ*e[2]
end

function updateWeights!(agent, input, α, δ)
    for layer in agent.model.layers
        g = lossgradient(layer,input, δ)
        #println(g)
        #println(length(g))
        agent.e[input][layer] = updateEligibility(agent.e[input][layer],grad, layer, δ)
        updateWeights!(layer, α, δ, agent.e[input][layer])
        input = layer(input)  
    end
end