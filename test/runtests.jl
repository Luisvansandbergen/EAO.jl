using EAO
using Test

@testset "EAO.jl" begin
    # Write your tests here.

    
    node_power = EAO.Node()

    test = EAO.myfirsttestfunction()
    @assert(test==1.0)

end
