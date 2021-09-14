#=
neuralnet:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-02-13
=#

using Flux, Random, Zygote

import Zygote: Params, gradient

# Set random seed for replicability
#Random.seed!(9);

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

