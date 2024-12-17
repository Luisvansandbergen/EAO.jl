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
end

