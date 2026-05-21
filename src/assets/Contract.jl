#######################################################
# File to model Contract asset (extends SimpleContract).
#
# Author: Luis van Sandbergen
# Date: 14.02.2026
#######################################################

"""
    Contract <: AbstractContract

Extended contract with optional minimum/maximum take volumes and ramp constraints.

# Arguments
- `name::String`: Name of the contract
- `nodes::Union{Node, Array{Node}}`: Connected nodes
- `start::DateTime`: Start time
- `finish::DateTime`: End time
- `price::String`: Price curve key
- `min_cap::Real`: Minimum dispatch rate (MW)
- `max_cap::Real`: Maximum dispatch rate (MW)
- `min_take::Union{Nothing, Vector{Tuple{DateTime, DateTime, Float64}}}`:
    Minimum volume constraints as `[(range_start, range_end, min_volume), ...]`
- `max_take::Union{Nothing, Vector{Tuple{DateTime, DateTime, Float64}}}`:
    Maximum volume constraints as `[(range_start, range_end, max_volume), ...]`
- `ramp::Union{Nothing, Real}`: Maximum dispatch rate change per hour (MW/h)
"""
mutable struct Contract <: AbstractContract
    name::String
    nodes::Union{Node, Array{Node}}
    start::DateTime
    finish::DateTime
    price::String
    min_cap::Real
    max_cap::Real
    min_take::Union{Nothing, Vector{Tuple{DateTime, DateTime, Float64}}}
    max_take::Union{Nothing, Vector{Tuple{DateTime, DateTime, Float64}}}
    ramp::Union{Nothing, Real}
end

# Constructor for Contract with keyword arguments
function Contract(; name::String,
                   nodes::Union{Node, Array{Node}},
                   start::DateTime, finish::DateTime,
                   price::String,
                   min_cap::Real, max_cap::Real,
                   min_take::Union{Nothing, Vector{Tuple{DateTime, DateTime, Float64}}} = nothing,
                   max_take::Union{Nothing, Vector{Tuple{DateTime, DateTime, Float64}}} = nothing,
                   ramp::Union{Nothing, Real} = nothing)
    return Contract(name, nodes, start, finish, price,
                    min_cap, max_cap, min_take, max_take, ramp)
end

"""
    add_variables_to_model!(model, asset::Contract, tg, price_dict)

Add contract dispatch variables with optional min_take, max_take, and ramp constraints.

Uses the same dispatch variable and profit convention as `SimpleContract`:
- Dispatch bounds: `[min_cap * dt, max_cap * dt]`
- Profit: `sum(-prices[t] * dispatch[t])`

Additional constraints:
- **min_take**: For each `(start, end, volume)`, constrains `sum(dispatch[t])` over matching
  time indices to be `>= volume`.
- **max_take**: Same but `<= volume`.
- **ramp**: Limits dispatch change between consecutive periods: `|disp[t] - disp[t-1]| <= ramp * dt`.

Returns `(dispatch, profit)`.
"""
function add_variables_to_model!(
    model::Model,
    asset::Contract,
    tg::Timegrid,
    price_dict::Dict{String,Vector{Float64}}
)
    T  = tg.T
    dt = dt_in_hours(tg.dt)

    # 1) Dispatch variables (same as SimpleContract)
    disp = @variable(model, [1:T],
        lower_bound = asset.min_cap * dt,
        upper_bound = asset.max_cap * dt,
        base_name = "$(asset.name)_disp")

    # 2) Prices and profit (same sign convention as SimpleContract)
    prices = price_dict[asset.price]
    @assert length(prices) == T "price curve length must match tg.T = $T"
    profit = @expression(model, sum(-prices[t] * disp[t] for t in 1:T))

    # 3) Min-take constraints
    if asset.min_take !== nothing
        for (mt_start, mt_end, min_vol) in asset.min_take
            indices = [t for t in 1:T if tg.times[t] >= mt_start && tg.times[t] < mt_end]
            if !isempty(indices)
                @constraint(model, sum(disp[t] for t in indices) >= min_vol)
            end
        end
    end

    # 4) Max-take constraints
    if asset.max_take !== nothing
        for (mt_start, mt_end, max_vol) in asset.max_take
            indices = [t for t in 1:T if tg.times[t] >= mt_start && tg.times[t] < mt_end]
            if !isempty(indices)
                @constraint(model, sum(disp[t] for t in indices) <= max_vol)
            end
        end
    end

    # 5) Ramp constraints: |disp[t] - disp[t-1]| <= ramp * dt
    if asset.ramp !== nothing
        ramp_limit = asset.ramp * dt
        for t in 2:T
            @constraint(model, disp[t] - disp[t-1] <= ramp_limit)
            @constraint(model, disp[t-1] - disp[t] <= ramp_limit)
        end
    end

    return disp, profit
end
