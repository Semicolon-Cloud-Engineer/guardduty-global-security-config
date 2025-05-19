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

If you're using Lark for team collaboration
1. Create a Lark App and Webhook URL:
Go to Lark Developer Console:

Lark Developer Console.

Create a New App:

Click Create App.

Fill in the details and select the Message Notification permission.

After creating the app, go to Features > Webhook and enable it.

Copy the Webhook URL (e.g., https://open.larksuite.com/open-apis/bot/v2/hook/xxxx-xxxx-xxxx).

✅ 2. Add the Webhook URL to GitHub Secrets:
Go to Settings > Secrets and variables > Actions.

Click New repository secret.

Name it LARK_WEBHOOK_URL.

Paste the Lark Webhook URL and Save.
Whenever there's error in your build you will be notified through lark
