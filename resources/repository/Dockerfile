# Use an official lightweight Python image.
# https://hub.docker.com/_/python
FROM python:3.9-alpine

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Create a simple Python script to serve "Hello, World!" on port 8000
RUN echo 'from http.server import SimpleHTTPRequestHandler, HTTPServer; \
HTTPServer(("", 8000), SimpleHTTPRequestHandler).serve_forever()' > server.py

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Run server.py when the container launches
CMD ["python", "server.py"]
