#######################################################
# Main file for Portfolio object
# 
# Author: Luis van Sandbergen
# Date: 17.12.2024
#######################################################

"""
Portfolio

The portfolio struct allows for collecting several assets in a network of nodes 
and optimizing them jointly. In terms of setting up the problem, the portfolio
collects the assets and imposes the restriction of forcing the flows of a 
commodity in each node to be zero in each time step.
"""
mutable struct Portfolio
    assets::Array{AbstractAsset}
    asset_names::Array{String}
    nodes::Array{Node}
    timegrid::Timegrid
    model::Any
end

# Constructor for Portfolio
function Portfolio(assets::Vector{AbstractAsset})
    asset_names = [a.name for a in assets]
    nodes_set = Set{Node}()
    for a in assets
        for n in a.nodes
            push!(nodes_set, n)
        end
    end
    if length(asset_names) != length(Set(asset_names))
        throw(ArgumentError("Asset names in portfolio must be unique"))
    end
    nodes = collect(nodes_set)
    return Portfolio(assets, asset_names, nodes, Timegrid())
end

# Method to set the timegrid
function set_timegrid!(portfolio::Portfolio, timegrid::Timegrid)
    portfolio.timegrid = timegrid
end

"""
    setup_optim_problem(port::Portfolio, T, dt, prices)

Erstellt ein JuMP-Modell, das alle Assets enthält.
- T: Anzahl Zeitstufen
- dt: Vektor mit Zeitschritt-Längen
- prices: Dictionary mit Preisreihen { "market_price" => [5.0,4.0,6.0,...], ... }

Gibt das Modell + die Gesamt-Objective (Expression) zurück.
"""
function setup_optim_problem(
                portfolio::Portfolio, 
                timegrid::Timegrid, 
                prices::Dict{String,Vector{Float64}},
                solver::MathOptInterface.AbstractOptimizer
    )
    
    model = Model(solver)

    # Wir sammeln alle Profit-Expressions in einer Liste
    profit_expressions = Float64[]  # man könnte auch ein Array{AffExpr,1} anlegen
    expr_list = Any[]               # hier sammeln wir JuMP-Expressions

    for asset in portfolio.assets
        if asset isa Storage
            sto_profit = add_to_model!(model, asset::Storage, T, dt, prices)
            push!(expr_list, sto_profit)
        elseif asset isa SimpleContract
            c_profit = add_to_model!(model, asset::SimpleContract, T, dt, prices)
            push!(expr_list, c_profit)
        else
            error("Asset-Typ unbekannt.")
        end
    end

    # Summiere alle Expressions zu einer Gesamt-Objective
    @expression(model, total_profit, sum(expr_list[i] for i in 1:length(expr_list)))
    @objective(model, Max, total_profit)

    return model
end















# Method to set up optimization problem using JuMP
function setup_optim_problem(portfolio::Portfolio; prices::Dict=Dict(), 
                            timegrid::Timegrid=nothing,
                            costs_only::Bool=false, 
                            skip_nodes::Vector{String}=[], 
                            fix_time_window::Dict=nothing)
    if timegrid != nothing
        set_timegrid!(portfolio, timegrid)
    end
    if !haskey(portfolio, :timegrid)
        throw(ArgumentError("Set timegrid of portfolio before creating optim problem."))
    end

    model = Model()
    variables = Dict{String, VariableRef}()
    constraints = Dict{String, ConstraintRef}()
    objective = 0.0

    for a in portfolio.assets
        asset_model, asset_vars, asset_constraints, asset_obj = a.setup_optim_problem(prices=prices, timegrid=portfolio.timegrid, costs_only=costs_only)
        for (name, var) in asset_vars
            variables[name] = var
        end
        for (name, constr) in asset_constraints
            constraints[name] = constr
        end
        objective += asset_obj
    end

    if costs_only
        return objective
    end

    for (node_name, node) in portfolio.nodes
        if !(node_name in skip_nodes)
            for t in portfolio.timegrid.I
                @constraint(model, sum(variables["$(node_name)_$(t)_$(a.name)"] for a in portfolio.assets if haskey(variables, "$(node_name)_$(t)_$(a.name)")) == 0)
            end
        end
    end

    if fix_time_window != nothing
        if !haskey(fix_time_window, "I") || !haskey(fix_time_window, "x")
            throw(ArgumentError("fix_time_window must contain keys 'I' and 'x'"))
        end
        if isa(fix_time_window["I"], DateTime)
            fix_time_window["I"] = (portfolio.timegrid.timepoints .<= fix_time_window["I"])
        end
        if length(fix_time_window["x"]) >= length(variables)
            fix_time_window["x"] = fix_time_window["x"][1:length(variables)]
        end
        for (name, var) in variables
            if in(parse(Int, split(name, "_")[2]), portfolio.timegrid.I[fix_time_window["I"]])
                fix_value = fix_time_window["x"][parse(Int, split(name, "_")[2])]
                @constraint(model, var == fix_value)
            end
        end
    end

    @objective(model, Min, objective)
    return model
end
