using JSON

function load_problem_instance(file_path::String)
    open(file_path, "r") do file
        return JSON.parse(file)
    end
end

load_problem_instance("train/train_0.json")
