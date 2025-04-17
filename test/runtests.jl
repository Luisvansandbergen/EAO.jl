using EAO
using Test

@testset "EAO.jl Tests" begin

    # Add basic type tests
    include("basicTypeTests.jl")

    # Add asset tests
    include("assetTests.jl")
    
    # Add portfolio tests
    include("portfolioTest.jl")
    
    ## Add more tests here

end