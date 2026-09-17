import gc
import random
import time
from pathlib import Path

import torch
from diffusers import StableDiffusionXLPipeline


class JuggernautGenerator:
    def __init__(self):
        self.model_id = "RunDiffusion/Juggernaut-XL-v9"
        self.pipe: StableDiffusionXLPipeline | None = None

    @property
    def is_loaded(self) -> bool:
        return self.pipe is not None

    def load(self) -> None:
        if self.pipe is not None:
            return

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

        self.load()

        if self.pipe is None:
            raise RuntimeError("Pipeline failed to load.")

        if seed is None:
            seed = random.randint(0, 2**32 - 1)

        generator = torch.Generator(
            device="cpu"
        ).manual_seed(seed)

        output_folder.mkdir(
            parents=True,
            exist_ok=True,
        )

        started = time.perf_counter()

        image = self.pipe(
            prompt=prompt,
            negative_prompt=negative_prompt,
            width=width,
            height=height,
            num_inference_steps=steps,
            guidance_scale=guidance_scale,
            generator=generator,
        ).images[0]

        generation_seconds = (
            time.perf_counter() - started
        )

        filename = f"juggernaut_{seed}.png"

        output_path = (
            output_folder / filename
        )

        image.save(output_path)

        return {
            "image_path": str(output_path),
            "seed": seed,
            "generation_seconds": generation_seconds,
            "width": width,
            "height": height,
        }