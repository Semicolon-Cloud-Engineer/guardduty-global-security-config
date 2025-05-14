# Detect and Assess the Issue: detect and assess the issue by using monitoring tools like prometrheus and grafana, I determine the severity, affected components, and potential business impact like security and data losses
# Isolate and Contain the Issue: make use of notifications and alert to notify the stakeholders and initaite response procedures, disable impact services, reroute traffic or scale down to avoid further inpact. the take a snapshot of the state and logs for root cause analysis
# Identify Root Cause and Apply Immediate Fixes: analyze the logs to pinpoint the root cause, then implement quick fixesto stabilize environment, and update the status to the stakeholder.
# Implement Permanent Solutions and Validate: Proceed to implement permanent fixes as neccessary, then Test these solutions to validate that the soluton does not introduce new problems. then I will monitor very closely to detect quickly reoccurences or side effect if there's any.
# Post-Mortem Analysis and Documentation: Using the RCA(Root Cause Analysis), Analyse the root cause, contributing factors, and preventive measures, then I will document my findings by creating incident report, update runbooks, and document lessons learnt.
# Finally Update monitoring, alerts, and failover mechanisms to prevent similar incidents.
#!/bin/bash

# Refined Infrastructure Issue Handler Script with Enhanced Logging and Testing
# Handles detection, isolation, analysis, resolution, and documentation of infrastructure issues

LOG_FILE="infra_issue_handler.log"
TEMP_DIR="/tmp/issue_analysis"
NOTIFY_EMAIL=""
PROMETHEUS_URL=""
SLACK_WEBHOOK=""
AWS_S3_BUCKET=""
GITHUB_REPO=""

# Ensure necessary directories
mkdir -p $TEMP_DIR

# Parameterize input values
if [ -z "$1" ]; then
  read -p "Enter notification email: " NOTIFY_EMAIL
else
  NOTIFY_EMAIL=$1
fi

if [ -z "$2" ]; then
  read -p "Enter Prometheus URL: " PROMETHEUS_URL
else
  PROMETHEUS_URL=$2
fi

if [ -z "$3" ]; then
  read -p "Enter Slack Webhook URL: " SLACK_WEBHOOK
else
  SLACK_WEBHOOK=$3
fi

if [ -z "$4" ]; then
  read -p "Enter AWS S3 Bucket for storage: " AWS_S3_BUCKET
else
  AWS_S3_BUCKET=$4
fi

if [ -z "$5" ]; then
  read -p "Enter GitHub Repository URL: " GITHUB_REPO
else
  GITHUB_REPO=$5
fi

# Logging function
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Enhanced Testing Function
test_component() {
  COMPONENT=$1
  COMMAND=$2

  log_message "Testing $COMPONENT..."
  if eval "$COMMAND"; then
    log_message "$COMPONENT is operational."
  else
    log_message "ERROR: $COMPONENT failed to respond."
  fi
}

# Test Prometheus connectivity
test_component "Prometheus" "curl -s $PROMETHEUS_URL >/dev/null"

# Test Slack Webhook
test_component "Slack Webhook" "curl -s -X POST -H 'Content-type: application/json' --data '{"text": "Testing Slack Webhook"}' $SLACK_WEBHOOK >/dev/null"

# Test S3 connectivity
test_component "AWS S3 Bucket" "aws s3 ls s3://$AWS_S3_BUCKET >/dev/null"

# 1. Detect and Assess the Issue
detect_issue() {
  log_message "Starting issue detection via Prometheus..."
  CPU_USAGE=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=100-(avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))*100)" | jq -r '.data.result[0].value[1]')

  if (( $(echo "$CPU_USAGE > 80.0" | bc -l) )); then
    log_message "High CPU usage detected: $CPU_USAGE%"
    echo "High CPU usage detected: $CPU_USAGE%" > "$TEMP_DIR/issue_report.txt"
    isolate_issue
  else
    log_message "No critical issues detected."
  fi
}

# 2. Isolate and Contain the Issue
isolate_issue() {
  log_message "Isolating issue and collecting logs..."
  ps aux > "$TEMP_DIR/process_snapshot.txt"
  dmesg > "$TEMP_DIR/system_logs.txt"
  journalctl -xe > "$TEMP_DIR/journal_logs.txt"

  # Notify via Slack
  if [ -n "$SLACK_WEBHOOK" ]; then
    curl -X POST -H 'Content-type: application/json' --data '{"text": "Issue detected and isolated. Logs collected."}' "$SLACK_WEBHOOK"
  fi

  TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
  ARCHIVE="issue_logs_$TIMESTAMP.tar.gz"
  tar -czf "$ARCHIVE" -C "$TEMP_DIR" .

  # Upload logs to S3
  if [ -n "$AWS_S3_BUCKET" ]; then
    aws s3 cp "$ARCHIVE" "s3://$AWS_S3_BUCKET/$ARCHIVE"
    log_message "Logs uploaded to S3: $AWS_S3_BUCKET/$ARCHIVE"
  fi

  analyze_issue
}

# 3. Identify Root Cause and Apply Immediate Fixes
analyze_issue() {
  log_message "Analyzing logs and identifying root cause..."
  ERROR_COUNT=$(grep -i "error" "$TEMP_DIR/system_logs.txt" | wc -l)
  log_message "Found $ERROR_COUNT error(s) in system logs."

  # Example fix: Restart a service
  log_message "Applying temporary fix: Restarting example service"
  # systemctl restart example.service

  validate_resolution
}

# 4. Implement Permanent Solutions and Validate
validate_resolution() {
  log_message "Validating resolution..."
  CPU_USAGE=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=100-(avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))*100)" | jq -r '.data.result[0].value[1]')

  if (( $(echo "$CPU_USAGE < 80.0" | bc -l) )); then
    log_message "Issue resolved."
    document_issue
  else
    log_message "Issue persists. Further investigation required."
  fi
}

# 5. Post-Mortem Analysis and Documentation
document_issue() {
  log_message "Documenting the incident..."
  TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
  ISSUE_REPORT="issue_report_$TIMESTAMP.txt"

  echo "Issue detected at $TIMESTAMP" > "$ISSUE_REPORT"
  echo "Logs archived to S3: $AWS_S3_BUCKET/$ARCHIVE" >> "$ISSUE_REPORT"

  # Push report to GitHub
  if [ -n "$GITHUB_REPO" ]; then
    cd "$TEMP_DIR"
    git init
    git remote add origin "$GITHUB_REPO"
    git add .
    git commit -m "Incident report $TIMESTAMP"
    git push -u origin main
    log_message "Incident report pushed to GitHub: $GITHUB_REPO"
  fi

  # Notify via email
  if [ -n "$NOTIFY_EMAIL" ]; then
    echo "Incident report generated: $ISSUE_REPORT" | mail -s "Incident Report" "$NOTIFY_EMAIL"
  fi
}

# Start detection
log_message "Starting infrastructure monitoring and issue handling..."
detect_issue
