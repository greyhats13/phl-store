# Path: fta_profile/app/infrastructure/logger.py

import sys, logging, ujson
from datetime import datetime
from aiologger import Logger as AsyncLogger
from aiologger.handlers.streams import AsyncStreamHandler
from aiologger.formatters.base import Formatter
from ..adapter.middleware import http_request_context


class JSONFormatter(Formatter):
    def __init__(self, project_id):
        self.project_id = project_id

    def format(self, record):
        log_record = {
            "timestamp": datetime.now().isoformat()().isoformat() + "Z",
            "severity": record.levelname,
            "http_request": http_request_context.get(),
        }
        print(
            f"otelTraceID: {record.otelTraceID}, otelSpanID: {record.otelSpanID}s, otelTraceSampled: {record.otelTraceSampled}"
        )
        log_record["trace"] = (
            f"projects/{self.project_id}/traces/{record.otelTraceID}" if record.OtelTraceID else None
        )
        log_record["span_id"] = record.otelSpanID if record.otelSpanID else None
        log_record["trace_sampled"] = record.otelTraceSampled if record.otelTraceSampled else None
        if hasattr(record, "msg"):
            log_record["msg"] = record.msg
        print(f"record:{record} ")
        return ujson.dumps(log_record)


class Logger:
    def __init__(self, app):
        # logging.getLogger("uvicorn.error").handlers = [logging.NullHandler()]
        # logging.getLogger("uvicorn.access").handlers = [logging.NullHandler()]
        # logging.getLogger("uvicorn").handlers = [logging.NullHandler()]
        # logging.getLogger("asgi").handlers = [logging.NullHandler()]
        self.logger = AsyncLogger.with_default_handlers(
            name=app.state.settings.app_name
        )
        self.app = app
        self._setup_handlers()

    def _setup_handlers(self):
        # Hapus handler default jika ada
        if self.logger.handlers:
            self.logger.remove_handler(self.logger.handlers[0])
        # Tambahkan AsyncStreamHandler dengan JSONFormatter
        stream_handler = AsyncStreamHandler(
            stream=sys.stdout,
            formatter=JSONFormatter(self.app.state.settings.firestore_project_id),
        )
        self.logger.add_handler(stream_handler)
        # Disable log propagation
        self.logger.propagate = False

    async def shutdown(self):
        await self.logger.shutdown()