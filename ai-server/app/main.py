from pathlib import Path

from fastapi import FastAPI

from app.generator import JuggernautGenerator
from app.models import GenerationRequest


app = FastAPI(
    title="WatcherTracker Local AI",
    version="0.1.0",
)


generator = JuggernautGenerator()

output_folder = Path(
    "/tmp/watchertracker-ai"
)


@app.get("/health")
def health():
    return {
        "status": "ok"
    }


@app.get("/info")
def info():
    return {
        "name": "WatcherTracker Local AI",
        "version": "0.1.0",
        "backend": "mps",
        "models": [
            "juggernaut-xl-v9"
        ],
        "model_loaded":
            generator.is_loaded,
        "busy": False,
    }


@app.post("/generate")
def generate(
    request: GenerationRequest
):
    return generator.generate(
        prompt=request.prompt,
        negative_prompt=
            request.negative_prompt,
        width=request.width,
        height=request.height,
        steps=request.steps,
        guidance_scale=
            request.guidance_scale,
        seed=request.seed,
        output_folder=output_folder,
    )


@app.post("/unload")
def unload():
    generator.unload()

    return {
        "status": "ok",
        "model_loaded":
            generator.is_loaded,
    }