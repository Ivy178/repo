"""Default celery configuration."""
from __future__ import annotations

import logging
import ssl

import re2
from kombu import Exchange, Queue

from airflow.configuration import conf

log = logging.getLogger(__name__)


def _broker_supports_visibility_timeout(url: str) -> bool:
    return url.startswith(("redis://", "rediss://", "sqs://", "sentinel://"))


def _is_amqps_broker(url: str) -> bool:
    return url.strip().lower().startswith("amqps://")


broker_url = conf.get("celery", "BROKER_URL", fallback="amqps://amqps:5671/rb_host")
default_queue_name = conf.get("operators", "DEFAULT_QUEUE")

task_default_queue_type = conf.get("celery", "task_default_queue_type", fallback="quorum")
task_create_missing_queue_type = conf.get(
    "celery", "task_create_missing_queue_type", fallback=task_default_queue_type
)
worker_detect_quorum_queues = conf.getboolean(
    "celery", "worker_detect_quorum_queues", fallback=True
)

broker_transport_options: dict = conf.getsection("celery_broker_transport_options") or {}
if "visibility_timeout" not in broker_transport_options and _broker_supports_visibility_timeout(broker_url):
    broker_transport_options["visibility_timeout"] = 21600
if task_default_queue_type == "quorum" or task_create_missing_queue_type == "quorum":
    broker_transport_options.setdefault("confirm_publish", True)

if conf.has_option("celery", "RESULT_BACKEND"):
    result_backend = conf.get_mandatory_value("celery", "RESULT_BACKEND")
else:
    result_backend = f'db+{conf.get("database", "SQL_ALCHEMY_CONN")}'

default_queue = Queue(
    default_queue_name,
    Exchange(default_queue_name, type="direct"),
    routing_key=default_queue_name,
    durable=True,
    queue_arguments={"x-queue-type": task_default_queue_type},
)

DEFAULT_CELERY_CONFIG = {
    "accept_content": ["json"],
    "event_serializer": "json",
    "worker_prefetch_multiplier": conf.getint("celery", "worker_prefetch_multiplier", fallback=1),
    "task_acks_late": True,
    "task_default_queue": default_queue_name,
    "task_default_exchange": default_queue_name,
    "task_default_routing_key": default_queue_name,
    "task_create_missing_queues": False,
    "task_queues": (default_queue,),
    "task_default_queue_type": task_default_queue_type,
    "task_create_missing_queue_type": task_create_missing_queue_type,
    "worker_detect_quorum_queues": worker_detect_quorum_queues,
    "task_track_started": conf.getboolean("celery", "task_track_started", fallback=True),
    "broker_url": broker_url,
    "broker_transport_options": broker_transport_options,
    "result_backend": result_backend,
    "database_engine_options": conf.getjson(
        "celery", "result_backend_sqlalchemy_engine_options", fallback={}
    ),
    "worker_concurrency": conf.getint("celery", "WORKER_CONCURRENCY", fallback=16),
    "worker_enable_remote_control": conf.getboolean("celery", "worker_enable_remote_control", fallback=True),
}

if _is_amqps_broker(broker_url):
    DEFAULT_CELERY_CONFIG["broker_use_ssl"] = {
        "keyfile": "/opt/airflow/cert/rabbitmq-node.key",
        "certfile": "/opt/airflow/cert/rabbitmq-node.crt",
        "ca_certs": "/etc/pki/tls/certs/ca-bundle.trust.crt",
        "cert_reqs": ssl.CERT_REQUIRED,
    }
    log.info("Enabled Celery broker SSL from amqps broker_url")

print("Celery Config:")
for key, value in DEFAULT_CELERY_CONFIG.items():
    print(f"  {key}: {value}")

match_not_recommended_backend = re2.search("redis?://|amqp://|rpc://", result_backend)
if match_not_recommended_backend:
    log.warning(
        "You have configured a result_backend using the protocol '%s', "
        "it is highly recommended to use an alternative result_backend (i.e. a database).",
        match_not_recommended_backend.group(0).strip("://"),
    )