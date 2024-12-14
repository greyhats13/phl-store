from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace.sampling import TraceIdRatioBased
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.logging import LoggingInstrumentor

def setup_tracer(app):
    resource = Resource(
        attributes={
            "service.name": app.state.settings.app_name,
        }
    )

    # Set sampling rate from config
    sampling_rate = app.state.settings.otel_sampling_rate
    sampler = TraceIdRatioBased(sampling_rate)

    tracer_provider = TracerProvider(resource=resource, sampler=sampler)
    # tracer_provider = TracerProvider(resource=resource)
    trace.set_tracer_provider(tracer_provider)

    # Configure OTLP exporter
    otlp_exporter = OTLPSpanExporter(
        endpoint=app.state.settings.otel_exporter_otlp_endpoint,
        insecure=app.state.settings.otel_exporter_otlp_insecure,
    )
    span_processor = BatchSpanProcessor(otlp_exporter)
    tracer_provider.add_span_processor(span_processor)

    # Instrument logging to include trace context
    LoggingInstrumentor().instrument(set_logging_format=False)

    # Instrument FastAPI app, exclude /v1/healthcheck
    FastAPIInstrumentor().instrument_app(app, excluded_urls="/v1/healthcheck")