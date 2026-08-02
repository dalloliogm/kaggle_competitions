#!/usr/bin/env python3
"""Build isolated GR-denoising variants from the clean ROGII GS1.30 notebook."""

from __future__ import annotations

import copy
import json
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK_DIR = REPO_ROOT / "competitions/rogii-wellbore-geology-prediction/notebooks"
BASE_NOTEBOOK = NOTEBOOK_DIR / "rogii-frontier-lab-clean.ipynb"
BASE_METADATA = NOTEBOOK_DIR / "rogii-frontier-lab-clean.kernel-metadata.json"

VARIANTS = {
    "rolling_median": {
        "filename": "rogii-gs130-gr-median7.ipynb",
        "kernel_id": "dalloliogm/rogii-gs1-30-gr-rolling-median-7",
        "title": "ROGII GS1.30 | GR Rolling Median 7",
        "description": "centered rolling-median window 7",
        "fft_flag": False,
    },
    "fft_notch": {
        "filename": "rogii-gs130-gr-fft-notch.ipynb",
        "kernel_id": "dalloliogm/rogii-gs1-30-gr-fft-notch",
        "title": "ROGII GS1.30 | GR FFT Notch",
        "description": "dominant-frequency FFT notch",
        "fft_flag": True,
    },
}


HELPER = '''\
def _denoise_gr_track(values, fill_value):
    """Prepare the GR signal used by PF/beam tracking without changing other features."""
    gr = pd.to_numeric(values, errors='coerce').interpolate(limit_direction='both').fillna(fill_value).astype(float)
    mode = str(globals().get('GR_DENOISE_MODE', 'none'))
    if mode == 'rolling_median':
        window = int(globals().get('GR_DENOISE_WINDOW', 7))
        if window < 1:
            return gr
        if window % 2 == 0:
            window += 1
        return gr.rolling(window=window, center=True, min_periods=1).median()
    if mode == 'fft_notch' and len(gr) >= 64:
        arr = gr.to_numpy(dtype=float, copy=True)
        center = float(np.median(arr))
        spectrum = np.fft.rfft(arr - center)
        amplitude = np.abs(spectrum)
        amplitude[0] = 0.0
        peak = int(np.argmax(amplitude))
        lo, hi = max(1, peak - 1), min(len(spectrum), peak + 2)
        spectrum[lo:hi] = 0.0
        filtered = np.fft.irfft(spectrum, n=len(arr)) + center
        return pd.Series(filtered, index=gr.index, name=gr.name)
    return gr


'''

MOUNT_COMPAT = '''\
# Kaggle may provision code runs with either the namespaced or legacy input layout.
_competition_data_candidates = (
    '/kaggle/input/competitions/rogii-wellbore-geology-prediction',
    '/kaggle/input/rogii-wellbore-geology-prediction',
)
COMPETITION_DATA_ROOT = next(
    (p for p in _competition_data_candidates if (Path(p) / 'train').exists()),
    _competition_data_candidates[0],
)
_ridge_artifact_candidates = (
    '/kaggle/input/datasets/ravaghi/wellbore-geology-prediction-artifacts',
    '/kaggle/input/wellbore-geology-prediction-artifacts',
)
RIDGE_ARTIFACT_ROOT = next(
    (p for p in _ridge_artifact_candidates if Path(p).exists()),
    _ridge_artifact_candidates[0],
)
print('competition data root:', COMPETITION_DATA_ROOT)
print('ridge artifact root:', RIDGE_ARTIFACT_ROOT)


'''


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one {label} replacement, found {count}")
    return text.replace(old, new, 1)


def build_notebook(base: dict, mode: str, spec: dict) -> dict:
    nb = copy.deepcopy(base)

    config = "".join(nb["cells"][0]["source"])
    config = "# ROGII GS1.30 isolated GR-denoising experiment: " + spec["description"] + "\n" + config
    config = replace_once(
        config,
        "RUN_GR_FFT_DENOISE = False\nRUN_SEQ_MATCHER = False",
        f"RUN_GR_FFT_DENOISE = {spec['fft_flag']}\n"
        f"GR_DENOISE_MODE = '{mode}'\n"
        "GR_DENOISE_WINDOW = 7\n"
        "RUN_SEQ_MATCHER = False",
        "denoise config",
    )
    nb["cells"][0]["source"] = config.splitlines(keepends=True)

    if mode == "fft_notch":
        cfg = "".join(nb["cells"][4]["source"])
        if not cfg.startswith("class CFG:"):
            raise RuntimeError("Unexpected CFG cell layout")
        nb["cells"][4]["source"] = (MOUNT_COMPAT + cfg).splitlines(keepends=True)

    selector = "".join(nb["cells"][5]["source"])
    selector = replace_once(
        selector,
        "    return hw, tw\n\n\ndef run_particle_filter",
        "    return hw, tw\n\n\n" + HELPER + "def run_particle_filter",
        "GR helper insertion",
    )
    selector = replace_once(
        selector,
        "    tw_at_k = np.interp(kn['TVT_input'].values, tw_tvt, tw_gr)\n"
        "    gs = float(np.clip(np.nanstd(kn['GR'].fillna(0).values - tw_at_k), 10., 60.))",
        "    gr_track = _denoise_gr_track(hw['GR'], tw_gr.mean())\n"
        "    tw_at_k = np.interp(kn['TVT_input'].values, tw_tvt, tw_gr)\n"
        "    gs = float(np.clip(np.nanstd(gr_track.loc[kn.index].values - tw_at_k), 10., 60.))",
        "particle-filter known-prefix GR",
    )
    selector = replace_once(
        selector,
        "    # Interpolate GR gaps before tracking\n"
        "    gr_interp = hw['GR'].interpolate(limit_direction='both').fillna(tw_gr.mean())\n"
        "    gr_v = gr_interp.values.astype(float)[ev.index]",
        "    # Denoise only the GR signal consumed by the tracker.\n"
        "    gr_v = gr_track.loc[ev.index].values.astype(float)",
        "particle-filter evaluation GR",
    )
    selector = replace_once(
        selector,
        "    gr_all = hw['GR'].interpolate(limit_direction='both').fillna(tw_gr.mean()).values.astype(float)\n"
        "    hgr    = gr_all[ev.index]",
        "    gr_all = _denoise_gr_track(hw['GR'], tw_gr.mean())\n"
        "    hgr    = gr_all.loc[ev.index].values.astype(float)",
        "beam GR",
    )
    nb["cells"][5]["source"] = selector.splitlines(keepends=True)

    learned = "".join(nb["cells"][31]["source"])
    learned = replace_once(
        learned,
        "    tw_at_k = np.interp(kn.TVT_input.values, tw_tvt, tw_gr)\n"
        "    gs = float(np.clip(np.nanstd(kn.GR.fillna(0).values - tw_at_k), 10., 60.)) * 1.3",
        "    gr_track = _denoise_gr_track(hw.GR, tw_gr.mean())\n"
        "    tw_at_k = np.interp(kn.TVT_input.values, tw_tvt, tw_gr)\n"
        "    gs = float(np.clip(np.nanstd(gr_track.loc[kn.index].values - tw_at_k), 10., 60.)) * 1.3",
        "learned PF known-prefix GR",
    )
    learned = replace_once(
        learned,
        '    gr_v = hw.GR.interpolate(limit_direction="both").fillna(tw_gr.mean()).values.astype(float)[ev.index]',
        "    gr_v = gr_track.loc[ev.index].values.astype(float)",
        "learned PF evaluation GR",
    )
    nb["cells"][31]["source"] = learned.splitlines(keepends=True)

    for cell in nb["cells"]:
        if cell.get("cell_type") == "code":
            cell["execution_count"] = None
            cell["outputs"] = []
            cell.get("metadata", {}).pop("execution", None)
            cell.get("metadata", {}).pop("papermill", None)

    return nb


def main() -> None:
    base = json.loads(BASE_NOTEBOOK.read_text())
    base_metadata = json.loads(BASE_METADATA.read_text())

    for mode, spec in VARIANTS.items():
        notebook = build_notebook(base, mode, spec)
        notebook_path = NOTEBOOK_DIR / spec["filename"]
        notebook_path.write_text(json.dumps(notebook, indent=1, ensure_ascii=False) + "\n")

        metadata = copy.deepcopy(base_metadata)
        metadata.update(
            id=spec["kernel_id"],
            title=spec["title"],
            code_file=spec["filename"],
        )
        metadata_path = notebook_path.with_suffix(".kernel-metadata.json")
        metadata_path.write_text(json.dumps(metadata, indent=2) + "\n")
        print(f"built {notebook_path.relative_to(REPO_ROOT)}")
        print(f"built {metadata_path.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
