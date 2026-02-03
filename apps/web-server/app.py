from flask import Flask, jsonify
import logging
import random
import time
import os

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Request counter
request_count = 0

@app.route('/')
def home():
    global request_count
    request_count += 1
    logger.info(f"Home endpoint accessed. Total requests: {request_count}")
    return jsonify({
        "message": "Web Server for Datadog Monitoring",
        "request_count": request_count,
        "version": "1.0.0"
    })

@app.route('/health')
def health():
    logger.debug("Health check endpoint")
    return jsonify({"status": "healthy"}), 200

@app.route('/slow')
def slow():
    """Simulates a slow endpoint"""
    delay = random.uniform(1, 3)
    logger.warning(f"Slow endpoint called, sleeping for {delay:.2f}s")
    time.sleep(delay)
    return jsonify({"message": "slow response", "delay": delay})

@app.route('/error')
def error():
    """Simulates an error"""
    logger.error("Error endpoint called - simulating server error")
    return jsonify({"error": "Internal Server Error"}), 500

@app.route('/metrics')
def metrics():
    """Custom metrics endpoint"""
    return jsonify({
        "total_requests": request_count,
        "memory_usage_mb": random.randint(100, 500),
        "cpu_usage_percent": random.randint(10, 80)
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    logger.info(f"Starting Web Server on port {port}")
    app.run(host='0.0.0.0', port=port)
