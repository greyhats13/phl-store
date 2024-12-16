# Path: fta_profile/main.py

from fastapi import FastAPI
from app.infrastructure.tracer import setup_tracer
from app.adapter.middleware import register_middleware
from app.adapter.error_handler import register_error_handlers
from app.adapter.transport.http.profile_router import profile_http_router
from app.infrastructure.lifespan import lifespan
from app.dependencies import get_settings

app = FastAPI(lifespan=lifespan)
app.state.settings = get_settings()

if app.state.settings.use_aiologger:
    from app.infrastructure.aiologger import Logger
else:
    from app.infrastructure.logger import Logger

app.state.log = Logger(app).logger

register_error_handlers(app)
register_middleware(app)
app.include_router(profile_http_router)
setup_tracer(app)

# # Run the app
# # For distroless images
# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run(app, host=app.state.settings.app_host, port=app.state.settings.app_port, log_level=app.state.settings.app_log_level)
    # uvicorn.run(app, host=settings.app_host, port=settings.app_port, log_level=settings.app_log_level,log_config=None, access_log=False)