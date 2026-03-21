import argparse
import os
from pathlib import Path

from TTS.api import TTS


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--speaker", default="")
    parser.add_argument("--gpu", default="0")
    parser.add_argument("--text", default="")
    parser.add_argument("--output", default="")
    parser.add_argument("--preload", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    user_profile = os.environ.get("USERPROFILE") or str(Path.home())
    os.environ.setdefault("LOCALAPPDATA", str(Path(user_profile) / "AppData" / "Local"))
    os.environ.setdefault("APPDATA", str(Path(user_profile) / "AppData" / "Roaming"))
    os.environ["TTS_HOME"] = str(Path(__file__).resolve().parents[1] / "tts_cache")
    tts = TTS(
        model_name=args.model,
        progress_bar=False,
        gpu=args.gpu == "1",
    )

    if args.preload:
        return 0

    text = args.text.strip()
    if not text:
        raise ValueError("Text input for TTS cannot be empty")

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    kwargs: dict[str, str] = {}
    speakers = getattr(tts, "speakers", None) or []
    if speakers:
        speaker = args.speaker.strip()
        kwargs["speaker"] = speaker if speaker in speakers else speakers[0]

    tts.tts_to_file(text=text, file_path=str(output_path), **kwargs)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
