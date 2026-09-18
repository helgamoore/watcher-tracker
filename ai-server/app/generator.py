import gc
import random
import time
from datetime import datetime
from pathlib import Path

import torch
from diffusers import StableDiffusionXLPipeline


class JuggernautGenerator:
    def __init__(self):
        self.model_id = "RunDiffusion/Juggernaut-XL-v9"
        self.pipe: StableDiffusionXLPipeline | None = None

        self.state = "idle"

        self.prompt: str | None = None
        self.negative_prompt: str | None = None
        self.width: int | None = None
        self.height: int | None = None
        self.guidance_scale: float | None = None
        self.seed: int | None = None

        self.current_step: int | None = None
        self.total_steps: int | None = None
        self.progress_percent: int | None = None

        self.output_filename: str | None = None

    @property
    def is_loaded(self) -> bool:
        return self.pipe is not None

    def load(self) -> None:
        if self.pipe is not None:
            return

        self.state = "loading"
        print("Loading Juggernaut XL...")

        self.pipe = StableDiffusionXLPipeline.from_pretrained(
            self.model_id,
            variant="fp16",
            dtype=torch.float16,
            use_safetensors=True,
        )

        self.pipe.to("mps")

        print("Juggernaut XL loaded.")

    def unload(self) -> None:
        if self.pipe is None:
            return

        print("Unloading Juggernaut XL...")

        self.pipe = None

        gc.collect()

        if torch.backends.mps.is_available():
            torch.mps.empty_cache()

        print("Juggernaut XL unloaded.")

    def generate(
        self,
        prompt: str,
        negative_prompt: str,
        width: int,
        height: int,
        steps: int,
        guidance_scale: float,
        seed: int | None,
        output_folder: Path,
    ) -> dict:
        if seed is None:
            seed = random.randint(0, 2**32 - 1)

        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S-%f")[:-3]
        filename = f"Juggernaut-Image-{timestamp}.png"

        # Store request details before model loading so /info can report them
        # during the complete lifetime of the request.
        self.prompt = prompt
        self.negative_prompt = negative_prompt
        self.width = width
        self.height = height
        self.guidance_scale = guidance_scale
        self.seed = seed

        self.current_step = 0
        self.total_steps = steps
        self.progress_percent = 0
        self.output_filename = filename

        try:
            self.load()

            if self.pipe is None:
                raise RuntimeError("Pipeline failed to load.")

            generator = torch.Generator(device="cpu").manual_seed(seed)

            output_folder.mkdir(
                parents=True,
                exist_ok=True,
            )

            self.state = "generating"

            def progress_callback(
                pipeline,
                step_index,
                timestep,
                callback_kwargs,
            ):
                self.current_step = step_index + 1

                if self.total_steps:
                    self.progress_percent = round(
                        self.current_step / self.total_steps * 100
                    )

                return callback_kwargs

            started = time.perf_counter()

            image = self.pipe(
                prompt=prompt,
                negative_prompt=negative_prompt,
                width=width,
                height=height,
                num_inference_steps=steps,
                guidance_scale=guidance_scale,
                generator=generator,
                callback_on_step_end=progress_callback,
            ).images[0]

            generation_seconds = time.perf_counter() - started

            self.state = "saving"

            output_path = output_folder / filename
            image.save(output_path)

            self.current_step = steps
            self.progress_percent = 100

            return {
                "image_path": str(output_path),
                "filename": filename,
                "seed": seed,
                "generation_seconds": generation_seconds,
                "width": width,
                "height": height,
            }

        finally:
            self.state = "idle"

            self.prompt = None
            self.negative_prompt = None
            self.width = None
            self.height = None
            self.guidance_scale = None
            self.seed = None

            self.current_step = None
            self.total_steps = None
            self.progress_percent = None

            self.output_filename = None
