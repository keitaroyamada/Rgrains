# /// script
# requires-python = ">=3.11"
# dependencies = ["mcp==2.3.0"]
# ///
"""MCP adapter for the existing Rgrains GUI command interface.

Install:  python -m pip install "mcp==2.3.0"
Run:      python rgrains_mcp.py --host 127.0.0.1 --port 50001 --timeout 3600
Or:       uv run rgrains_mcp.py
Catalog:  python rgrains_mcp.py --list-commands

The MCP host launches this file with stdio transport. Start the Rgrains GUI
first; its TCP command interface requires Instrument Control Toolbox. No MATLAB
Engine, GUI automation, image capture, or changes to the MLAPP are used here.

MCP tool          GUI TCP action       Arguments
get_state         get_state            none
load_image        load                 path
set_options       set_options          options (partial opts_* objects)
binarise          binarise             none (binarize is a GUI-side alias)
analyse           analyse              none (analyze is a GUI-side alias)
replot            replot               none
export_results    export               directory
get_results       get_results          none
set_view          set_view             view: Original / BW / Results
press_button      press_button         button; path/directory when needed
load_settings     load_settings        path
save_settings     save_settings        path

Normal workflow: get_state -> set_options -> load_image -> binarise -> analyse
-> get_results -> optional replot/export_results. Changing analysis options
does not recalculate results: call analyse again. Changing binarisation options
requires binarise and then analyse; changing upconvert requires reloading the
image as well. Plot-only changes need replot. Paths are absolute on the GUI's
computer. JSON null is the unlimited upper noise threshold and can reset
opts_app.base_dir/save_dir. Other explicit null options are rejected.

Long calculations: the default socket timeout is one hour, adjustable with
--timeout. Set the MCP host's tool-call timeout accordingly too. Progress
notifications report elapsed seconds, not completion percentages. Requests
share one persistent TCP connection and are never executed concurrently.
Cancelling an MCP call does NOT stop MATLAB calculation. The operation keeps
the connection lock until it finishes; get_state reports local BUSY status.
Timeouts/disconnections have uncertain outcomes and NEVER trigger a replay.
The GUI's ERROR reply contains no error details; consult MATLAB command output.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import math
import socket
import threading
import time
from contextlib import asynccontextmanager
from pathlib import PurePosixPath, PureWindowsPath
from typing import Annotated, Any, ClassVar, Literal

try:
    from mcp.server import MCPServer
    from mcp.server.mcpserver import Context
    from mcp.server.mcpserver.exceptions import ToolError
    from mcp.types import ToolAnnotations
    from pydantic import BaseModel, ConfigDict, Field, StrictBool, model_validator
except ImportError as exc:
    raise SystemExit(
        'Rgrains MCP requires Python 3.11+ and mcp==2.3.0. '
        'Install with: python -m pip install "mcp==2.3.0"'
    ) from exc


LOG = logging.getLogger("rgrains_mcp")
PROGRESS_INTERVAL = 10.0
UnitInterval = Annotated[float, Field(ge=0, le=1, allow_inf_nan=False)]
Positive = Annotated[float, Field(gt=0, allow_inf_nan=False)]
Nonnegative = Annotated[float, Field(ge=0, allow_inf_nan=False)]
Color = str | Annotated[list[UnitInterval], Field(min_length=3, max_length=3)]
EmptyDirectory = Annotated[list[None], Field(max_length=0)]
Button = Literal[
    "LoadimageButton", "BinariseButton", "AnalyseButton", "ReplotButton", "ExportButton"
]
View = Literal["Original", "BW", "Results"]


class PartialOptions(BaseModel):
    """Only explicitly supplied fields are sent; unknown fields are errors."""

    model_config = ConfigDict(extra="forbid")
    nullable_fields: ClassVar[frozenset[str]] = frozenset()

    @model_validator(mode="after")
    def check_explicit_nulls(self):
        for name in self.model_fields_set:
            if getattr(self, name) is None and name not in self.nullable_fields:
                raise ValueError(f"Omit {name} to keep its current value; null is not valid.")
        return self


class BinariseOptions(PartialOptions):
    upconvert: StrictBool | None = Field(None, description="Double image size during load; reload after changing.")
    particle_color: Literal["Dark", "Bright"] | None = Field(None, description="Particle brightness relative to the background.")
    method: Literal["Adaptive", "Otsu", "Absolute", "Edge", "None"] | None = Field(None, description="Existing GUI binarisation method.")
    adaptive_sensitivity: UnitInterval | None = Field(None, description="Sensitivity/threshold in [0,1], interpreted by the selected method.")
    noise_thresholds: tuple[Nonnegative, Nonnegative | None] | None = Field(None, description="Lower and upper particle-area thresholds in pixels of the processed image. Upper null means unlimited.")
    ignore_particles_on_borders: StrictBool | None = Field(None, description="Exclude particles touching image borders.")

    @model_validator(mode="after")
    def check_threshold_order(self):
        if self.noise_thresholds is not None:
            lower, upper = self.noise_thresholds
            if upper is not None and lower > upper:
                raise ValueError("Lower noise threshold must not exceed the upper threshold.")
        return self


class RoundnessOptions(PartialOptions):
    calc_roundness: StrictBool | None = Field(None, description="Compute roundness as well as the other shape measurements.")
    trace_precision: UnitInterval | None = Field(None, description="Boundary-fitting span in [0,1]; existing trace_precision parameter.")
    corner_sensitivity: UnitInterval | None = Field(None, description="Corner-detection sensitivity in [0,1].")
    circle_precision: UnitInterval | None = Field(None, description="Circle-fitting precision in [0,1]. GUI displays only three decimal places; get_state returns the stored value. Higher precision can increase computation time.")
    image_scale: Positive | None = Field(None, description="Original image resolution in pixels per centimetre (pix/cm).")
    PCD_normalisation: StrictBool | None = Field(None, description="Normalise particle size by minimum circumscribed-circle diameter before calculation.")
    PCD_size: Positive | None = Field(None, description="Target normalised particle diameter in pixels.")
    circularity_type: Literal["legacy", "new"] | None = Field(None, description="Use the existing legacy or new circularity calculation.")
    filter_inaccurate_outline: StrictBool | None = Field(None, description="Use Rgrains' existing classifier to filter inaccurate outlines when available.")


class PlotOptions(PartialOptions):
    base_image: Literal["original", "bw"] | None = Field(None, description="Background image used when drawing results.")
    colour_smoothed_particle_boundaries: Color | None = Field(None, description="Particle-outline colour: MATLAB colour name/hex code or RGB values in [0,1].")
    thickness_smoothed_particle_boundaries: Positive | None = Field(None, description="Particle-outline line width in points.")
    colour_max_inscribed_circle: Color | None = Field(None, description="Colour of the large maximum inscribed circle, not the small corner circles.")
    thickness_max_inscribed_circle: Positive | None = Field(None, description="Maximum-inscribed-circle line width in points.")
    colour_corner_circles: Color | None = Field(None, description="Colour of the small circles fitted at particle corners.")
    thickness_corner_circles: Positive | None = Field(None, description="Small corner-circle line width in points.")
    colour_info_text: Color | None = Field(None, description="Colour of particle labels.")
    font_size_info_text: Positive | None = Field(None, description="Particle-label font size in points.")
    font: str | None = Field(None, min_length=1, description="MATLAB font name, for example Arial.")
    plot_info: Literal["Particlenumber", "Roundness"] | None = Field(None, description="Value displayed in particle labels.")


class ExportOptions(PartialOptions):
    save_bw_image: StrictBool | None = Field(None, description="Export the binary image.")
    save_fitted_image_with_No: StrictBool | None = Field(None, description="Export a fitted image labelled with particle numbers.")
    save_fitted_image_vector: StrictBool | None = Field(None, description="Export fitted boundaries as the existing EPS vector output.")
    save_fitted_image_with_Roundness: StrictBool | None = Field(None, description="Export a fitted image labelled with roundness values.")
    save_summary_image: StrictBool | None = Field(None, description="Export the summary plot image.")
    save_csv: StrictBool | None = Field(None, description="Export the particle-measurement CSV table.")
    save_each_circles_csv: StrictBool | None = Field(None, description="Include small-circle radius data in the measurement table.")
    save_annotation: StrictBool | None = Field(None, description="Export the existing XML annotation output.")
    save_edge_annotation: StrictBool | None = Field(None, description="Export the existing YOLO-format edge annotations.")
    annotation_target: Literal["Roundness", "R", "Circularity", "Majorlength", "Minorlength", "Area", "Aspect", "PCD"] | None = Field(None, description="Measurement used for annotation classes.")
    save_settings: StrictBool | None = Field(None, description="Export the per-image .rgrains settings file.")


class AppOptions(PartialOptions):
    nullable_fields: ClassVar[frozenset[str]] = frozenset({"base_dir", "save_dir"})
    base_dir: str | EmptyDirectory | None = Field(None, description="Default image-selection directory on the GUI computer; null or an empty array resets it.")
    save_dir: str | EmptyDirectory | None = Field(None, description="Default export-selection directory on the GUI computer; null or an empty array resets it.")
    in_image_type: Literal["jpg", "tif", "png"] | None = Field(None, description="Image extension selected in the acquisition menu.")


class OptionsPatch(PartialOptions):
    opts_binarise: BinariseOptions | None = Field(None, description="Partial binarisation settings.")
    opts_roundness: RoundnessOptions | None = Field(None, description="Partial shape/roundness calculation settings.")
    opts_plot: PlotOptions | None = Field(None, description="Partial result-display settings; use replot after changing.")
    opts_export: ExportOptions | None = Field(None, description="Partial output-selection settings.")
    opts_app: AppOptions | None = Field(None, description="Partial acquisition/default-directory settings.")


COMMANDS = {
    "get_state": {"action": "get_state", "arguments": []},
    "load_image": {"action": "load", "arguments": ["path"]},
    "set_options": {"action": "set_options", "arguments": ["options"]},
    "binarise": {"action": "binarise", "arguments": [], "gui_aliases": ["binarize"]},
    "analyse": {"action": "analyse", "arguments": [], "gui_aliases": ["analyze"]},
    "replot": {"action": "replot", "arguments": []},
    "export_results": {"action": "export", "arguments": ["directory"]},
    "get_results": {"action": "get_results", "arguments": []},
    "set_view": {"action": "set_view", "arguments": ["view"]},
    "press_button": {"action": "press_button", "arguments": ["button", "path?", "directory?"]},
    "load_settings": {"action": "load_settings", "arguments": ["path"]},
    "save_settings": {"action": "save_settings", "arguments": ["path"]},
}


class RgrainsConnection:
    """One serialized, persistent ASCII-JSON/LF connection to the official GUI API."""

    def __init__(self, host="127.0.0.1", port=50001, timeout=3600.0, connect_timeout=5.0):
        self.host, self.port = host, port
        self.timeout, self.connect_timeout = timeout, connect_timeout
        self._socket = None
        self._reader = None
        self._lock = threading.Lock()
        self._active = None
        self._close_requested = False

    def busy_state(self):
        active = self._active
        if active is None:
            return None
        return {"status": "BUSY", "busy": True, "source": "mcp_server",
                "command": active[0], "elapsed_seconds": round(time.monotonic() - active[1], 1),
                "message": "An existing command is still running; no additional TCP request was sent."}

    def close(self):
        self._close_requested = True
        if self._lock.acquire(blocking=False):
            try:
                self._disconnect()
            finally:
                self._lock.release()

    def _disconnect(self):
        if self._reader is not None:
            self._reader.close()
        if self._socket is not None:
            self._socket.close()
        self._reader = self._socket = None

    def _exchange(self, payload):
        action = payload["action"]
        if self._socket is None:
            try:
                self._socket = socket.create_connection((self.host, self.port), self.connect_timeout)
                self._socket.settimeout(self.timeout)
                self._reader = self._socket.makefile("rb")
            except OSError as exc:
                self._disconnect()
                raise ToolError(
                    f"Cannot connect to Rgrains at {self.host}:{self.port}: {exc}. Start the GUI "
                    "with its Instrument Control Toolbox command interface enabled. No command was sent."
                ) from exc
        try:
            data = (json.dumps(payload, ensure_ascii=True, allow_nan=False) + "\n").encode("ascii")
            self._socket.sendall(data)
            line = self._reader.readline(64 * 1024 * 1024 + 1)
            if not line.endswith(b"\n") or len(line) > 64 * 1024 * 1024:
                raise OSError("Missing, incomplete, or oversized GUI response")
        except (OSError, ValueError) as exc:
            self._disconnect()
            raise ToolError(
                f"Communication failed or timed out during '{action}'. Its outcome is unknown "
                "and MATLAB may still be calculating. The command was NOT replayed. "
                "Check get_state after the GUI is available before deciding what to do."
            ) from exc
        try:
            reply = line.decode("utf-8").strip()
            if reply == "ERROR":
                raise ToolError(
                    f"Rgrains rejected '{action}'. Check get_state for prerequisites and current "
                    "settings. The GUI returns no detailed error; details are in MATLAB command output."
                )
            if reply == "OK":
                return {"status": "OK", "action": action}
            result = json.loads(reply)
            if not isinstance(result, dict) or result.get("status") != "OK":
                raise ValueError("Unexpected GUI response format")
            return result
        except (UnicodeError, ValueError) as exc:
            self._disconnect()
            raise ToolError(f"Invalid response to '{action}'; the command was not replayed.") from exc

    def execute(self, payload, *, with_state=False):
        if not self._lock.acquire(blocking=False):
            active = self.busy_state() or {}
            raise ToolError(f"Rgrains is processing {active.get('command', 'another command')}; no new command was sent.")
        self._active = (payload["action"], time.monotonic())
        try:
            if self._close_requested:
                raise ToolError("The MCP connection is shutting down; no command was sent.")
            result = self._exchange(payload)
            if with_state:
                try:
                    result["state"] = self._exchange({"action": "get_state"})
                except ToolError as exc:
                    raise ToolError(
                        f"'{payload['action']}' was acknowledged OK, but state verification failed. "
                        "Do not replay it automatically; retrieve get_state after reconnecting."
                    ) from exc
            return result
        finally:
            if self._close_requested:
                self._disconnect()
            self._active = None
            self._lock.release()


connection = RgrainsConnection()


@asynccontextmanager
async def lifespan(_server):
    try:
        yield {}
    finally:
        connection.close()


mcp = MCPServer(
    "Rgrains", version="1.0.0", lifespan=lifespan,
    instructions=(
        "Control the already-running Rgrains GUI through its existing TCP interface. "
        "Inspect get_state first. Use set_options, load_image, binarise, analyse, then get_results. "
        "All options are partial patches; unspecified values are retained. Plot-only changes need replot. "
        "Analysis changes need analyse again; binarisation changes need binarise then analyse. "
        "Calculations can be very slow: wait for completion and never repeat an in-flight command. "
        "Cancelling this MCP request does not cancel MATLAB. get_state returns local BUSY while "
        "a command is in flight. Use absolute paths on the GUI computer."
    ),
)
READ = ToolAnnotations(read_only_hint=True, open_world_hint=False)
CHANGE = ToolAnnotations(read_only_hint=False, destructive_hint=False, idempotent_hint=True, open_world_hint=False)
REPLACE = ToolAnnotations(read_only_hint=False, destructive_hint=True, idempotent_hint=False, open_world_hint=False)


def absolute_path(value, *, settings=False):
    if not value or not (PureWindowsPath(value).is_absolute() or PurePosixPath(value).is_absolute()):
        raise ToolError("Use a nonempty absolute path on the computer running the Rgrains GUI.")
    if settings and PureWindowsPath(value).suffix.lower() != ".rgrains":
        raise ToolError("Settings paths must end in .rgrains.")
    return value


def consume_detached_result(task):
    try:
        task.result()
    except (Exception, asyncio.CancelledError) as exc:
        LOG.warning("A detached Rgrains operation finished with an error: %s", exc)


async def run_mutation(payload, ctx):
    # Shield the worker: MCP cancellation cannot stop a calculation in MATLAB.
    task = asyncio.create_task(asyncio.to_thread(connection.execute, payload, with_state=True))
    started = time.monotonic()
    try:
        while not task.done():
            done, _ = await asyncio.wait({task}, timeout=PROGRESS_INTERVAL)
            if not done:
                elapsed = time.monotonic() - started
                await ctx.report_progress(elapsed, message=(
                    f"Rgrains '{payload['action']}' is running; {elapsed:.0f} seconds elapsed. "
                    "Completion percentage is not provided by the GUI."
                ))
        return await asyncio.shield(task)
    finally:
        if not task.done():
            task.add_done_callback(consume_detached_result)


@mcp.tool(annotations=READ)
async def get_state() -> dict[str, Any]:
    """Get the GUI image, all current opts_* settings, view, particle count and enabled buttons.

    During this server's active command, return lightweight local BUSY status
    with elapsed seconds instead of queueing another TCP request. A three-digit
    GUI display can round circle_precision; this response preserves its value.
    """
    active = connection.busy_state()
    return active if active is not None else await asyncio.to_thread(connection.execute, {"action": "get_state"})


@mcp.tool(annotations=REPLACE)
async def load_image(path: Annotated[str, Field(description="Absolute image path on the GUI computer; replaces current image/results.")], ctx: Context) -> dict[str, Any]:
    """Load an image and update the GUI. Existing results are replaced without a file dialog.

    Set upconvert before loading. Returns OK and the updated GUI state.
    """
    return await run_mutation({"action": "load", "path": absolute_path(path)}, ctx)


@mcp.tool(annotations=CHANGE)
async def set_options(options: OptionsPatch, ctx: Context) -> dict[str, Any]:
    """Patch any existing opts_binarise/opts_roundness/opts_plot/opts_export/opts_app fields.

    Unspecified fields are retained; unknown fields are rejected. Settings are
    reflected in the GUI and the verified state is returned. This does not run
    calculations or redraw results. Use replot for colour changes, binarise then
    analyse for binarisation changes, or analyse for roundness changes.
    """
    patch = options.model_dump(mode="json", exclude_unset=True)
    if not patch or not any(patch.values()):
        raise ToolError("Supply at least one option field to change.")
    return await run_mutation({"action": "set_options", "options": patch}, ctx)


@mcp.tool(annotations=REPLACE)
async def binarise(ctx: Context) -> dict[str, Any]:
    """Run the existing Binarise button on a loaded image and show the binary overlay.

    Does not run roundness calculation. Returns OK and updated GUI state.
    """
    return await run_mutation({"action": "binarise"}, ctx)


@mcp.tool(annotations=REPLACE)
async def analyse(ctx: Context) -> dict[str, Any]:
    """Run the existing Analyse button after binarisation, then draw the results.

    This can take many minutes. Uses the configured long timeout, sends elapsed
    time notifications, and rejects concurrent commands. Do not automatically
    retry on cancellation/timeout: MATLAB calculation may continue. No automatic
    binarisation or export is performed. Returns OK and completed GUI state;
    retrieve measurements with get_results.
    """
    return await run_mutation({"action": "analyse"}, ctx)


@mcp.tool(annotations=CHANGE)
async def replot(ctx: Context) -> dict[str, Any]:
    """Run Replot with current plot options and existing analysis results.

    Applies colours, labels, font and line widths without recalculating shapes.
    """
    return await run_mutation({"action": "replot"}, ctx)


@mcp.tool(annotations=REPLACE)
async def export_results(directory: Annotated[str, Field(description="Absolute output directory on the GUI computer; created if needed.")], ctx: Context) -> dict[str, Any]:
    """Run Export using current opts_export settings after successful analysis.

    Writes selected CSV/images/annotations/settings. Existing matching filenames
    can be overwritten. Export may also be slow. Returns the GUI acknowledgement
    and state, not a file-by-file export manifest.
    """
    return await run_mutation({"action": "export", "directory": absolute_path(directory)}, ctx)


@mcp.tool(annotations=READ)
async def get_results() -> dict[str, Any]:
    """Get the existing measurement table after analysis as a list of particle records.

    Roundness is dimensionless; *_cm lengths and *_cm2 areas carry their named
    units. Names/data follow the existing GUI get_results response. JSON null
    can denote a missing/NaN measurement. Does not recalculate or export files.
    """
    result = await asyncio.to_thread(connection.execute, {"action": "get_results"})
    if isinstance(result.get("results"), dict):
        result["results"] = [result["results"]]
    return result


@mcp.tool(annotations=CHANGE)
async def set_view(view: View, ctx: Context) -> dict[str, Any]:
    """Select Original, BW or Results using the existing GUI view control.

    Load an image first. The GUI can fall back to Original when a requested
    derived view is unavailable; inspect the returned state.
    """
    return await run_mutation({"action": "set_view", "view": view}, ctx)


@mcp.tool(annotations=REPLACE)
async def press_button(button: Button, ctx: Context, path: str | None = None, directory: str | None = None) -> dict[str, Any]:
    """Invoke any of the five GUI buttons through its existing command handler.

    LoadimageButton requires absolute path; ExportButton requires absolute
    directory. Other buttons take neither. Disabled buttons are rejected by
    Rgrains. AnalyseButton has the same heavy-calculation behaviour as analyse.
    """
    payload = {"action": "press_button", "button": button}
    if button == "LoadimageButton":
        if path is None or directory is not None:
            raise ToolError("LoadimageButton requires path and does not take directory.")
        payload["path"] = absolute_path(path)
    elif button == "ExportButton":
        if directory is None or path is not None:
            raise ToolError("ExportButton requires directory and does not take path.")
        payload["directory"] = absolute_path(directory)
    elif path is not None or directory is not None:
        raise ToolError("This button takes neither path nor directory.")
    return await run_mutation(payload, ctx)


@mcp.tool(annotations=REPLACE)
async def load_settings(path: Annotated[str, Field(description="Absolute path to an existing .rgrains settings file.")], ctx: Context) -> dict[str, Any]:
    """Load settings using the GUI's existing settings method and synchronise its controls.

    Does not reload the image, recalculate, or redraw existing results.
    """
    return await run_mutation({"action": "load_settings", "path": absolute_path(path, settings=True)}, ctx)


@mcp.tool(annotations=REPLACE)
async def save_settings(path: Annotated[str, Field(description="Absolute .rgrains output path; its parent directory must exist.")], ctx: Context) -> dict[str, Any]:
    """Save current settings with the existing GUI method. May overwrite the named file."""
    return await run_mutation({"action": "save_settings", "path": absolute_path(path, settings=True)}, ctx)


@mcp.resource("rgrains://commands")
def command_reference() -> str:
    """Catalog of all implemented MCP tools and their existing GUI TCP commands."""
    return json.dumps({"commands": COMMANDS, "workflow": __doc__}, ensure_ascii=False, indent=2)


def main():
    global connection
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--host", default="127.0.0.1", help="Rgrains TCP host (not an MCP HTTP listener).")
    parser.add_argument("--port", type=int, default=50001, help="Rgrains TCP port (default: 50001).")
    parser.add_argument("--timeout", type=float, default=3600.0, help="GUI response timeout in seconds; default: 3600. Also configure the MCP host's timeout.")
    parser.add_argument("--connect-timeout", type=float, default=5.0, help="TCP connection timeout in seconds.")
    parser.add_argument("--list-commands", action="store_true", help="Print the command catalog and exit without connecting.")
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error("--port must be between 1 and 65535")
    if not all(math.isfinite(value) and value > 0 for value in (args.timeout, args.connect_timeout)):
        parser.error("timeouts must be positive finite numbers")
    if args.list_commands:
        print(json.dumps(COMMANDS, ensure_ascii=False, indent=2))
        return
    connection = RgrainsConnection(args.host, args.port, args.timeout, args.connect_timeout)
    try:
        mcp.run(transport="stdio")
    finally:
        connection.close()


if __name__ == "__main__":
    main()
