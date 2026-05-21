#######################################################
# Integration tests for Portfolio optimization
#
# Author: Luis van Sandbergen
# Date: 19.01.2025
#######################################################

using Test
using Dates
using JuMP
using EAO
import HiGHS
const MOI = JuMP.MOI

@testset "Portfolio Tests" begin

# ─────────────────────────────────────────────────────
# Test 1: SimpleContract pair — buy/sell arbitrage
# ─────────────────────────────────────────────────────
@testset "SimpleContract pair - price arbitrage" begin
    # Two SimpleContracts on the same node with different prices.
    # SC_buy: buys from "cheap" price. min_cap=0, max_cap=10 (positive dispatch = buying)
    # SC_sell: sells at "expensive" price. min_cap=-10, max_cap=0 (negative dispatch = selling)
    #
    # SC_buy profit = sum(-cheap[t] * buy_disp[t])   (cost when buying)
    # SC_sell profit = sum(-expensive[t] * sell_disp[t])  (revenue when selling: disp<0)
    # Node balance: buy_disp[t] + sell_disp[t] == 0  =>  sell_disp[t] = -buy_disp[t]
    #
    # Total profit = sum((expensive[t] - cheap[t]) * buy_disp[t])
    # With buy_disp in [0, 10], spread = 30: profit = 30*10*4 = 1200

    node = EAO.Node("N")
    sc_buy = EAO.SimpleContract(name="buy", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="cheap", min_cap=0.0, max_cap=10.0)
    sc_sell = EAO.SimpleContract(name="sell", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="expensive", min_cap=-10.0, max_cap=0.0)

    tg = EAO.Timegrid(start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3), freq="H")
    prices = Dict("cheap"     => [20.0, 20.0, 20.0, 20.0],
                  "expensive" => [50.0, 50.0, 50.0, 50.0])

    portf = EAO.Portfolio(EAO.AbstractAsset[sc_buy, sc_sell])
    model = EAO.setup_optim_problem(portf, tg, prices, HiGHS.Optimizer)
    JuMP.set_silent(model)
    JuMP.optimize!(model)

    @test termination_status(model) == MOI.OPTIMAL
    @test objective_value(model) ≈ 1200.0 atol=1e-6
end

# ─────────────────────────────────────────────────────
# Test 2: PowerPlant + SimpleContract
# ─────────────────────────────────────────────────────
@testset "PowerPlant + SimpleContract" begin
    # PP: min_cap=0, max_cap=5, fuel cost as negative price.
    #   PP profit = sum(fuel[t] * pp_disp[t])  (positive sign)
    # SC: min_cap=-10, max_cap=10, market price.
    #   SC profit = sum(-market[t] * sc_disp[t])
    #
    # Node balance: pp_disp[t] + sc_disp[t] = 0  =>  sc_disp = -pp_disp
    # Total = sum((fuel[t] + market[t]) * pp_disp[t])
    # fuel = [-30, -30, -30, -30], market = [50, 50, 50, 50]
    # Per period: (-30+50)*5 = 100. Total = 400.

    node = EAO.Node("N")
    pp = EAO.PowerPlant("PP", node, DateTime(2024,1,1), DateTime(2024,1,1,3),
                        "fuel", 0.0, 5.0)
    sc = EAO.SimpleContract(name="SC", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="market", min_cap=-10.0, max_cap=10.0)

    tg = EAO.Timegrid(start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3), freq="H")
    prices = Dict("fuel"   => [-30.0, -30.0, -30.0, -30.0],
                  "market" => [50.0, 50.0, 50.0, 50.0])

    portf = EAO.Portfolio(EAO.AbstractAsset[pp, sc])
    model = EAO.setup_optim_problem(portf, tg, prices, HiGHS.Optimizer)
    JuMP.set_silent(model)
    JuMP.optimize!(model)

    @test termination_status(model) == MOI.OPTIMAL
    @test objective_value(model) ≈ 400.0 atol=1e-6
end

# ─────────────────────────────────────────────────────
# Test 3: Storage arbitrage (perfect efficiency)
# ─────────────────────────────────────────────────────
@testset "Storage arbitrage (perfect efficiency)" begin
    # Storage + SC on same node. 4 hourly periods. Prices: [10, 50, 10, 50].
    # Storage: cap_in=cap_out=10, size=20, eff=1.0, start_level=0.
    # SC: min_cap=-20, max_cap=20, same price.
    #
    # Optimal: charge at 10 (low price), discharge at 10 (high price). Two cycles.
    # Storage profit = sum(price[t]*net_disp[t]) = 10*(-10)+50*(10)+10*(-10)+50*(10) = 800
    # SC profit = sum(-price[t]*sc_disp[t]) = sum(price[t]*net_disp[t]) = 800
    # Total = 1600

    node = EAO.Node("N")
    sto = EAO.Storage(name="STO", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="mkt", cap_in=10.0, cap_out=10.0,
        size=20.0, discharge_eff=1.0, charge_eff=1.0)
    sc = EAO.SimpleContract(name="SC", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="mkt", min_cap=-20.0, max_cap=20.0)

    tg = EAO.Timegrid(start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3), freq="H")
    prices = Dict("mkt" => [10.0, 50.0, 10.0, 50.0])

    portf = EAO.Portfolio(EAO.AbstractAsset[sto, sc])
    model = EAO.setup_optim_problem(portf, tg, prices, HiGHS.Optimizer)
    JuMP.set_silent(model)
    JuMP.optimize!(model)

    @test termination_status(model) == MOI.OPTIMAL
    @test objective_value(model) ≈ 1600.0 atol=1e-6
end

# ─────────────────────────────────────────────────────
# Test 4: Storage arbitrage with efficiency losses
# ─────────────────────────────────────────────────────
@testset "Storage arbitrage (with efficiency)" begin
    # Same setup but charge_eff=0.9, discharge_eff=0.9.
    #
    # t=1 (p=10): charge. disp_in=10, fill=0.9*10=9. net=-10.
    # t=2 (p=50): discharge. disp_out=9, fill=0. net=9*0.9=8.1.
    # t=3 (p=10): charge. disp_in=10, fill=9. net=-10.
    # t=4 (p=50): discharge. disp_out=9, fill=0. net=8.1.
    #
    # Storage profit = 10*(-10)+50*8.1+10*(-10)+50*8.1 = -100+405-100+405 = 610
    # SC profit = 610 (same derivation via node balance)
    # Total = 1220

    node = EAO.Node("N")
    sto = EAO.Storage(name="STO", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="mkt", cap_in=10.0, cap_out=10.0,
        size=20.0, discharge_eff=0.9, charge_eff=0.9)
    sc = EAO.SimpleContract(name="SC", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="mkt", min_cap=-20.0, max_cap=20.0)

    tg = EAO.Timegrid(start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3), freq="H")
    prices = Dict("mkt" => [10.0, 50.0, 10.0, 50.0])

    portf = EAO.Portfolio(EAO.AbstractAsset[sto, sc])
    model = EAO.setup_optim_problem(portf, tg, prices, HiGHS.Optimizer)
    JuMP.set_silent(model)
    JuMP.optimize!(model)

    @test termination_status(model) == MOI.OPTIMAL
    @test objective_value(model) ≈ 1220.0 atol=1e-6
end

# ─────────────────────────────────────────────────────
# Test 5: Contract with min_take constraint
# ─────────────────────────────────────────────────────
@testset "Contract with min_take" begin
    # Contract (buyer): price "buy"=[100,...], min_cap=0, max_cap=10.
    # SC (absorber/seller): price "sell"=[80,...], min_cap=-10, max_cap=0.
    #
    # Node: c_disp + sc_disp = 0 => sc_disp = -c_disp
    # Total = sum(-100*c_disp + 80*c_disp) = sum(-20*c_disp)
    # Without min_take: optimal c_disp = 0 (avoid losses). Profit = 0.
    # With min_take >= 30 MWh: must dispatch at least 30 total.
    # Profit = -20*30 = -600.

    node = EAO.Node("N")
    contract = EAO.Contract(
        name="C", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="buy", min_cap=0.0, max_cap=10.0,
        min_take=[(DateTime(2024,1,1), DateTime(2024,1,2), 30.0)])
    sc = EAO.SimpleContract(name="SC", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="sell", min_cap=-10.0, max_cap=0.0)

    tg = EAO.Timegrid(start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3), freq="H")
    prices = Dict("buy"  => [100.0, 100.0, 100.0, 100.0],
                  "sell" => [80.0, 80.0, 80.0, 80.0])

    portf = EAO.Portfolio(EAO.AbstractAsset[contract, sc])
    model = EAO.setup_optim_problem(portf, tg, prices, HiGHS.Optimizer)
    JuMP.set_silent(model)
    JuMP.optimize!(model)

    @test termination_status(model) == MOI.OPTIMAL
    @test objective_value(model) ≈ -600.0 atol=1e-6
end

# ─────────────────────────────────────────────────────
# Test 6: Contract with ramp constraint
# ─────────────────────────────────────────────────────
@testset "Contract with ramp constraint" begin
    # Contract (seller): min_cap=-10, max_cap=0, ramp=3 MW/h.
    # Prices: [100, 100, 100, -100]. Selling profitable at t=1,2,3, costly at t=4.
    # SC (absorber): min_cap=0, max_cap=10, zero price.
    #
    # Contract profit = sum(-price[t]*d[t]). SC profit = 0.
    # Without ramp: d=[−10,−10,−10,0], profit = 1000+1000+1000+0 = 3000.
    # With ramp=3 (limit per period = 3 MWh change):
    #   Optimal: stay at max dispatch for profitable periods, ramp toward 0 at t=4.
    #   d[1]=-10, d[2]=-10, d[3]=-10, d[4]=-7 (ramp from -10 by +3).
    #   Profit = -100*(-10) -100*(-10) -100*(-10) -(-100)*(-7)
    #          = 1000+1000+1000-700 = 2300.

    node = EAO.Node("N")
    contract = EAO.Contract(
        name="C", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="rev", min_cap=-10.0, max_cap=0.0,
        ramp=3.0)
    sc = EAO.SimpleContract(name="SC", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="zero", min_cap=0.0, max_cap=10.0)

    tg = EAO.Timegrid(start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3), freq="H")
    prices = Dict("rev"  => [100.0, 100.0, 100.0, -100.0],
                  "zero" => [0.0, 0.0, 0.0, 0.0])

    portf = EAO.Portfolio(EAO.AbstractAsset[contract, sc])
    model = EAO.setup_optim_problem(portf, tg, prices, HiGHS.Optimizer)
    JuMP.set_silent(model)
    JuMP.optimize!(model)

    @test termination_status(model) == MOI.OPTIMAL
    @test objective_value(model) ≈ 2300.0 atol=1e-6
end

# ─────────────────────────────────────────────────────
# Test 7: Storage with end level constraint
# ─────────────────────────────────────────────────────
@testset "Storage with end level constraint" begin
    # Flat price=50. Storage must end at fill=10 (start=0).
    # No arbitrage opportunity with flat prices. Must charge 10 MWh total.
    #
    # net_disp total = -10 (pure charging). Storage profit = 50*(-10) = -500.
    # SC profit = sum(-50*sc_disp) = sum(50*net_disp) = -500.
    # Total = -1000.

    node = EAO.Node("N")
    sto = EAO.Storage(name="STO", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="mkt", cap_in=10.0, cap_out=10.0,
        size=20.0, discharge_eff=1.0, charge_eff=1.0,
        start_level=0.0, end_level=10.0)
    sc = EAO.SimpleContract(name="SC", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="mkt", min_cap=-20.0, max_cap=20.0)

    tg = EAO.Timegrid(start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3), freq="H")
    prices = Dict("mkt" => [50.0, 50.0, 50.0, 50.0])

    portf = EAO.Portfolio(EAO.AbstractAsset[sto, sc])
    model = EAO.setup_optim_problem(portf, tg, prices, HiGHS.Optimizer)
    JuMP.set_silent(model)
    JuMP.optimize!(model)

    @test termination_status(model) == MOI.OPTIMAL
    @test objective_value(model) ≈ -1000.0 atol=1e-6
end

# ─────────────────────────────────────────────────────
# Test 8: 15-minute timegrid (validates dt_in_hours fix)
# ─────────────────────────────────────────────────────
@testset "15-minute timegrid dispatch bounds" begin
    # 4 x 15-min periods. SimpleContract: max_cap=4 MW.
    # dt = 0.25 h => dispatch bounds = [0, 4*0.25] = [0, 1] MWh per period.
    # Buy at 10, sell at 50. Spread = 40 per MWh.
    # Per period: 40*1 = 40. Total = 40*4 = 160.
    #
    # If dt was broken (dt=15 instead of 0.25), bounds would be [0, 60 MWh],
    # giving a wildly different result.

    node = EAO.Node("N")
    sc_buy = EAO.SimpleContract(name="buy", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,0,45),
        price="cheap", min_cap=0.0, max_cap=4.0)
    sc_sell = EAO.SimpleContract(name="sell", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,0,45),
        price="expensive", min_cap=-4.0, max_cap=0.0)

    tg = EAO.Timegrid(start=DateTime(2024,1,1), finish=DateTime(2024,1,1,0,45), freq="15min")
    @test tg.T == 4  # [0:00, 0:15, 0:30, 0:45]
    prices = Dict("cheap"     => [10.0, 10.0, 10.0, 10.0],
                  "expensive" => [50.0, 50.0, 50.0, 50.0])

    portf = EAO.Portfolio(EAO.AbstractAsset[sc_buy, sc_sell])
    model = EAO.setup_optim_problem(portf, tg, prices, HiGHS.Optimizer)
    JuMP.set_silent(model)
    JuMP.optimize!(model)

    @test termination_status(model) == MOI.OPTIMAL
    @test objective_value(model) ≈ 160.0 atol=1e-6
end

# ─────────────────────────────────────────────────────
# Test 9: run_optimization convenience function
# ─────────────────────────────────────────────────────
@testset "run_optimization convenience" begin
    node = EAO.Node("N")
    sc_buy = EAO.SimpleContract(name="buy", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="cheap", min_cap=0.0, max_cap=10.0)
    sc_sell = EAO.SimpleContract(name="sell", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="expensive", min_cap=-10.0, max_cap=0.0)

    tg = EAO.Timegrid(start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3), freq="H")
    prices = Dict("cheap" => [20.0, 20.0, 20.0, 20.0],
                  "expensive" => [50.0, 50.0, 50.0, 50.0])

    portf = EAO.Portfolio(EAO.AbstractAsset[sc_buy, sc_sell])
    results = EAO.run_optimization(portf, tg, prices, HiGHS.Optimizer)

    @test results.value ≈ 1200.0 atol=1e-6
    @test isa(results.x, Dict{String, Float64})
    @test length(results.x) > 0
end

# ─────────────────────────────────────────────────────
# Test 10: Portfolio constructor validation
# ─────────────────────────────────────────────────────
@testset "Portfolio unique asset names" begin
    node = EAO.Node("N")
    a1 = EAO.SimpleContract(name="dup", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="p", min_cap=0.0, max_cap=1.0)
    a2 = EAO.SimpleContract(name="dup", nodes=node,
        start=DateTime(2024,1,1), finish=DateTime(2024,1,1,3),
        price="p", min_cap=0.0, max_cap=1.0)
    @test_throws ArgumentError EAO.Portfolio(EAO.AbstractAsset[a1, a2])
end

end  # @testset "Portfolio Tests"
