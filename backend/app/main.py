import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from .routers import auth, messages

app = FastAPI(
    title="Chat Me",
    description="FastAPI Backend for Messaging App",
    version="1.0.0"
)

# Configure CORS (allow all origins for local/web Flutter clients)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include auth and message routers
app.include_router(auth.router)
app.include_router(messages.router)

# Set up media static files directory
media_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "media"))
os.makedirs(media_dir, exist_ok=True)
app.mount("/media", StaticFiles(directory=media_dir), name="media")

@app.get("/")
def read_root():
    return {
        "message": "Welcome to the FastAPI Chat API! Visit /docs for the interactive API reference."
    }
