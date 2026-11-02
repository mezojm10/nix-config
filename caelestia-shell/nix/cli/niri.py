import json
import subprocess
from typing import Any


def message(*args: str) -> Any:
    return json.loads(subprocess.check_output(["niri", "msg", "--json", *args], text=True))


def monitors() -> list[dict[str, Any]]:
    """Enabled niri outputs, shaped like the `hyprctl monitors` fields the CLI reads."""
    focused = message("focused-output")
    focused_name = focused["name"] if focused else None

    result = []
    for name, output in message("outputs").items():
        logical = output.get("logical")
        current_mode = output.get("current_mode")
        # Disabled outputs have neither
        if logical is None or current_mode is None:
            continue

        result.append(
            {
                "name": name,
                "x": logical["x"],
                "y": logical["y"],
                "width": logical["width"],
                "height": logical["height"],
                # niri reports millihertz
                "refreshRate": output["modes"][current_mode]["refresh_rate"] / 1000,
                "focused": name == focused_name,
            }
        )

    return result
