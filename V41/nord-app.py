import os
import json
import uuid
from datetime import datetime, timezone

from flask import Flask, request, jsonify, send_file
from azure.storage.blob import BlobServiceClient, ContentSettings

app = Flask(__name__)

ACCOUNT_URL = "https://stnovatrixv388.blob.core.windows.net"
ACCOUNT_KEY = os.environ["ACCOUNT_KEY"]  # sätts som miljövariabel, aldrig i koden
CONTAINER_NAME = "arenden"

blob_service_client = BlobServiceClient(
    account_url=ACCOUNT_URL,
    credential=ACCOUNT_KEY
)

container_client = blob_service_client.get_container_client(CONTAINER_NAME)


@app.route('/')
def home():
    return send_file('index.html')


@app.route('/submit', methods=['POST'])
def submit():
    try:
        data = request.form.to_dict() if request.form else (request.get_json() or {})
        image = request.files.get("bild")

        now_str = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        short_id = str(uuid.uuid4())[:8]
        entry_id = f"{now_str}-{short_id}"

        image_url = ""
        image_name = ""

        if image and image.filename:
            image_name = f"{entry_id}_{image.filename}"

            image_blob = container_client.get_blob_client(image_name)

            image_blob.upload_blob(
                image.read(),
                overwrite=True
            )

            image_url = f"{ACCOUNT_URL}/{CONTAINER_NAME}/{image_name}"

        file_name = f"{entry_id}.json"

        payload = {
            "id": entry_id,
            "name": data.get("name", "Okänd"),
            "mail": data.get("mail") or data.get("email", ""),
            "message": data.get("msg", ""),
            "created": now_str,
            "image": image_url,
            "image_name": image_name
        }

        json_data = json.dumps(
            payload,
            ensure_ascii=False,
            indent=2
        ).encode("utf-8")

        blob_client = container_client.get_blob_client(file_name)

        blob_client.upload_blob(
            json_data,
            overwrite=True,
            blob_type="BlockBlob",
            content_settings=ContentSettings(
                content_type="application/json; charset=utf-8"
            )
        )

        return jsonify({
            "status": "success",
            "id": entry_id
        }), 200

    except Exception as e:
        print(f"Fel vid uppladdning: {e}")

        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
