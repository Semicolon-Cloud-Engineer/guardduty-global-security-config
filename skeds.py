from flask import Flask, request, jsonify
from uuid import uuid4

app = Flask(__name__)
tasks = {}

@app.route("/tasks", methods=["POST"])
def add_task():
    data = request.get_json()
    if not data or "title" not in data:
        return jsonify({"error": "Task must include a title"}), 400
    task_id = str(uuid4())
    task = {"id": task_id, "title": data["title"]}
    tasks[task_id] = task
    return jsonify(task), 201

@app.route("/tasks", methods=["GET"])
def list_tasks():
    return jsonify(list(tasks.values())), 200

@app.route("/tasks/<task_id>", methods=["DELETE"])
def delete_task(task_id):
    if task_id not in tasks:
        return jsonify({"error": "Task not found"}), 404
    del tasks[task_id]
    return jsonify({"message": "Task deleted"}), 200

@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "healthy"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
