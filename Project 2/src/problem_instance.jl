module ProblemInstance

using JSON

export load_problem_instance

function load_problem_instance(file_path::String)
    open(file_path, "r") do file
        return JSON.parse(file)
    end
end

end
