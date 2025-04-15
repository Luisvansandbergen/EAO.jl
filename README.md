[![Build Status](https://github.com/Luisvansandbergen/EAO.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Luisvansandbergen/EAO.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/Luisvansandbergen/EAO.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Luisvansandbergen/EAO.jl)

# Energy Asset Optimization (EAO) with Julia!

This Julia packages aims to translate the [EAO package](https://github.com/EnergyAssetOptimization/EAO) from Python to Julia, while trying to get rid of the matrices by implementing a modeling language (JuMP.jl) right under the hood. This should make the implementation of new assets or editing existing assets much simpler.

### Original description
The EAO package is a modular Python framework, designed to enable practitioners to use, build and optimize energy and commodity trading portfolios using linear or mixed integer programming as well as stochastic linear programming. It provides an implementation of
- standard assets such as contracts, transport and storages
- addition of new asset types
- their combination to complex portfolios using network structures
- (de-) serialization to JSON
- basic input & output functionality

We found that the approach is useful for modeling very different problem settings, such as decentral and renewable power generation, green power supply and PPAs and sector coupling in ad-hoc analysis, market modeling or daily operation.

You can find the documentation along with several sample notebooks here:
[`EAO documentation`](https://energyassetoptimization.github.io/EAO)

And an extensive technical report here:
[`Report`](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3842822)
