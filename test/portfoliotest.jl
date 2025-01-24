#######################################################
# Test for the Portfolio setup
# 
# Author: Luis van Sandbergen
# Date: 19.01.2025
#######################################################

using Test
using Dates

@testset "Portfolio Tests" begin

@testset "Node Tests" begin  
    # Test if the node is created correctly
    node_1 = EAO.Node("node_1")
    node_2 = EAO.Node("node_2")

    @test node_1.name == "node_1"
    @test node_2.name == "node_2"
end

@testset "Portfolio creation" begin

    # 1) create nodes
    nodeA = EAO.Node("NodeA", nothing)
    nodeB = EAO.Node("NodeB", "Power")

    # 2) create assets
    storage = EAO.Storage(
        name = "MyStorage", 
        nodes = nodeA,
        start = DateTime(2024, 1, 1),
        finish = DateTime(2024, 1, 2),
        price = "market_price",
        size = 20.0,
        cap_in = 10.0,
        cap_out = 8.0,
        η_discharge = 1.0,
        η_charge = 1.0,
    )

    contract = EAO.SimpleContract(
        name = "MyContract", 
        nodes = nodeA, 
        start = DateTime(2024, 1, 1), 
        finish = DateTime(2024, 1, 2),
        price = "market_price",
        min_cap = -5.0,
        max_cap = 10.0
    )

    # 3) create portfolio
    port = EAO.Portfolio([storage, contract], [nodeA, nodeB])

    # 4) define time steps
    T = 4
    dt = [1.0, 1.0, 1.0, 1.0]

    # 5) define prices
    prices = Dict(
        "market_price" => [50.0, 40.0, 60.0, 55.0]  # z.B. €/MWh
    )

    # 6) build JuMP model
    op = EAO.setup_optim_problem(port, T, dt, prices)

    # 7) solve
    optimize!(op)

    println("Solver status: ", termination_status(op))
    println("Objective Value: ", objective_value(op))

    # 8) read results
    dispatch_in  = sto.variables[:dispatch_in]
    dispatch_out = sto.variables[:dispatch_out]
    fill_level   = sto.variables[:fill_level]

    println("=== Ergebnisse Storage ===")
    for t in 1:T
        println(" t = $t : in = ", value(dispatch_in[t]),
                        ", out = ", value(dispatch_out[t]),
                        ", fill = ", value(fill_level[t]))
    end

    dispatch_contract = contract.variables[:dispatch]
    println("=== Ergebnisse Contract ===")
    for t in 1:T
        println(" t = $t : dispatch = ", value(dispatch_contract[t]))
    end

end

# @testset "SimpleContract Tests" begin
#     # Test if the node is created correctly
#     node_1 = EAO.Node("node_1")
#     node_2 = EAO.Node("node_2")

#     # Set up timegrid
#     timegrid = EAO.Timegrid(DateTime(2024, 1, 1), DateTime(2024, 1, 2), "H", "H")

#     # Set up contract
#     a1 = EAO.Contract(name = "contract_1", 
#                       nodes = node_1, 
#                       start = DateTime(2024, 1, 1), 
#                       finish = DateTime(2024, 1, 2),
#                       price = "rand_price",
#                       min_cap = 0.0,
#                       max_cap = 1.0
#                       )

#     # Set up prices
#     prices = Dict("rand_price" => ones(24)*1)

#     # Set up portfolio
#     portf = EAO.Portfolio(assets = [a1])

#     # Set up optimization problem
#     op_std = setup_optim_problem(portf, prices = prices, timegrid = timegrid)

#     # Solve optimization problem
#     res_std = optimize(op_std)

#     @test res_std.value == 1.0

# end

end