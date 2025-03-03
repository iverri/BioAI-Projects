function evaluate_travel_time(solution, travel_matrix)
    total_time = 0.0
    for route in solution.routes
        if !isempty(route.patients)
            total_time += travel_matrix[1, route.patients[1]] # time from depot to first patient
            for i in 1:length(route.patients)-1
                total_time += travel_matrix[route.patients[i], route.patients[i+1]] # time from patient i to patient i+1 along the route
            end
            total_time += travel_matrix[route.patients[end], 1] # time from last patient to depot
        end
    end
    return total_time
end