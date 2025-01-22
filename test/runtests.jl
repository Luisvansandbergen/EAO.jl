using EAO
using Test

@testset "EAO.jl Tests" begin

    # Add asset tests
    include("assettests.jl")
    
    # Add portfolio tests
    include("portfoliotest.jl")
    
    ## Add more tests here

end