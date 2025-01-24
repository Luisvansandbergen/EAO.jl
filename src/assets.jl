#######################################################
# File where assets are defined.
# 
# Author: Luis van Sandbergen
# Date: 30.11.2024
#######################################################

# Abstract type for assets
abstract type AbstractAsset end

# Include optimization model files
include("assets//Storage.jl")
include("assets//SimpleContract.jl")