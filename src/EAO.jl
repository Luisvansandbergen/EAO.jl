"""
Main file for EAO.jl module

Author: Luis van Sandbergen
Date: 30.11.2024
"""
module EAO

include("assets.jl")
include("io.jl")
include("basic_types.jl")
include("portfolio.jl")


function myfirsttestfunction()
    print("Hi!")
    
    return 1
end

end # module