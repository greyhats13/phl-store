# Path: fta_profile/app/adapters/middleware.py

import time, sys, contextvars, ujson, logging
from fastapi import Request, HTTPException, status, Response
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from opentelemetry import trace

http_request_context = contextvars.ContextVar("http_request_context", default=dict({}))
# cloud_trace_context = contextvars.ContextVar("cloud_trace_context", default="")
otel_trace_context = contextvars.ContextVar("otel_trace_id", default=dict({}))

def register_middleware(app):
    @app.middleware("http")
    async def loggingMiddleware(request: Request, call_next: RequestResponseEndpoint):
        request.state.start_time = time.perf_counter()
        if request.url.path == "/v1/healthcheck":
            try:
                return await call_next(request)
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail={
                        "msg": "healthcheck failed",
                        "reason": str(e),
                    },
                )
        # if "x-cloud-trace-context" in request.headers:
        #     log.debug(f"X-Cloud-Trace-Context: {request.headers.get('X-Cloud-Trace-Context')}")
        #     cloud_trace_context.set(request.headers.get("X-Cloud-Trace-Context"))
        span = trace.get_current_span()
        span_context = span.get_span_context()
        print(f"Before logging - Trace ID: {format(span_context.trace_id, '032x')}, Span ID: {format(span_context.span_id, '016x')}, Trace Sampled: {span_context.trace_flags}")
        otel_trace_context.set(
            {
                "trace_id": format(span_context.trace_id, "032x"),
                "span_id": format(span_context.span_id, "016x"),
                "trace_sampled": span_context.trace_flags,
            }
        )
        http_request = {
            "requestMethod": request.method,
            "requestUrl": str(request.url),
            "requestSize": sys.getsizeof(request),
            "protocol": request.url.scheme + "/" + request.scope.get("http_version"),
        }
        if request.client:
            http_request["remoteIp"] = request.client.host
        if "host" in request.headers:
            http_request["serverIp"] = request.headers.get("host")
        if "user-agent" in request.headers:
            http_request["userAgent"] = request.headers.get("user-agent")
        if "referrer" in request.headers:
            http_request["referrer"] = request.headers.get("referrer")
        ### Call the next middleware or route handler
        try:
            response = await call_next(request)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={
                    "msg": "Unhandled exception",
                    "reason": str(e),
                },
            )
        ### Calculate the request processing time
        process_time = (time.perf_counter() - request.state.start_time)
        http_request["latency"] = f"{process_time:.2f}s"
        http_request["status"] = response.status_code
        http_request["responseSize"] = int(response.headers.get("content-length", 0))
        http_request_context.set(http_request)
        if 200 <= response.status_code < 400:
            if app.state.settings.use_aiologger:
                await app.state.log.info("Success")
            app.state.log.info("Success")
        elif 400 <= response.status_code < 500:
            if app.state.settings.use_aiologger:
                await app.state.log.warning("Client Error")
            app.state.log.warning("Client Error")
        return response

    # Menambahkan middleware CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=app.state.settings.cors_allow_origins.split(","),
        allow_methods=app.state.settings.cors_allow_methods.split(","),
        allow_headers=app.state.settings.cors_allow_headers.split(","),
    )

    # Menambahkan middleware Trusted Hosts
    app.add_middleware(
        TrustedHostMiddleware, allowed_hosts=app.state.settings.trusted_hosts.split(",")
    )

    # Menambahkan middleware GZip
    app.add_middleware(GZipMiddleware, minimum_size=app.state.settings.gzip_min_length)


# # Path: fta_profile/app/adapters/middleware.py

# import time
# import contextvars
# import json
# from fastapi import Request, HTTPException
# from fastapi.logger import logger as log
# from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
# from fastapi.middleware.cors import CORSMiddleware
# from fastapi.middleware.trustedhost import TrustedHostMiddleware
# from fastapi.middleware.gzip import GZipMiddleware

# http_request_context = contextvars.ContextVar("http_request_context", default={})

# class LoggingMiddleware(BaseHTTPMiddleware):
#     async def dispatch(self, request: Request, call_next: RequestResponseEndpoint):
#         log.debug("test log")
#         start_time = time.perf_counter()

#         http_request = {
#             "requestMethod": request.method,
#             "requestUrl": str(request.url),
#             "protocol": f"{request.url.scheme}/{request.scope.get('http_version', '1.1')}",
#         }

#         if request.client:
#             http_request["remoteIp"] = request.client.host
#         if "host" in request.headers:
#             http_request["serverIp"] = request.headers["host"]
#         if "user-agent" in request.headers:
#             http_request["userAgent"] = request.headers["user-agent"]
#         if "referrer" in request.headers:
#             http_request["referrer"] = request.headers["referrer"]

#         try:
#             response = await call_next(request)
#         except Exception as e:
#             raise HTTPException(
#                 status_code=500,
#                 detail={
#                     "msg": "Unhandled exception",
#                     "reason": str(e),
#                 },
#             )

#         process_time = time.perf_counter() - start_time
#         http_request["latency"] = f"{process_time:.2f}s"
#         http_request["status"] = response.status_code
#         http_request["responseSize"] = int(response.headers.get("content-length", 0))

#         http_request_context.set(http_request)

#         if 200 <= response.status_code < 400:
#             log.info("Request processed")
#         elif 400 <= response.status_code < 500:
#             log.warning("client error")
#         elif 500 <= response.status_code:
#             log.error("server error")

#         return response

# def register_middleware(app):
#     app.add_middleware(LoggingMiddleware)
#     app.add_middleware(
#         CORSMiddleware,
#         allow_origins=app.state.settings.cors_allow_origins.split(","),
#         allow_methods=app.state.settings.cors_allow_methods.split(","),
#         allow_headers=app.state.settings.cors_allow_headers.split(","),
#         allow_credentials=app.state.settings.cors_allow_credentials,
#         max_age=app.state.settings.cors_max_age,
#     )
#     app.add_middleware(
#         TrustedHostMiddleware, allowed_hosts=app.state.settings.trusted_hosts.split(",")
#     )
#     app.add_middleware(
#         GZipMiddleware, minimum_size=app.state.settings.gzip_min_length
#     )