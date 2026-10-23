import os, subprocess, sys, json, time, logging, re, socket
from google.oauth2 import service_account
from google.cloud import logging
from google.cloud.logging.handlers import CloudLoggingHandler
from dateutil.relativedelta import relativedelta
import traceback
import requests
import google.auth
import google.auth.transport.requests

logging_client = logging.Client()
# This log can be found in the Cloud Logging console under 'Custom Logs'.
logger = logging_client.logger('c48InfraLogs')
logging_labels = {'resource': 'AirFlow', 'service_status': 'Service_failed'}
base_url = """https://api_host/api/sendAlert?%40key=%api_key_id%&%40type=ALERT&%40version=alertapi-0.1&occurtime={0}&object={1}&text={2}&severity={3}"""

def check_service_status(service_name):
    max_attempts = 3
    attempt = 1

    while attempt <= max_attempts:
        result = subprocess.run(['systemctl', 'status', service_name], capture_output=True)
        output = result.stdout.decode()

        if "Active: active (running)" in output:
            print(f"The {service_name} is running.")
            return True

        attempt += 1
        time.sleep(60)  # Wait for 60 seconds before the next attempt

    print(f"The {service_name} is not running.")
    return False

def send_xmatters_alert(service_name):
    try:
        with open("/opt/airflow/service.log", "a+") as file:
            content = file.read()
            if service_name in content:
                print(f"XMatters alert already sent for {service_name}...")
            else:
                print(f"Sending XMatters alert for {service_name}...")
                object_name = service_name
                alert_description = "Service " + service_name + " is not running on "+ socket.gethostname()
                severity = 'MAJOR'
                xmatters_alert(alert_description, severity, object_name, job_run_id=0, job_id=0)
                file.write(f"{service_name}\n")
    except FileNotFoundError:
        print("File not found")
    except Exception as e:
        print(f"An error occured: {e}")

def check_airflow_services():
    services = ["airflow-api-webserver.service", "airflow-scheduler.service", "celery-worker.service", "cloud-sql-proxy.service", "nginx.service", "flower.service"]
    for service in services:
        if not check_service_status(service):
            send_xmatters_alert(service)

def xmatters_alert(alert_description, severity, object_name, **kwargs):
    try:
        epochtime = int(str(time.time() * 1000).split('.')[0])
        job_run_id = int(kwargs.get("job_run_id"))
        job_id = int(kwargs.get("job_id"))

        alert_description = str(alert_description).replace('\\', "").replace("\n", "").replace("\r", "")
        alert_description = re.sub("""[\\[\\]\\'\\>\\<?&%\\^~]""", "", str(alert_description).strip())
        alert_description = alert_description[0:1024]
        print(alert_description)

        object_name = str(object_name).replace('\\', "").replace("\n", "").replace("\r", "")
        object_name = re.sub("""[\\[\\]\\'\\>\\<?&%\\^~]""", "", str(object_name).strip())
        object_name = object_name[0:108]
        severity = str(severity).upper()
        logger.log_text(alert_description, severity="ERROR", labels=logging_labels)

        if job_run_id == 0 and job_id == 0:
            url = base_url.format(epochtime, object_name, alert_description, severity)
            response = requests.post(url, verify="/etc/pki/tls/certs/ca-bundle.trust.crt")
            response_code = response.status_code
            print("Response code is: ", response_code)
            response.raise_for_status()
            incident_id = response.text
            print("The incident_id is:", incident_id)
        else:
            url = base_url.format(epochtime, object_name, alert_description, severity)
            response = requests.post(url, verify="/etc/pki/tls/certs/ca-bundle.trust.crt")
            response_code = response.status_code
            print("Response code is ", response_code)
            response.raise_for_status()
            incident_id = response.text
            print("The incident_id is:", incident_id)
            cursor.close()
            connection.close()
    except Exception as e:
        print(e)
        if job_run_id == 0 and job_id == 0:
            logger.log_text(
                "**ERROR : Failed to send alert to xmatters api \n " +
                traceback.format_exc(), severity="ERROR", labels=logging_labels)
        else:
            logger.log_text(
                "**ERROR : Failed to send alert to xmatters api \n " +
                traceback.format_exc(), severity="ERROR", labels=logging_labels)

check_airflow_services()