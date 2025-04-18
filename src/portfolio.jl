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
end

# Constructor for Portfolio
function Portfolio(assets::Vector{AbstractAsset})
    asset_names = [a.name for a in assets]
    nodes_set = Set{Node}()
    for a in assets
        # Ensure a.nodes is always iterable
        nodes_iter = isa(a.nodes, Node) ? [a.nodes] : a.nodes
        for n in nodes_iter
            push!(nodes_set, n)
        end
    end
    if length(asset_names) != length(Set(asset_names))
        throw(ArgumentError("Asset names in portfolio must be unique"))
    end
    nodes = collect(nodes_set)
    return Portfolio(assets, asset_names, nodes)
end

"""
    setup_optim_problem(port::Portfolio, T, dt, prices)

Create a JuMP-model, that includes all asstes.
- portf: Portfolio object

returns: JuMP-Model
"""
function setup_optim_problem(
                portfolio::Portfolio,
                tg::Timegrid,
                price_dict::Dict{String,Vector{Float64}}, 
                solver
    )
    
    model = Model(solver)

    # Collector for dispatch variables and profit terms
    dispatch_registry = Dict{String,Vector{VariableRef}}()
    profit_terms      = GenericAffExpr{Float64,VariableRef}[]

    # 1) per‐asset variables & profit
    for a in portfolio.assets
        disp, profit = add_variables_to_model!(model, a, tg, price_dict)
        dispatch_registry[a.name] = disp
        push!(profit_terms, profit)
    end

    # 2) per‐asset constraints
    for a in portfolio.assets
        add_constraints_to_model!(model, a, dispatch_registry[a.name], tg, price_dict)
    end

    # 3) zero‐sum node balances
    add_node_balance_constraints!(model, dispatch_registry, portfolio.assets, tg)

    # Objective: maximize total profit
    @objective(model, Max, sum(profit_terms))
    
    return model
end

"""
    add_node_balance_constraints!(
        model,
        dispatch_registry,
        assets,
        tg::Timegrid
    )

For each node, collect all `dispatch[t]` vectors of the assets connected to that node
and impose ∀ t: sum(dispatch_i[t] for i∈assets_at_node) == 0.
"""
function add_node_balance_constraints!(
    model::Model,
    dispatch_registry::Dict{String,Vector{VariableRef}},
    assets::Vector{AbstractAsset},
    tg::Timegrid
)
    T = tg.T

    # 1) group each plant’s dispatch by node
    node_vars = Dict{Node, Vector{Vector{VariableRef}}}()
    for a in assets
        nodes = a.nodes isa Node ? (a.nodes,) : a.nodes
        disp  = dispatch_registry[a.name]
        for nd in nodes
            push!( get!(node_vars, nd, Vector{Vector{VariableRef}}()), disp)
        end
    end

    # 2) add, for each node, the zero‐sum balance constraint over time
    for (nd, disp_list) in node_vars
        @constraint(model, [t=1:T],
            sum(disp[t] for disp in disp_list) == 0
        )
    end

    return nothing
end