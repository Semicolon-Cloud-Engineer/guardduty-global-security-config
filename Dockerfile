# Dockerfile for the Flask To-Do API

# Use the official Python image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements file if you had one (here we install Flask manually)
RUN pip install flask

# Copy application code
COPY . .

# Expose the Flask app port
EXPOSE 5000

# Command to run the Flask app
CMD ["python", "todo_api.py"]
