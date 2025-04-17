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
    println(typeof(T))

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

using JuMP


"""
    add_power_balance_constraints!(
        model,
        dispatch_registry,
        plants,
        node_demands,
        tg::Timegrid
    )

For each node in `node_demands`, collects all dispatch
variables of the plants connected to that node and adds

    ∀ t ∈ 1:tg.T:  sum_{i ∈ assets_at_node} disp_i[t] == node_demands[node][t]
"""
function add_power_balance_constraints!(
    model::Model,
    dispatch_registry::Dict{String,Vector{VariableRef}},
    plants::Vector{PowerPlant},
    node_demands::Dict{Node,Vector{Float64}},
    tg::Timegrid
)
    T = tg.T

    # 1) Build a map Node -> Vector of dispatch Vars
    node_vars = Dict{Node, Vector{Vector{VariableRef}}}()
    for pp in plants
        # ensure .nodes is always a Vector
        nodes = pp.nodes isa Node ? (pp.nodes, ) : pp.nodes
        disp = dispatch_registry[pp.name]  # your disp[1:T] array
        for nd in nodes
            push!( get!(node_vars, nd, Vector{Vector{VariableRef}}()), disp )
        end
    end

    # 2) For each node, add the time‐indexed balance constraints
    for (nd, var_lists) in node_vars
        demand = node_demands[nd]
        @assert length(demand) == T "Demand curve for $nd must have length T"
        # var_lists is a Vector of dispatch arrays; we want sum across assets
        @constraint(model, [t=1:T],
            sum( disp[t] for disp in var_lists ) == demand[t]
        )
    end

    return nothing
end
