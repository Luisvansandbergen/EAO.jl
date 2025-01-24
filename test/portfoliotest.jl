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

@testset "Portfolio Tests" begin

    # 1) Erstelle Nodes
    nodeA = Node("NodeA", nothing)
    nodeB = Node("NodeB", "Power")

    # 2) Erstelle Assets
    sto = Storage(
        "MyStorage", 
        nodeA,
        20.0,   # size
        10.0,   # cap_in
        8.0,    # cap_out
        0.0,    # start_level
        5.0,    # end_level
        0.95,   # eff_in
        2.0,    # cost_in
        1.0,    # cost_out
        0.1,    # cost_store
        "market_price",   # price_key
        Dict{Symbol,Any}()
    )

    contract = SimpleContract(
        "MyContract",
        nodeB,
        -5.0,   # min_cap
        10.0,   # max_cap
        0.5,    # extra_costs
        "market_price",   # price_key
        Dict{Symbol,Any}()
    )

    # 3) Portfolio erstellen
    port = Portfolio([sto, contract], [nodeA, nodeB])

    # 4) Zeitschritte definieren
    T = 4
    dt = [1.0, 1.0, 1.0, 1.0]

    # 5) Preise definieren
    prices = Dict(
        "market_price" => [50.0, 40.0, 60.0, 55.0]  # z.B. €/MWh
    )

    # 6) JuMP-Modell aufbauen
    model = build_jump_model(port, T, dt, prices)

    # 7) Lösen
    optimize!(model)

    println("Solver status: ", termination_status(model))
    println("Objective Value: ", objective_value(model))

    # 8) Ergebnisse auslesen
    #   Wir können auf sto.variables[:dispatch_in] etc. zugreifen
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

@testset "Node Tests" begin

    # Test if the node is created correctly
    node_1 = EAO.Node("node_1")
    node_2 = EAO.Node("node_2")

    @test node_1.name == "node_1"
    @test node_2.name == "node_2"

end