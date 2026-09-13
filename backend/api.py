from flask import Flask, jsonify, request
import os
import base64
import json
import mimetypes
from dotenv import load_dotenv
from google import genai


# ==========================================
# CONFIGURATION
# ==========================================

BASE_FOLDER = os.path.dirname(os.path.abspath(__file__))


# ==========================================
# LOAD GEMINI API KEY
# ==========================================

# Look for .env in the backend folder.
ENV_FILE = os.path.join(BASE_FOLDER, ".env")

load_dotenv(ENV_FILE)

api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    raise ValueError("GEMINI_API_KEY not found in backend/.env")

client = genai.Client(api_key=api_key)


# ==========================================
# FLASK APP
# ==========================================

app = Flask(__name__)


# ==========================================
# ANALYZE IMAGE WITH GEMINI
# ==========================================

def analyze_image(image_data, mime_type):

    # Convert image to Base64.
    image_base64 = base64.b64encode(
        image_data
    ).decode("utf-8")


    # AI prompt.
    prompt = """
Analyze this image for the FixMyCity civic issue reporting application.

Identify the main road or civic issue visible in the image.

Allowed categories:
- Pothole
- Garbage
- Broken streetlight
- Water leakage
- Road damage
- Other

Severity must be exactly one of:
- Low
- Medium
- High

Return ONLY valid JSON.

Do not use markdown.
Do not add any explanation outside the JSON.

Use exactly these fields:

{
    "category": "Pothole",
    "severity": "High",
    "description": "A large pothole is visible on the road.",
    "confidence": 0.98
}

Rules:
- category must be one of the allowed categories.
- severity must be Low, Medium, or High.
- description should briefly explain what is visible.
- confidence must be a number between 0 and 1.
"""


    # Send image to Gemini.
    response = client.models.generate_content(
        model="gemini-3.6-flash",
        contents=[
            prompt,
            {
                "inline_data": {
                    "mime_type": mime_type,
                    "data": image_base64
                }
            }
        ]
    )


    # Get Gemini response.
    result_text = response.text.strip()


    # Remove possible markdown code fences.
    if result_text.startswith("```"):

        result_text = result_text.replace(
            "```json",
            ""
        )

        result_text = result_text.replace(
            "```",
            ""
        )

        result_text = result_text.strip()


    # Convert Gemini response to JSON.
    result = json.loads(result_text)

    return result


# ==========================================
# ANALYZE API
# ==========================================

@app.route("/analyze", methods=["POST"])
def analyze():

    try:

        print()
        print("===================================")
        print("New analysis request received")
        print("===================================")


        # ==========================================
        # CHECK IMAGE
        # ==========================================

        if "image" not in request.files:

            return jsonify({
                "error": "No image was uploaded."
            }), 400


        uploaded_image = request.files["image"]


        if uploaded_image.filename == "":

            return jsonify({
                "error": "Image filename is empty."
            }), 400


        # ==========================================
        # READ IMAGE
        # ==========================================

        image_data = uploaded_image.read()


        if not image_data:

            return jsonify({
                "error": "Uploaded image is empty."
            }), 400


        # ==========================================
        # DETERMINE MIME TYPE
        # ==========================================

        filename = uploaded_image.filename.lower()

        if filename.endswith((".jpg", ".jpeg", ".jfif")):
             mime_type = "image/jpeg"

        elif filename.endswith(".png"):
            mime_type = "image/png"

        elif filename.endswith(".webp"):
            mime_type = "image/webp"

        else:
            mime_type = uploaded_image.mimetype or "image/jpeg"


        print("Image:")
        print(uploaded_image.filename)

        print("MIME type:")
        print(mime_type)



        # ==========================================


        # GET LOCATION
        # ==========================================

        location = request.form.get(
            "location",
            ""
        ).strip()


        print("Location:")
        print(location)


        # ==========================================
        # SEND IMAGE TO GEMINI
        # ==========================================

        print("Sending image to Gemini...")


        result = analyze_image(
            image_data,
            mime_type
        )


        print("Gemini analysis completed.")


        # ==========================================
        # ADD EXTRA INFORMATION
        # ==========================================

        result["location"] = location

        result["image"] = uploaded_image.filename


        # ==========================================
        # DISPLAY RESULT
        # ==========================================

        print("Result:")
        print(result)

        print("===================================")
        print()


        # ==========================================
        # RETURN RESULT TO FLUTTER
        # ==========================================

        return jsonify(result)


    except json.JSONDecodeError:

        print()
        print("ERROR:")
        print("Gemini did not return valid JSON.")
        print()


        return jsonify({
            "error": "Gemini returned invalid JSON."
        }), 500


    except Exception as e:

        print()
        print("ERROR:")
        print(str(e))
        print()


        return jsonify({
            "error": str(e)
        }), 500


# ==========================================
# START SERVER
# ==========================================

if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False
    )
