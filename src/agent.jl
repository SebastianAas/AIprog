using Flux
using Flux.Tracker

abstract type Agent end

struct Critic <: Agent
    V::Array
    e
end

struct Actor <: Agent
    Π
    e
end

function forward(input, action)
    return true
end


function train()
    for i in 1:epochs
        total_loss = 0
        for j in 1:length(x)
            true
        end
    end
end