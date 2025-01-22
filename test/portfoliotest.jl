#######################################################
# Test for the Portfolio setup
# 
# Author: Luis van Sandbergen
# Date: 19.01.2025
#######################################################

using Dates

@testset "Portfolio Tests" begin

    # Test if the node is created correctly
    node_1 = EAO.Node("node_1")
    node_2 = EAO.Node("node_2")

    # Set up timegrid
    timegrid = EAO.Timegrid(DateTime(2024, 1, 1), DateTime(2024, 1, 2), "H", "H")

    # Set up contract
    a1 = EAO.Contract(name = "contract_1", 
                      nodes = node_1, 
                      start = DateTime(2024, 1, 1), 
                      finish = DateTime(2024, 1, 2))

    # Set up prices
    prices = {"rand_price" => ones(24)*1}

    # Set up portfolio
    portf = EAO.Portfolio(assets = [a1])

    # Set up optimization problem
    op_std = setup_optim_problem(portf, prices = prices, timegrid = timegrid)

    # Solve optimization problem
    res_std = optimize(op_std)

    @test res_std.value == 1.0

end