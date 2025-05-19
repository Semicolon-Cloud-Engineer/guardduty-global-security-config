#!/usr/bin/env python3

import os
import time
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from dotenv import dotenv_values, load_dotenv

# Configuration
WATCHED_FILES = ['.env', '.env.local', '.env.development', '.env.production', '.env.staging',
                'application.properties', 'application-dev.properties', 'application-prod.properties', 'application.yml',
                'config.json', 'config.yaml', 'settings.py', 'config/application.rb', 'config/secrets.yml',
                'docker-compose.yml', 'k8s-config.yaml', 'terraform.tfvars', 'terraform.tfvars.json',
                '.github/workflows/*.yml', '.gitlab-ci.yml', 'Jenkinsfile']
LOG_FILE = 'config_change_log.txt'
CHECK_INTERVAL = 5  # in seconds

# Setup logging
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

class ConfigChangeHandler(FileSystemEventHandler):
    def __init__(self, watched_files):
        self.watched_files = watched_files
        self.prev_env = self.load_environment()

    def load_environment(self):
        env = {}
        for file_path in self.watched_files:
            if os.path.exists(file_path):
                if file_path.endswith('.env'):
                    env.update(dotenv_values(file_path))
                elif file_path.endswith('.properties'):
                    with open(file_path) as f:
                        for line in f:
                            if '=' in line:
                                key, value = line.strip().split('=', 1)
                                env[key] = value
        return env

    def detect_changes(self, new_env):
        changes = []
        for key, value in new_env.items():
            if key not in self.prev_env:
                changes.append(f'ADDED: {key}={value}')
            elif self.prev_env[key] != value:
                changes.append(f'MODIFIED: {key}={value} (was {self.prev_env[key]})')

        for key in self.prev_env.keys() - new_env.keys():
            changes.append(f'REMOVED: {key}')

        return changes

    def log_errors(self, changes):
        for change in changes:
            key = change.split(': ')[1].split('=')[0]
            value = os.getenv(key)
            if value is None:
                logging.error(f'ERROR: Missing environment variable: {key}')
            elif not value:
                logging.warning(f'WARNING: Empty environment variable: {key}')

    def on_modified(self, event):
        if event.src_path in self.watched_files:
            new_env = self.load_environment()
            changes = self.detect_changes(new_env)
            if changes:
                for change in changes:
                    logging.info(change)
                self.log_errors(changes)
            self.prev_env = new_env

if __name__ == '__main__':
    event_handler = ConfigChangeHandler(WATCHED_FILES)
    observer = Observer()
    for file_path in WATCHED_FILES:
        observer.schedule(event_handler, path=os.path.dirname(file_path) or '.', recursive=False)

    observer.start()
    try:
        while True:
            time.sleep(CHECK_INTERVAL)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
