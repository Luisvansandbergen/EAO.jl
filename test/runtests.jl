using EAO
using Test

@testset "EAO.jl Tests" begin

    # Add basic type tests
    include("basictypetests.jl")

    # Add asset tests
    include("assettests.jl")
    
    # Add portfolio tests
    include("portfoliotest.jl")
    
    ## Add more tests here

end