#######################################################
# File to model Storage asset.
#
# Author: Luis van Sandbergen
# Date: 24.01.2025
#######################################################

# Abstract type for Storage
abstract type AbstractStorage <: AbstractAsset end

# Concrete Storage object
"""
    Storage
A storage that can charge and discharge at given efficiencies and capacities.

# Arguments
- `name::String`: Name of the storage
- `nodes::Union{Node, Array{Node}}`: Node or nodes the storage is connected to
- `start::DateTime`: Start time of the storage
- `finish::DateTime`: Finish time of the storage
- `price::String`: Price key for the storage
- `cap_in::Real`: Maximum charge rate (MW)
- `cap_out::Real`: Maximum discharge rate (MW)
- `size::Real`: Maximum storage capacity (MWh)
- `discharge_eff::Real`: Discharge efficiency (0-1)
- `charge_eff::Real`: Charge efficiency (0-1)
- `start_level::Real`: Initial fill level (MWh), default 0.0
- `end_level::Union{Real, Nothing}`: Required final fill level (MWh), or nothing
- `cost_in::Real`: Per-MWh charging cost, default 0.0
- `cost_out::Real`: Per-MWh discharging cost, default 0.0
- `cost_store::Real`: Per-MWh-period storage holding cost, default 0.0
"""
mutable struct Storage <: AbstractStorage
    name::String
    nodes::Union{Node, Array{Node}}
    start::DateTime
    finish::DateTime
    price::String
    cap_in::Real
    cap_out::Real
    size::Real
    discharge_eff::Real
    charge_eff::Real
    start_level::Real
    end_level::Union{Real, Nothing}
    cost_in::Real
    cost_out::Real
    cost_store::Real
end

# Constructor for Storage with keyword arguments and defaults for new fields
function Storage(; name::String,
                  nodes::Union{Node, Array{Node}},
                  start::DateTime, finish::DateTime,
                  price::String,
                  cap_in::Real, cap_out::Real,
                  size::Real,
                  discharge_eff::Real, charge_eff::Real,
                  start_level::Real = 0.0,
                  end_level::Union{Real, Nothing} = nothing,
                  cost_in::Real = 0.0,
                  cost_out::Real = 0.0,
                  cost_store::Real = 0.0)
    return Storage(name, nodes, start, finish, price,
                   cap_in, cap_out, size, discharge_eff, charge_eff,
                   start_level, end_level, cost_in, cost_out, cost_store)
end

"""
    add_variables_to_model!(model, asset::Storage, tg, price_dict)

Add storage variables and constraints to the JuMP model.

Creates four variable arrays:
- `dispatch_in[1:T]`:  energy charged from the node (MWh), bounded by `[0, cap_in * dt]`
- `dispatch_out[1:T]`: energy withdrawn from storage (MWh), bounded by `[0, cap_out * dt]`
- `fill_level[1:T]`:   storage fill level (MWh), bounded by `[0, size]`
- `net_dispatch[1:T]`: net energy flow at the node (positive = discharging, negative = charging)

Constraints:
- Fill balance: `fill[t] = prev + charge_eff * dispatch_in[t] - dispatch_out[t]`
- Net dispatch: `net_dispatch[t] = dispatch_out[t] * discharge_eff - dispatch_in[t]`
- End level (optional): `fill_level[T] == end_level`

Returns `(net_dispatch, profit)` for integration with the portfolio dispatch registry.
"""
function add_variables_to_model!(
    model::Model,
    asset::Storage,
    tg::Timegrid,
    price_dict::Dict{String,Vector{Float64}}
)
    T  = tg.T
    dt = dt_in_hours(tg.dt)

    # 1) Variables
    dispatch_in = @variable(model, [1:T],
        lower_bound = 0.0,
        upper_bound = asset.cap_in * dt,
        base_name = "$(asset.name)_disp_in")

    dispatch_out = @variable(model, [1:T],
        lower_bound = 0.0,
        upper_bound = asset.cap_out * dt,
        base_name = "$(asset.name)_disp_out")

    fill_level = @variable(model, [1:T],
        lower_bound = 0.0,
        upper_bound = asset.size,
        base_name = "$(asset.name)_fill")

    # net_dispatch: what the storage contributes to the node
    # positive = discharging (energy to node), negative = charging (energy from node)
    net_dispatch = @variable(model, [1:T],
        base_name = "$(asset.name)_net_disp")

    # 2) Fill level balance constraints
    for t in 1:T
        prev_level = (t == 1) ? asset.start_level : fill_level[t-1]
        @constraint(model,
            fill_level[t] == prev_level + asset.charge_eff * dispatch_in[t] - dispatch_out[t])
    end

    # 3) Net dispatch definition
    for t in 1:T
        @constraint(model,
            net_dispatch[t] == dispatch_out[t] * asset.discharge_eff - dispatch_in[t])
    end

    # 4) Optional end level constraint
    if asset.end_level !== nothing
        @constraint(model, fill_level[T] == asset.end_level)
    end

    # 5) Prices and profit
    prices = price_dict[asset.price]
    @assert length(prices) == T "price curve length must match tg.T = $T"

    profit = @expression(model,
        sum(prices[t] * net_dispatch[t]
            - asset.cost_in * dispatch_in[t]
            - asset.cost_out * dispatch_out[t]
            - asset.cost_store * fill_level[t]
            for t in 1:T))

    return net_dispatch, profit
end
