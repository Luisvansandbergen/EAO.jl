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
collects the assets and imposes the restriction of forcing the flows of a commodity
in each node to be zero in each time step.
"""
struct Portfolio
    assets::Array{AbstractAsset}
    asset_names::Array{String}
    node::Array{Node}
    timegrid::Timegrid
end

# Constructor for Portfolio
function Portfolio(assets::Vector{AbstractAsset})
    asset_names = [a.name for a in assets]
    nodes = Dict{String, Node}()
    for a in assets
        for n in a.nodes
            if !haskey(nodes, n.name)
                nodes[n.name] = n
            end
        end
    end
    if length(asset_names) != length(Set(asset_names))
        throw(ArgumentError("Asset names in portfolio must be unique"))
    end
    return Portfolio(assets, asset_names, nodes, Timegrid())
end

# Method to set the timegrid
function set_timegrid!(portfolio::Portfolio, timegrid::Timegrid)
    portfolio.timegrid = timegrid
end

# Method to set up optimization problem using JuMP
function setup_optim_problem(portfolio::Portfolio; prices::Dict=Dict(), timegrid::Timegrid=nothing, costs_only::Bool=false, skip_nodes::Vector{String}=[], fix_time_window::Dict=nothing)
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

# Method to create cost samples
function create_cost_samples(portfolio::Portfolio, price_samples::Vector{Dict}, timegrid::Timegrid=nothing)
    res = []
    for ps in price_samples
        push!(res, setup_optim_problem(portfolio, prices=ps, timegrid=timegrid, costs_only=true))
    end
    return res
end

# Method to get an asset by name
function get_asset(portfolio::Portfolio, asset_name::String)
    if asset_name in portfolio.asset_names
        idx = findfirst(isequal(asset_name), portfolio.asset_names)
        return portfolio.assets[idx]
    else
        return nothing
    end
end

# Method to get a node by name
function get_node(portfolio::Portfolio, node_name::String)
    if haskey(portfolio.nodes, node_name)
        return portfolio.nodes[node_name]
    else
        return nothing
    end
end