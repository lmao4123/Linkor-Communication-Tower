from flask import Flask, request, jsonify
import os

app = Flask(__name__)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

current_mode = "idle"

# ---------------- STATUS ----------------
@app.route("/status", methods=["GET"])
def status():
    return jsonify({
        "message": "PC is connected",
        "mode": current_mode
    })

# ---------------- MODE ----------------
@app.route("/mode", methods=["POST"])
def set_mode():
    global current_mode

    data = request.json
    current_mode = data.get("mode", "idle")

    print(f"\n🔥 MODE: {current_mode}")

    return jsonify({"status": "ok"})

# ---------------- UPLOAD ----------------
@app.route("/upload", methods=["POST"])
def upload():
    file = request.files["file"]

    path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(path)

    print(f"📁 RECEIVED: {file.filename}")

    return jsonify({"status": "saved"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)