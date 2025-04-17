#######################################################
# File to model Storage asset.
# 
# Author: Luis van Sandbergen
# Date: 24.01.2025
#######################################################

# Anstract type for Storage
abstract type AbstractStorage <: AbstractAsset end

# Concrete Storage object
"""
    Storage
A storage object that is able to charge and discharge at given efficiencies and capacities.

# Arguments
- `name::String`: Name of the storage
- `nodes::Union{Node, Array{Node}}`: Node or nodes the storage is connected to
- `start::DateTime`: Start time of the storage
- `finish::DateTime`: Finish time of the storage
- `price::String`: Price of the storage
- `min_cap::Real`: Minimum capacity of the storage
- `max_cap::Real`: Maximum capacity of the storage
- `size::Real`: Maximum charge capacity of the storage
- `η_discharge::Real`: Discharge efficiency of the storage
- `η_charge::Real`: Charge efficiency of the storage
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
end

# Constructor for Storage with keyword arguments
function Storage(; name::String, 
                  nodes::Union{Node, Array{Node}}, 
                  start::DateTime, finish::DateTime, 
                  price::String, cap_in::Real, cap_out::Real, 
                  size::Real, discharge_eff::Real, charge_eff::Real)
    return Storage(name, nodes, start, finish, price, cap_in, cap_out, size, discharge_eff, charge_eff)
end

"""
    add_to_model!(model, sto::Storage, T, dt, price_dict)

Erweitert das JuMP-Modell um Variablen & Constraints für einen Speicher. 
Gibt den Beitrag zur Zielfunktion (Revenue - Costs) als JuMP-Expression zurück.
"""
function add_to_model!(model::Model, 
                       sto::AbstractStorage, 
                       T::Int, 
                       dt::Vector{Float64}, 
                       price_dict::Dict{String,Vector{Float64}})

    # 1) Variablen anlegen
    @variables model begin
        dispatch_in[1:T] >= 0
        dispatch_out[1:T] >= 0
        fill_level[1:T] >= 0
    end

    # Speichere sie in sto.variables, falls wir später auslesen wollen
    sto.variables[:dispatch_in]  = dispatch_in
    sto.variables[:dispatch_out] = dispatch_out
    sto.variables[:fill_level]   = fill_level

    # 2) Constraints
    # a) Kapazität
    @constraints model begin
        [t in 1:T], dispatch_in[t]  <= sto.cap_in  * dt[t]
        [t in 1:T], dispatch_out[t] <= sto.cap_out * dt[t]
    end

    # b) Füllstandsbilanz
    @constraint(model, fill_balance[1:T], fill_level[t] == (
        t == 1 ? 
            sto.start_level + sto.eff_in*dispatch_in[t] - dispatch_out[t] :
            fill_level[t-1] + sto.eff_in*dispatch_in[t] - dispatch_out[t]
    ))
    
    # c) Max. Speichergröße
    @constraint(model, [t in 1:T], fill_level[t] <= sto.size)

    # d) Endlevel
    @constraint(model, fill_level[T] == sto.end_level)

    # 3) Kosten- und Preis-Expression
    # Falls sto.price_key existiert und in price_dict enthalten ist, benutzen wir es
    price_array = sto.price_key != nothing && haskey(price_dict, sto.price_key) ? 
                  price_dict[sto.price_key] : 
                  fill(Float64(0.0), T)  # fallback: zeros

    # Deckungsbeitrag (Revenue - Costs)
    # Wir nutzen eine @expression, die wir zurückgeben.
    @expression(model, storage_profit, 
        sum(price_array[t] * dispatch_out[t]
            - sto.cost_in  * dispatch_in[t]
            - sto.cost_out * dispatch_out[t]
            - sto.cost_store * fill_level[t] 
            for t in 1:T)
    )

    return storage_profit
end


# Can be implemeted later to set up single optimization problems
function setup_optim_problem(
    asset::Storage, 
    timegrid::Timegrid, 
    prices::Dict{String,Vector{Float64}},
    solver
)

model = Model(solver)

return nothing
end