from flask import Flask, request, jsonify, send_from_directory
import os
import socket
import threading
import time

app = Flask(__name__)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# -------------------------
# BASIC SERVER API
# -------------------------

@app.route("/")
def home():
    return "Synco PC Server Running 🚀"

@app.route("/status")
def status():
    return jsonify({"message": "PC connected", "status": "ok"})

@app.route("/upload", methods=["POST"])
def upload():
    if "file" not in request.files:
        return jsonify({"error": "no file"}), 400

    file = request.files["file"]
    save_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(save_path)

    print("📁 Received:", file.filename)

    return jsonify({"status": "file received", "file": file.filename})

@app.route("/files")
def files():
    return jsonify(os.listdir(UPLOAD_FOLDER))

@app.route("/download/<filename>")
def download(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

# -------------------------
# WIFI AUTO DISCOVERY
# -------------------------

def broadcast_pc():
    """
    Sends PC presence to local network so Flutter can auto-detect it
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

    while True:
        try:
            message = b"SYNCO_PC_DISCOVERY"
            s.sendto(message, ("<broadcast>", 9999))
            time.sleep(2)  # broadcast every 2 seconds
        except:
            pass

# -------------------------
# START SERVER
# -------------------------

if __name__ == "__main__":
    print("🚀 Starting Synco PC Server...")

    # start WiFi discovery in background
    threading.Thread(target=broadcast_pc, daemon=True).start()

    # run flask server
    app.run(host="0.0.0.0", port=5000)