#######################################################
# Basic Types that the framework uses
# 
# Author: Luis van Sandbergen
# Date: 24.01.2024
#######################################################
"""
    Node

Struct to define a node in the optimization problem. A node is a (virtual) point, where
assets are located. In a node, the sum of all commodity flows must be zero.
Only one commodity may be present in each node. 
Per node we also define the units to be used for capacity (volume/energy and flow/capacity).
Examples are MWh and MW or liters and liters per minute.
"""
struct Node
    name::String
    commodity::Union{String, Nothing}  # Allow `commodity` to be `nothing`
end

# Constructor for Node with default value for commodity
Node(name::String) = Node(name, nothing)

"""
    Timegrid

Struct to manage the time grid used for the optimization, supporting arbitrary frequencies and easy iteration.
"""
struct Timegrid
    start::DateTime       # Start time of the grid
    finish::DateTime      # End time of the grid (inclusive)
    dt::Period            # Time step period (e.g., Minute(15), Hour(1))
    times::Vector{DateTime}  # Vector of all time points
    T::Int                # Number of time steps
end

"""
    Timegrid(; start::DateTime, finish::DateTime, freq::String)

Construct a Timegrid from `start` to `finish` with a frequency `freq`.

Supported `freq` strings:
- "15min" or "15m" → `Minute(15)`
- "H" or "1H" → `Hour(1)`
- "D" → `Day(1)`
- "M" → `Month(1)`
- "Y" → `Year(1)`
"""
function Timegrid(; start::DateTime, finish::DateTime, freq::String)
    # Map frequency string to a Dates.Period
    dt = lowercase(freq) in ("15min", "15m") ? Minute(15) :
         lowercase(freq) in ("h", "1h")    ? Hour(1)   :
         lowercase(freq) ==  "d"             ? Day(1)    :
         lowercase(freq) ==  "m"             ? Month(1)  :
         lowercase(freq) ==  "y"             ? Year(1)   :
         error("Invalid frequency '$(freq)'. Use one of: '15min', 'H', 'D', 'M', 'Y'.")

    # Generate the time vector (inclusive of finish if it aligns)
    times = collect(start:dt:finish)
    if last(times) < finish
        push!(times, finish)
    end

    T = length(times)
    return Timegrid(start, finish, dt, times, T)
end