# Path: fta_profile/app/adapters/error.py

import time
from fastapi import HTTPException, Request, status
from fastapi.responses import Response, JSONResponse
from .middleware import http_request_context

# Define a mapping of status codes to JSON responses
response_map = {
    status.HTTP_400_BAD_REQUEST: lambda detail: JSONResponse(status_code=status.HTTP_400_BAD_REQUEST, content={"detail": detail}),
    status.HTTP_401_UNAUTHORIZED: lambda detail: JSONResponse(status_code=status.HTTP_401_UNAUTHORIZED, content={"detail": detail}),
    status.HTTP_403_FORBIDDEN: lambda detail: JSONResponse(status_code=status.HTTP_403_FORBIDDEN, content={"detail": detail}),
    status.HTTP_404_NOT_FOUND: lambda detail: JSONResponse(status_code=status.HTTP_404_NOT_FOUND, content={"detail": detail}),
    status.HTTP_405_METHOD_NOT_ALLOWED: lambda detail: JSONResponse(status_code=status.HTTP_405_METHOD_NOT_ALLOWED, content={"detail": detail}),
    status.HTTP_406_NOT_ACCEPTABLE: lambda detail: JSONResponse(status_code=status.HTTP_406_NOT_ACCEPTABLE, content={"detail": detail}),
    status.HTTP_409_CONFLICT: lambda detail: JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"detail": detail}),
    status.HTTP_422_UNPROCESSABLE_ENTITY: lambda detail: JSONResponse(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, content={"detail": detail}),
    status.HTTP_429_TOO_MANY_REQUESTS: lambda detail: JSONResponse(status_code=status.HTTP_429_TOO_MANY_REQUESTS, content={"detail": detail}),
    status.HTTP_501_NOT_IMPLEMENTED: lambda detail: JSONResponse(status_code=status.HTTP_501_NOT_IMPLEMENTED, content={"detail": detail}),
    status.HTTP_502_BAD_GATEWAY: lambda detail: JSONResponse(status_code=status.HTTP_502_BAD_GATEWAY, content={"detail": detail}),
    status.HTTP_503_SERVICE_UNAVAILABLE: lambda detail: JSONResponse(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, content={"detail": detail}),
    status.HTTP_504_GATEWAY_TIMEOUT: lambda detail: JSONResponse(status_code=status.HTTP_504_GATEWAY_TIMEOUT, content={"detail": detail}),
}

async def http_exception_handler(request: Request, exc: HTTPException)-> Response:
    # Handle known HTTP status codes
    if exc.status_code in response_map:
        return response_map[exc.status_code](exc.detail)
    # Handle 500 Internal Server Error
    if exc.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR:
        http_request = {
            "requestMethod": request.method,
            "requestUrl": str(request.url),
            "responseSize": 21,
            "status": exc.status_code,
            "protocol": request.url.scheme+"/"+request.scope.get("http_version"),
            "error": exc.detail,
        }
        if request.client:
            http_request["remoteIp"] = request.client.host
        if "host" in request.headers:
            http_request["serverIp"] = request.headers.get("host")
        if "user-agent" in request.headers:
            http_request["userAgent"] = request.headers.get("user-agent")
        if "referrer" in request.headers:
            http_request["referrer"] = request.headers.get("referrer")
        process_time = (time.time() - request.state.start_time) * 1000
        http_request["latency"] = f"{process_time:.2f}ms"
        http_request_context.set(http_request)
        if request.app.state.settings.use_aiologger:
            await request.app.state.log.error("Internal Server Error", exc_info=True)
        else:
            request.app.state.log.error("Internal Server Error", exc_info=True)
        return Response(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, content=("Internal Server Error"))

async def server_error_exception_handler(request: Request, exc: Exception)-> Response:
    process_time = (time.time() - request.state.start_time) * 1000
    http_request = {
        "requestMethod": request.method,
        "requestUrl": str(request.url),
        "responseSize": 21,
        "userAgent": request.headers.get("user-agent"),
        "remoteIp": request.client.host if request.client else None,
        "serverIp": request.headers.get("host"),
        "status": 500,
        "referer": request.headers.get("referer"),
        "latency": f"{process_time:.2f}ms",
        "protocol": request.url.scheme+"/"+request.scope.get("http_version"),
        "error": str(exc),
    }
    http_request_context.set(http_request)
    if request.app.state.settings.use_aiologger:
        await request.app.state.log.critical("Internal Server Error", exc_info=True)
    else:
        request.app.state.log.critical("Internal Server Error", exc_info=True)
    return Response(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content="Internal Server Error",
    )

# Register all exception handlers
def register_error_handlers(app):
    app.add_exception_handler(HTTPException, http_exception_handler)
    app.add_exception_handler(Exception, server_error_exception_handler)
    return app