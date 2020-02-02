#=
test:
- Julia version: 1.3.1
- Author: sebas
- Date: 2020-01-13
=#
using Plots, ProgressMeter
pyplot()


Plots.plot([(0,0), (1,1), (1,2), (1,3), (1,4), (2,1), (2,2), (2,3), (3,1), (3,2), (4,1)],
    seriestype = :scatter,
    markersize = 10,
    c = :orange,
    title = "Let's go!'")

savefig("./animations/plot.png")

"""
animation = @animate for i in (1:4)
    plot!(i,i)
end

gif(animation, "C:\\Users\\sebas\\dev\\AIprog\\src\\animations\\plot1.gif" ,fps=15)
"""

