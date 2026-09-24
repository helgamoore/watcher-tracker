from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from threading import Lock, Thread
from urllib.parse import quote
from uuid import UUID

import os

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.generator import JuggernautGenerator
from app.models import GenerationRequest


log_file = Path(os.environ["LOG_FILE"])

SERVER_VERSION = "0.3.0"
OUTPUT_MAX_AGE = timedelta(days=1)

output_folder = Path(
    "/tmp/watchertracker-ai"
)

output_folder.mkdir(
    parents=True,
    exist_ok=True,
)


def generated_file_path(filename: str) -> Path:
    if Path(filename).name != filename:
        raise HTTPException(
            status_code=400,
            detail="Invalid filename.",
        )

    if not filename.lower().endswith(".png"):
        raise HTTPException(
            status_code=400,
            detail="Only PNG files can be deleted.",
        )

    return output_folder / filename


def cleanup_generated_files(folder: Path) -> int:
    cutoff = datetime.now(timezone.utc) - OUTPUT_MAX_AGE
    deleted = 0

    for file in folder.iterdir():
        if not file.is_file():
            continue

        modified_at = datetime.fromtimestamp(
            file.stat().st_mtime,
            tz=timezone.utc,
        )

        if modified_at < cutoff:
            file.unlink()
            deleted += 1

    return deleted


@asynccontextmanager
async def lifespan(app: FastAPI):
    deleted = cleanup_generated_files(output_folder)

    if deleted:
        print(
            f"Deleted {deleted} generated file(s) older than "
            f"{OUTPUT_MAX_AGE}."
        )

    yield


app = FastAPI(
    title="WatcherTracker Local AI",
    version=SERVER_VERSION,
    lifespan=lifespan,
)


generator = JuggernautGenerator()
generation_lock = Lock()

jobs_lock = Lock()
jobs: dict[str, dict] = {}
active_job_id: str | None = None


app.mount(
    "/images",
    StaticFiles(directory=output_folder),
    name="images",
)


def generation_request_snapshot(
    request: GenerationRequest,
) -> dict:
    return {
        "prompt": request.prompt,
        "negative_prompt": request.negative_prompt,
        "width": request.width,
        "height": request.height,
        "steps": request.steps,
        "guidance_scale": request.guidance_scale,
        "seed": request.seed,
    }


def generation_result_response(
    result: dict,
) -> dict:
    image_path = Path(
        result["image_path"]
    )

    return {
        "filename": result["filename"],
        "image_url": f"/images/{quote(image_path.name)}",
        "seed": result["seed"],
        "generation_seconds": result["generation_seconds"],
        "width": result["width"],
        "height": result["height"],
    }


def job_response(job_id: str) -> dict:
    with jobs_lock:
        job = jobs.get(job_id)

        if job is None:
            raise HTTPException(
                status_code=404,
                detail="Generation job not found.",
            )

        snapshot = dict(job)
        is_active = (
            active_job_id == job_id
            and snapshot["status"] == "running"
        )

    progress_percent = snapshot.get(
        "progress_percent"
    )
    current_step = snapshot.get(
        "current_step"
    )
    total_steps = snapshot.get(
        "total_steps"
    )

    if is_active:
        progress_percent = generator.progress_percent
        current_step = generator.current_step
        total_steps = generator.total_steps

    return {
        "job_id": job_id,
        "status": snapshot["status"],
        "created_at": snapshot["created_at"].isoformat(),
        "completed_at": (
            snapshot["completed_at"].isoformat()
            if snapshot.get("completed_at")
            else None
        ),
        "request": snapshot["request"],
        "progress_percent": progress_percent,
        "current_step": current_step,
        "total_steps": total_steps,
        "result": snapshot.get("result"),
        "error": snapshot.get("error"),
    }


def run_generation_job(
    job_id: str,
    request: GenerationRequest,
) -> None:
    global active_job_id

    try:
        result = generator.generate(
            prompt=request.prompt,
            negative_prompt=request.negative_prompt,
            width=request.width,
            height=request.height,
            steps=request.steps,
            guidance_scale=request.guidance_scale,
            seed=request.seed,
            output_folder=output_folder,
        )

        response = generation_result_response(
            result
        )

        with jobs_lock:
            job = jobs[job_id]

            job["status"] = "completed"
            job["completed_at"] = datetime.now(
                timezone.utc
            )
            job["progress_percent"] = 100
            job["current_step"] = request.steps
            job["total_steps"] = request.steps
            job["result"] = response
            job["error"] = None

    except Exception as error:
        print(
            f"Generation job {job_id} failed:",
            error,
        )

        with jobs_lock:
            job = jobs[job_id]

            job["status"] = "failed"
            job["completed_at"] = datetime.now(
                timezone.utc
            )
            job["result"] = None
            job["error"] = str(error)

    finally:
        with jobs_lock:
            if active_job_id == job_id:
                active_job_id = None

        generation_lock.release()


@app.get("/health")
def health():
    return {
        "status": "ok"
    }


@app.get("/info")
def info():
    busy = generation_lock.locked()

    return {
        "name": "WatcherTracker Local AI",
        "version": SERVER_VERSION,
        "backend": "mps",
        "log_file": log_file,
        "models": [
            "juggernaut-xl-v9"
        ],
        "model_loaded": generator.is_loaded,
        "busy": busy,
        "state": generator.state if busy else "idle",
        "prompt": generator.prompt if busy else None,
        "negative_prompt": generator.negative_prompt if busy else None,
        "width": generator.width if busy else None,
        "height": generator.height if busy else None,
        "steps": generator.total_steps if busy else None,
        "guidance_scale": generator.guidance_scale if busy else None,
        "seed": generator.seed if busy else None,
        "expected_filename": generator.output_filename if busy else None,
        "progress_percent": generator.progress_percent if busy else None,
        "current_step": generator.current_step if busy else None,
        "total_steps": generator.total_steps if busy else None,
    }


@app.get("/generated-files")
def generated_files():
    files = []

    for file in output_folder.iterdir():
        if not file.is_file():
            continue

        stat = file.stat()

        modified_at = datetime.fromtimestamp(
            stat.st_mtime,
            tz=timezone.utc,
        )

        files.append({
            "filename": file.name,
            "image_url": f"/images/{quote(file.name)}",
            "size_bytes": stat.st_size,
            "modified_at": modified_at.isoformat(),
        })

    files.sort(
        key=lambda item: item["modified_at"],
        reverse=True,
    )

    return {
        "count": len(files),
        "files": files,
    }


# MARK: - Resumable generation jobs


@app.put(
    "/jobs/{job_id}",
    status_code=202,
)
def start_generation_job(
    job_id: UUID,
    request: GenerationRequest,
):
    global active_job_id

    normalized_job_id = str(job_id)

    # PUT is idempotent. If the client retries the same
    # request after a temporary network failure, return
    # the already-existing job instead of starting a
    # duplicate generation.
    with jobs_lock:
        if normalized_job_id in jobs:
            existing = jobs[
                normalized_job_id
            ]

            return {
                "job_id": normalized_job_id,
                "status": existing["status"],
            }

    acquired = generation_lock.acquire(
        blocking=False
    )

    if not acquired:
        return JSONResponse(
            status_code=429,
            content={
                "detail":
                    "Image generation is already in progress."
            },
            headers={
                "Retry-After": "180"
            },
        )

    try:
        with jobs_lock:
            jobs[normalized_job_id] = {
                "status": "running",
                "created_at": datetime.now(
                    timezone.utc
                ),
                "completed_at": None,
                "request":
                    generation_request_snapshot(
                        request
                    ),
                "progress_percent": 0,
                "current_step": 0,
                "total_steps": request.steps,
                "result": None,
                "error": None,
            }

            active_job_id = normalized_job_id

        thread = Thread(
            target=run_generation_job,
            args=(
                normalized_job_id,
                request,
            ),
            daemon=True,
            name=f"generation-{normalized_job_id}",
        )

        thread.start()

    except Exception:
        with jobs_lock:
            jobs.pop(
                normalized_job_id,
                None,
            )

            if active_job_id == normalized_job_id:
                active_job_id = None

        generation_lock.release()
        raise

    return {
        "job_id": normalized_job_id,
        "status": "running",
    }


@app.get("/jobs/{job_id}")
def get_generation_job(
    job_id: UUID,
):
    return job_response(
        str(job_id)
    )


# MARK: - Existing synchronous endpoint
#
# Kept for compatibility with older clients and manual
# API testing. New clients should use /jobs.


@app.post("/generate")
def generate(
    request: GenerationRequest
):
    acquired = generation_lock.acquire(
        blocking=False
    )

    if not acquired:
        return JSONResponse(
            status_code=429,
            content={
                "detail":
                    "Image generation is already in progress."
            },
            headers={
                "Retry-After": "180"
            },
        )

    try:
        result = generator.generate(
            prompt=request.prompt,
            negative_prompt=request.negative_prompt,
            width=request.width,
            height=request.height,
            steps=request.steps,
            guidance_scale=request.guidance_scale,
            seed=request.seed,
            output_folder=output_folder,
        )

        return generation_result_response(
            result
        )

    finally:
        generation_lock.release()


@app.post("/unload")
def unload():
    if generation_lock.locked():
        return JSONResponse(
            status_code=409,
            content={
                "detail":
                    "Cannot unload the model while generation is in progress."
            },
        )

    generator.unload()

    return {
        "status": "ok",
        "model_loaded":
            generator.is_loaded,
    }


@app.delete("/generated-files/{filename}")
def delete_generated_file(filename: str):
    file_path = generated_file_path(filename)

    if (
        generation_lock.locked()
        and generator.output_filename == filename
    ):
        raise HTTPException(
            status_code=409,
            detail="Cannot delete the image currently being generated.",
        )

    if not file_path.exists():
        raise HTTPException(
            status_code=404,
            detail="Generated image not found.",
        )

    file_path.unlink()

    return {
        "status": "ok",
        "deleted": filename,
    }


@app.delete("/generated-files")
def delete_all_generated_files():
    if generation_lock.locked():
        raise HTTPException(
            status_code=409,
            detail="Cannot delete generated images while generation is in progress.",
        )

    deleted_count = 0

    for file in output_folder.glob("*.png"):
        if file.is_file():
            file.unlink()
            deleted_count += 1

    return {
        "status": "ok",
        "deleted_count": deleted_count,
    }
