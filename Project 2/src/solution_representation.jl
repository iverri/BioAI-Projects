module SolutionStructs

export Route, Solution

mutable struct Route
    patients::Vector{Int}
    total_demand::Int
    total_travel_time::Float64
end

mutable struct Solution
    routes::Vector{Route}
    total_travel_time::Float64
end

end