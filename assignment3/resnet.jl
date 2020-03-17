
struct ResidualBlock
    conv_layers
    norm_layers
    shortcut
end


function ResidualBlock(filters, kernels::Array{Tuple{Int,Int}}, pads::Array{Tuple{Int,Int}}, strides::Array{Tuple{Int,Int}}, shortcut = identity)
    local conv_layers = []
    local norm_layers = []
    for i in 2:length(filters)
      push!(conv_layers, Conv(kernels[i-1], filters[i-1]=>filters[i], pad = pads[i-1], stride = strides[i-1]))
      push!(norm_layers, BatchNorm(filters[i]))
    end
    ResidualBlock(Tuple(conv_layers),Tuple(norm_layers),shortcut)
end