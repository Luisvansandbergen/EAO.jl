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

    function PowerPlant(name::String, 
                        nodes, start::DateTime, 
                        finish::DateTime, price::String, 
                        min_cap::Real, 
                        max_cap::Real)
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
    add_variables_to_model!(model, asset, tg, price_dict)

– Adds to `model` a dispatch variable `dispatch[t]` for `t = 1:tg.T`, with
  bounds [asset.min_cap*dt, asset.max_cap*dt].

– Looks up `prices = price_dict[plant.price]` (must be length `tg.T`).

– Returns
    • `dispatch::Vector{VariableRef}`
    • `profit::GenericAffExpr{Float64,VariableRef}`, equal to
        sum(prices[t] * dispatch[t] for t in 1:tg.T)
"""
function add_variables_to_model!(
    model::Model,
    asset::PowerPlant,
    tg::Timegrid,
    price_dict::Dict{String,Vector{Float64}}
)
    # unpack for readability
    T, dt = tg.T, tg.dt.value

    # 1) dispatch variable in MWh (or your time‐unit)
    @variable(model, PowerPlant_disp[1:T],
        lower_bound = asset.min_cap*dt,
        upper_bound = asset.max_cap*dt,
        base_name = "$(asset.name)_disp")

    # 2) pull the prices
    prices = price_dict[asset.price]
    @assert length(prices) == T "price curve length must match tg.T = $T"

    # 3) build the profit expression
    profit = @expression(model, sum(prices[t] * PowerPlant_disp[t] for t in 1:T))

    return PowerPlant_disp, profit
end

function add_constraints_to_model!(
    model::Model,
    asset::PowerPlant,
    variables::Vector{VariableRef},
    tg::Timegrid,
    price_dict::Dict{String,Vector{Float64}}
)
    # unpack for readability
    T, dt = tg.T, tg.dt.value
    #pp_disp = variables.

    # ramping constraints
    #@constraint(model, tg[1:T],
    #pp_disp[t] - pp_disp[t-1] <= asset.ramp_up*dt for t in 2:T)

    return nothing
end


# Can be implemeted later to set up single optimization problems
function setup_optim_problem(
    asset::PowerPlant, 
    timegrid::Timegrid, 
    prices::Dict{String,Vector{Float64}},
    solver
)
    # Create a JuMP-model, for single asset
    model = Model(solver)

    # add variables
    vars, disp, profit = add_variables_to_model!(model, asset, timegrid, prices)
    
    # add constraints
    add_constraints_to_model!(model, asset, vars, timegrid, prices)
    
    # Objective: maximize total profit
    @objective(model, Max, sum(profit_terms))

    return model
end