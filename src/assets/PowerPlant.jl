#######################################################
# File to model PowerPlant asset.
# 
# Author: Luis van Sandbergen
# Date: 16.04.2025
#######################################################

# Abstract type for PowerPlant
abstract type AbstractPowerPlant <: AbstractAsset end

# Concrete PowerPlant object
"""
    PowerPlant
A power plant that is able to produce at given prices up to a given capacity.

# Arguments
- `name::String`: Name of the power plant
- `nodes::Union{Node, Array{Node}}`: Node or nodes the power plant is connected to
- `start::DateTime`: Start time of the power plant
- `finish::DateTime`: Finish time of the power plant
- `price::String`: Price of the power plant
- `min_cap::Real`: Minimum capacity of the power plant
- `max_cap::Real`: Maximum capacity of the power plant
"""
mutable struct PowerPlant <: AbstractPowerPlant
    name::String
    nodes::Union{Node, Array{Node}}
    start::DateTime
    finish::DateTime
    price::String
    min_cap::Real
    max_cap::Real

    function PowerPlant(name::String, nodes, start::DateTime, finish::DateTime, price::String, min_cap::Real, max_cap::Real)
        if start > finish
            throw(ArgumentError("start must be <= finish"))
        end
        if min_cap > max_cap
            throw(ArgumentError("min_cap must be <= max_cap"))
        end
        new(name, nodes, start, finish, price, min_cap, max_cap)
    end
end

"""
    add_to_model(model::Model,
                    asset::PowerPlant,
                    timegrid::Timegrid,
                    price_dict::Dict{String,Vector{Float64}})

Extends the JuMP model with variables & constraints for a power plant.
Returns the contribution to the target function (revenue - costs) as a JuMP expression.
"""
function add_to_model(model::Model,
                    asset::PowerPlant,
                    timegrid::Timegrid,
                    price_dict::Dict{String,Vector{Float64}})
    
    # Add variables
    @variable(model, disp[1:timegrid.T], lower_bound = asset.min_cap * timegrid.dt[1], upper_bound = asset.max_cap * timegrid.dt[1])
    
    # Add constraints
    @constraints model begin
        [t in 1:timegrid.T], disp[t] >= asset.min_cap * timegrid.dt[t]
        [t in 1:timegrid.T], disp[t] <= asset.max_cap * timegrid.dt[t]
    end
    
end


# Can be implemeted later to set up single optimization problems
function setup_optim_problem(
    asset::PowerPlant, 
    timegrid::Timegrid, 
    prices::Dict{String,Vector{Float64}},
    solver
)

model = Model(solver)

return nothing
end