import json
import matplotlib.pyplot as plt


def plot_solution(case_no):
    with open(f"solutions/solution_{case_no}.json") as f:
        solution = json.load(f)

    with open(f"train/train_{case_no}.json") as f:
        case = json.load(f)

    depot = case["depot"]
    patients = case["patients"]

    plt.figure(figsize=(16, 8))

    plt.scatter(depot["x_coord"], depot["y_coord"], color="red", s=100, label="Depot")

    for i, patient in patients.items():
        plt.scatter(
            patient["x_coord"],
            patient["y_coord"],
            color="blue",
            s=100,
        )

    num_routes = len(solution["routes"])
    colormap = plt.colormaps["tab20"]

    for i, route in enumerate(solution["routes"]):
        x_coords = (
            [depot["x_coord"]]
            + [patients[str(patient_id)]["x_coord"] for patient_id in route]
            + [depot["x_coord"]]
        )
        y_coords = (
            [depot["y_coord"]]
            + [patients[str(patient_id)]["y_coord"] for patient_id in route]
            + [depot["y_coord"]]
        )
        plt.plot(
            x_coords, y_coords, color=colormap(i / num_routes), label=f"Nurse {i+1}"
        )

    plt.legend(loc="upper left", bbox_to_anchor=(1, 1))

    plt.show()


plot_solution(2)
