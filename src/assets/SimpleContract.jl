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
    add_to_model!(model, c::SimpleContract, T, dt, price_dict)
Erweitert das JuMP-Modell um Variablen & Constraints für einen Contract.
"""
function add_to_model!(model::Model, c::SimpleContract, timegrid::Timegrid, price_dict::Dict{String,Vector{Float64}})
    # 1) Variable dispatch[t], hier erlauben wir positives UND negatives, 
    # falls min_cap < 0
    @variable(model, dispatch[1:T], lower_bound = c.min_cap * dt[1], upper_bound = c.max_cap * dt[1])
    # Aber hier wollen wir es evtl. je Zeitschritt anpassen -> unten in Constraints
    # (In JuMP kann man natürlich pro Index ein eigenes lower_bound definieren, s.u.)

    # Speichern:
    c.variables[:dispatch] = dispatch

    # 2) Detailliertere Bounds:
    #    dispatch[t] in [min_cap * dt[t], max_cap * dt[t]]
    @constraints model begin
        [t in 1:T], dispatch[t] >= c.min_cap * dt[t]
        [t in 1:T], dispatch[t] <= c.max_cap * dt[t]
    end

    # 3) Profit-Expression
    price_array = c.price_key != nothing && haskey(price_dict, c.price_key) ?
                  price_dict[c.price_key] :
                  fill(Float64(0.0), T)

    @expression(model, contract_profit,
        sum( (price_array[t] - c.extra_costs) * dispatch[t] for t in 1:T )
    )

    return contract_profit
end