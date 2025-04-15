#######################################################
# Main file for EAO.jl module
# 
# Author: Luis van Sandbergen
# Date: 30.11.2024
#######################################################
module EAO

# import external Modules
using JuMP
using Dates

# Include main module Files
include("basic_types.jl")
include("assets.jl")
include("io.jl")
include("portfolio.jl")
include("optimization.jl")

end # end module