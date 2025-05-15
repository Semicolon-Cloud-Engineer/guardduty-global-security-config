# config_change_detector.py

import os
import hashlib
import logging
from datetime import datetime
from pathlib import Path
import subprocess

# Configuration
WATCHED_FILES = ['.env', 'application.properties', 'pom.xml', 'config.js', 'config.json', 'config.yaml', 'settings.py', 'webpack.config.js', 'vite.config.js']
LOG_FILE = 'config_change.log'
HASH_FILE = '.file_hashes'

# Setup logging
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)


def calculate_hash(file_path):
    """Calculate the SHA256 hash of a file."""
    hasher = hashlib.sha256()
    try:
        with open(file_path, 'rb') as f:
            while chunk := f.read(8192):
                hasher.update(chunk)
        return hasher.hexdigest()
    except FileNotFoundError:
        return None


def load_previous_hashes():
    """Load the previous file hashes from the hash file."""
    if not os.path.exists(HASH_FILE):
        return {}
    with open(HASH_FILE, 'r') as f:
        return dict(line.strip().split(' ') for line in f)


def save_current_hashes(hashes):
    """Save the current file hashes to the hash file."""
    with open(HASH_FILE, 'w') as f:
        for file_path, file_hash in hashes.items():
            f.write(f"{file_path} {file_hash}\n")


def monitor_files():
    previous_hashes = load_previous_hashes()
    current_hashes = {}
    for file_path in WATCHED_FILES:
        file_hash = calculate_hash(file_path)
        current_hashes[file_path] = file_hash

        if file_path in previous_hashes:
            if previous_hashes[file_path] != file_hash:
                if file_hash:
                    logging.info(f"Modified: {file_path}")
                else:
                    logging.warning(f"Removed: {file_path}")
        elif file_hash:
            logging.info(f"Added: {file_path}")

    save_current_hashes(current_hashes)


def setup_git_hook():
    """Setup the pre-push git hook to run this script."""
    hook_path = Path('.git/hooks/pre-push')
    hook_path.parent.mkdir(parents=True, exist_ok=True)
    hook_content = f"#!/bin/bash\npython3 {Path(__file__).resolve()}"
    with open(hook_path, 'w') as hook_file:
        hook_file.write(hook_content)
    os.chmod(hook_path, 0o755)
    logging.info("Git pre-push hook has been set up.")


if __name__ == "__main__":
    monitor_files()
    setup_git_hook()
