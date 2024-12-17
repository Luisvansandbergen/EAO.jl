#######################################################
# Main file for EAO.jl module
# 
# Author: Luis van Sandbergen
# Date: 30.11.2024
#######################################################
module EAO

# import external Modules
import JuMP
using Dates

# Include main module Files
include("basic_types.jl")
include("assets.jl")
include("io.jl")
include("portfolio.jl")

function myfirsttestfunction()
    print("Hi!")
    
    return 1
end




end # end module