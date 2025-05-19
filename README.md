to run the configuration management jobs:

Place these files in your project root:
config_change_monitor.py (the monitoring script)
start_config_monitor.sh (the launcher script)
to check the logs, run this command:
tail -f config_monitor.log
#To see the env changes and make the neccessary required adjustment

For Github Actions the file .github/workflows/config-monitor.yml will be committed and pushed to the repository.
and it would be activated once push is made to the matching branch.
Make a change in one of the monitored config files in a branch (e.g., add a variable to .env or application.yml) if there is any.
check for any changes and add any missing environment variable
