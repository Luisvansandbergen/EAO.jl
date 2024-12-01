#######################################################
# File where assets are defined.
# 
# Author: Luis van Sandbergen
# Date: 30.11.2024
#######################################################

# Abstract type for assets
abstract type AbstractAsset end

# Abstract type for contracts
abstract type AbstractContract <: AbstractAsset end

# Concrete Contract object
mutable struct Contract <: AbstractContract
    name::String
    nodes::Union{Node, Array{Node}}
    start::DateTime
    finish::DateTime # end results in Julia error
end 


