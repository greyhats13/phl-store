# fta_profile/app/infrastructure/metrics.py

from opentelemetry.metrics import set_meter_provider
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

def setup_metrics(app):
    resource = Resource(attributes={"service.name": app.state.settings.app_name})
    metric_exporter = OTLPMetricExporter(
        endpoint=app.state.settings.otel_exporter_otlp_endpoint,
        insecure=app.state.settings.otel_exporter_otlp_insecure,
        headers=app.state.settings.otel_exporter_otlp_headers
    )

    metric_reader = PeriodicExportingMetricReader(metric_exporter)
    meter_provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
    set_meter_provider(meter_provider)

    # Instrument FastAPI to collect default metrics
    FastAPIInstrumentor.instrument_app(app)