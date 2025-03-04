module SaveSolution

export save_solution

using ..SolutionStructs

using JSON

function save_solution(solution::SolutionStructs.Solution, instance_no::Int)
    data = Dict(
        "routes" => [route.patients for route in solution.routes],
        "total_travel_time" => solution.total_travel_time
    )
    open("solutions/solution_$instance_no.json", "w") do f
        JSON.print(f, data)
    end
end

end