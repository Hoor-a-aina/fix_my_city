FixMyCity Backend

This folder contains the Flask backend used by the FixMyCity Flutter application.

The backend receives issue images from the mobile application, sends the image for AI analysis using Gemini, and returns the generated analysis to the Flutter application.

Technology
Python
Flask
Gemini API
Backend Responsibilities

The backend is responsible for:

Receiving an image from the Flutter application.
Processing the uploaded image.
Sending the image to Gemini for analysis.
Receiving the AI-generated response.
Returning the analysis to the Flutter application.
Requirements

Install Python 3 and make sure it is available from the terminal.

Install the required Python dependencies used by the backend.

For example:

pip install flask


Install any additional packages imported by api.py if they are not already installed.

Gemini API Key

The backend requires a Gemini API key to perform AI analysis.

Configure the API key according to the method used in api.py.

Do not commit a real API key to GitHub.

Running the Backend

Open a terminal in the backend directory:

cd backend


Start the Flask server:

python api.py


The development server will normally be available at:

http://127.0.0.1:5000


The backend is configured to listen on:

0.0.0.0


This allows a physical Android phone connected to the same local network to access the backend using the computer's local IP address.

For example:

http://192.168.1.6:5000


Your local IP address may be different.

Connecting the Flutter App

The Flutter application contains a backend URL similar to:

static const String _backendUrl = 'http://192.168.1.6:5000';


Replace the IP address with the IPv4 address of the computer running the Flask server.

Both the computer and Android phone should be connected to the same Wi-Fi network.

Testing the Connection

Start the backend first:

python api.py


Then start the Flutter application:

flutter run


In the application:

Report an Issue
↓
Gallery / Take Photo
↓
Select or capture image
↓
AI Analysis
↓
Analysis Result


If the backend is reachable and the Gemini API is configured correctly, the AI analysis result should be returned to the application.

Important Notes

The Flask server used during development is a development server and is intended for project testing and demonstration.

It should not be considered a production deployment.

For a production version, the backend could be deployed to a cloud service and the Flutter application could communicate with the deployed HTTPS endpoint.

Current Limitations

The current backend is intended for the FixMyCity project demonstration.

It does not currently provide:

Cloud report storage
User authentication
GPS-based location services
Municipal authority integration
Production-grade deployment
Real-time notifications

These features can be added in future versions.

Security

Never commit sensitive credentials such as:

Gemini API keys
Passwords
Access tokens
Private credentials

Use environment variables or another secure configuration method for production.

Future Improvements

Possible backend improvements include:

Cloud database integration
Authentication
Secure API key management
Production WSGI server
HTTPS
Cloud deployment
GPS/location services
Municipal authority APIs
Analytics and reporting