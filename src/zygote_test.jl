using Zygote

fs = Dict("sin" => sin, "cos" => cos, "tan" => tan);

W, b = rand(2, 3), rand(2);

println(gradient(x -> fs[readline()](x), 1))

predict(x) = W*x .+ b;

g = gradient(Params([W, b])) do
    sum(predict([1,2,3]))
  end

println(g[W])
println(g[b])