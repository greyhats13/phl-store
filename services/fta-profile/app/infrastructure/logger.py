import logging, ujson
import google.cloud.logging
from fastapi.logger import logger
from google.cloud.logging_v2.handlers import CloudLoggingFilter
from ..adapter.middleware import http_request_context

# logger = logging.getLogger()
class GoogleCloudLogFilter(CloudLoggingFilter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.http_request = http_request_context.get()
        if hasattr(record, 'otelTraceID'):
            record.trace = f"projects/{self.project}/traces/{record.otelTraceID}"
            record.span_id = record.otelSpanID
            record.trace_sampled = record.otelTraceSampled
        else:
            record.trace = None
            record.span_id = None
            record.trace_sampled = None
        super().filter(record)
        return True

def get_log_level(log_level: str) -> int:
    match log_level:
        case "debug":
            return logging.DEBUG
        case "info":
            return logging.INFO
        case "warning":
            return logging.WARNING
        case "error":
            return logging.ERROR
        case "critical":
            return logging.CRITICAL
        case _:
            return logging.FATAL

class JsonFormatter(logging.Formatter):
    def format(self, record):
        if hasattr(record, 'otelTraceID'):
            print(f"otelTraceID: {record.otelTraceID}, otelSpanID: {record.otelSpanID}, otelTraceSampled: {record.otelTraceSampled}")
        else:
            print("otelTraceID not found in record")

        log_record = {
            "timestamp": self.formatTime(record, datefmt='%Y-%m-%dT%H:%M:%S.%fZ'),
            "severity": record.levelname,
            "message": record.getMessage(),
        }
        if hasattr(record, 'http_request'):
            log_record["httpRequest"] = record.http_request
        if hasattr(record, 'trace'):
            log_record["trace"] = record.trace
        if hasattr(record, 'span_id'):
            log_record["spanId"] = record.span_id
        if hasattr(record, 'trace_sampled'):
            log_record["traceSampled"] = record.trace_sampled
        return ujson.dumps(log_record)

class Logger:
    def __init__(self, app):
        # logging.getLogger("uvicorn.error").handlers = [logging.NullHandler()]
        logging.getLogger("uvicorn.access").handlers = [logging.NullHandler()]
        logging.getLogger("uvicorn").handlers = [logging.NullHandler()]
        logging.getLogger("asgi").handlers = [logging.NullHandler()]
        self.app = app
        self.logger = logger

    def getLogger(self):
        client = google.cloud.logging.Client()
        handler = client.get_default_handler()

        log_level = get_log_level(self.app.state.settings.app_log_level)
        handler.setLevel(logging.DEBUG)
        handler.filters = []
        handler.addFilter(GoogleCloudLogFilter(project=self.app.state.settings.firestore_project_id))

        # Set formatter pada handler
        formatter = JsonFormatter()
        handler.setFormatter(formatter)

        logger.handlers = []
        logger.addHandler(handler)

        logger.setLevel(logging.DEBUG)
        for h in logger.handlers:
            print(f"Handler: {h}, Level: {h.level}")