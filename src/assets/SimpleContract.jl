#######################################################
# File to model SimpleContract asset.
# 
# Author: Luis van Sandbergen
# Date: 24.01.2025
#######################################################

# Abstract type for contracts
abstract type AbstractContract <: AbstractAsset end

# Concrete Contract object
"""
    SimpleContract
A simple contract that is able to buy or sell (consume/produce) at given prices up to a given capacity.

# Arguments
- `name::String`: Name of the contract
- `nodes::Union{Node, Array{Node}}`: Node or nodes the contract is connected to
- `start::DateTime`: Start time of the contract
- `finish::DateTime`: Finish time of the contract
- `price::String`: Price of the contract
- `min_cap::Real`: Minimum capacity of the contract
- `max_cap::Real`: Maximum capacity of the contract
"""
mutable struct SimpleContract <: AbstractContract
    name::String
    nodes::Union{Node, Array{Node}}
    start::DateTime
    finish::DateTime
    price::String
    min_cap::Real
    max_cap::Real
end

# Constructor for SimpleContract with keyword arguments
function SimpleContract(; name::String, 
                        nodes::Union{Node, Array{Node}}, 
                        start::DateTime, finish::DateTime, 
                        price::String, min_cap::Real, max_cap::Real)
    return SimpleContract(name, nodes, start, finish, price, min_cap, max_cap)
end

"""
    add_variables_to_model!(model, asset, tg, price_dict)

– Adds to `model` a dispatch variable `dispatch[t]` for `t = 1:tg.T`, with
  bounds [plant.min_cap*dt, plant.max_cap*dt].

– Looks up `prices = price_dict[plant.price]` (must be length `tg.T`).

– Returns
    • `dispatch::Vector{VariableRef}`
    • `profit::GenericAffExpr{Float64,VariableRef}`, equal to
        sum(prices[t] * dispatch[t] for t in 1:tg.T)
"""
function add_variables_to_model!(
    model::Model,
    asset::SimpleContract,
    tg::Timegrid,
    price_dict::Dict{String,Vector{Float64}}
)
    # unpack for readability
    T, dt = tg.T, tg.dt.value

    # 1) dispatch variable in MWh (or your time‐unit)
    @variable(model, SimpleContract_disp[1:T],
        lower_bound = asset.min_cap*dt,
        upper_bound = asset.max_cap*dt,
        base_name = "$(asset.name)_disp")

    # 2) pull the prices
    prices = price_dict[asset.price]
    @assert length(prices) == T "price curve length must match tg.T = $T"

    # 3) build the profit expression
    profit = @expression(model, sum(-prices[t] * SimpleContract_disp[t] for t in 1:T))

    return SimpleContract_disp, profit
end

function add_constraints_to_model!(
    model::Model,
    asset::SimpleContract,
    variables::Vector{VariableRef},
    tg::Timegrid,
    price_dict::Dict{String,Vector{Float64}}
)
    return nothing
end

# Can be implemeted later to set up single optimization problems
function setup_optim_problem(
    asset::SimpleContract, 
    timegrid::Timegrid, 
    prices::Dict{String,Vector{Float64}},
    solver
)

model = Model(solver)

return model
end