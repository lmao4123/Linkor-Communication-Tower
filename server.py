from flask import Flask, request, jsonify, send_from_directory
import os

app = Flask(__name__)

# 📁 Folder where files are saved
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# 🔗 Check server status
@app.route("/")
def home():
    return "Linkor server is running 🚀"

@app.route("/status", methods=["GET"])
def status():
    return jsonify({"status": "connected"})

# 📤 Upload file
@app.route("/upload", methods=["POST"])
def upload_file():
    if "file" not in request.files:
        return jsonify({"error": "No file sent"}), 400

    file = request.files["file"]
    file.save(os.path.join(UPLOAD_FOLDER, file.filename))

    print("📁 Received:", file.filename)

    return jsonify({
        "status": "file received",
        "filename": file.filename
    })

# 📄 List all uploaded files
@app.route("/files", methods=["GET"])
def list_files():
    files = os.listdir(UPLOAD_FOLDER)
    return jsonify(files)

# 📥 Download a specific file
@app.route("/download/<filename>")
def download_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

# 🚀 Run server
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)