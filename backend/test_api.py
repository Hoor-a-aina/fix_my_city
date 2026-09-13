import os
import requests


# ==========================================
# CONFIGURATION
# ==========================================

BASE_FOLDER = os.path.dirname(
    os.path.abspath(__file__)
)

url = "http://127.0.0.1:5000/analyze"


# ==========================================
# TEST IMAGE
# ==========================================

# This image is temporarily used only for testing.
# Change this path if you want to test another image.


image_path = r"C:\Users\Hoor Aina\OneDrive - SSUET\Desktop\FixMyCity_AI\FixMyCity_AI\TEST\Pothole_Big.jpg"


# ==========================================
# CHECK IMAGE
# ==========================================

if not os.path.exists(image_path):

    print("ERROR: Test image was not found.")

    print("Expected image:")
    print(image_path)

    input("Press Enter to exit...")
    exit()


# ==========================================
# SEND IMAGE TO API
# ==========================================

print()
print("===================================")
print("Testing FixMyCity API")
print("===================================")

print("Image:")
print(image_path)

print()

print("Sending image to Flask API...")


try:

    with open(image_path, "rb") as image:

        files = {
            "image": (
                os.path.basename(image_path),
                image,
                "image/jpeg"
            )
        }

        data = {
            "location": "North Nazimabad, Karachi, Pakistan"
        }

        response = requests.post(
            url,
            files=files,
            data=data,
            timeout=120
        )


except requests.exceptions.RequestException as e:

    print()
    print("ERROR: Could not connect to Flask API.")
    print(e)

    input("Press Enter to exit...")
    exit()


# ==========================================
# DISPLAY RESPONSE
# ==========================================

print()
print("Status:")
print(response.status_code)

print()

print("Response:")


try:

    print(response.json())

except ValueError:

    print(response.text)


print()
print("===================================")
