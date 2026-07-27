import fs from "node:fs";
import path from "node:path";

const repoRoot = process.cwd();
const notebookDir = path.join(
  repoRoot,
  "competitions/rogii-wellbore-geology-prediction/notebooks",
);
const sourcePath = path.join(notebookDir, "working-note-neighbor-transfer-v2.ipynb");
const targetPath = path.join(notebookDir, "working-note-pf-seed-branch-hedge.ipynb");
const sourceMetadataPath = path.join(
  notebookDir,
  "working-note-neighbor-transfer-v2.kernel-metadata.json",
);
const targetMetadataPath = path.join(
  notebookDir,
  "working-note-pf-seed-branch-hedge.kernel-metadata.json",
);

const notebook = JSON.parse(fs.readFileSync(sourcePath, "utf8"));

function cellSource(index) {
  const source = notebook.cells[index].source;
  return Array.isArray(source) ? source.join("") : source;
}

function setCellSource(index, source) {
  notebook.cells[index].source = source;
  notebook.cells[index].outputs = [];
  notebook.cells[index].execution_count = null;
}

let selectorSource = cellSource(11);
const oldFunction = `def run_pf_lik_ensemble_scales(hw, tw, scales=SELECTOR_SCALES, n_particles=500, n_seeds=128):
    preds = []
    liks = []
    for s in range(n_seeds):
        p, ll = run_particle_filter(hw, tw, n_particles=n_particles, seed=s)
        preds.append(p)
        liks.append(ll)
    pred_arr = np.stack(preds, 0)
    liks = np.array(liks)
    liks_n = liks - liks.max()
    out = {}
    for scale in scales:
        weights = np.exp(liks_n / float(scale))
        weights /= weights.sum()
        out[f'pf_scale_{scale:g}'] = (weights[:, None] * pred_arr).sum(0)
    out['pf_mean'] = pred_arr.mean(0)
    if bool(globals().get('SELECTOR_PF_RETURN_STD', False)):
        out['pf_seed_std'] = pred_arr.std(0)
    return out
`;

const newFunction = `def run_pf_lik_ensemble_scales(
    hw,
    tw,
    scales=SELECTOR_SCALES,
    n_particles=500,
    n_seeds=128,
    branch_stats=None,
):
    preds = []
    liks = []
    for s in range(n_seeds):
        p, ll = run_particle_filter(hw, tw, n_particles=n_particles, seed=s)
        preds.append(p)
        liks.append(ll)
    pred_arr = np.stack(preds, 0)
    liks = np.array(liks)
    liks_n = liks - liks.max()
    out = {}
    for scale in scales:
        weights = np.exp(liks_n / float(scale))
        weights /= weights.sum()
        out[f'pf_scale_{scale:g}'] = (weights[:, None] * pred_arr).sum(0)
    out['pf_mean'] = pred_arr.mean(0)
    if bool(globals().get('SELECTOR_PF_RETURN_STD', False)):
        out['pf_seed_std'] = pred_arr.std(0)

    # Preserve the seed-level posterior geometry for the final guarded hedge.
    # This is diagnostic-only here: the regular PF ensemble remains unchanged.
    if branch_stats is not None:
        try:
            eval_mask = pd.to_numeric(
                hw['TVT_input'], errors='coerce'
            ).isna().to_numpy()
            if int(eval_mask.sum()) >= 10:
                seed_weight = np.exp(liks_n / 5.0)
                seed_weight /= max(float(seed_weight.sum()), 1e-12)
                level = np.nanmedian(pred_arr[:, eval_mask], axis=1)
                valid = (
                    np.isfinite(level)
                    & np.isfinite(seed_weight)
                    & (seed_weight > 0)
                )
                level = level[valid]
                seed_weight = seed_weight[valid]
                seed_weight /= max(float(seed_weight.sum()), 1e-12)
                if len(level) >= 4:
                    order = np.argsort(level)
                    x = level[order]
                    w = seed_weight[order]
                    cumulative_w = np.cumsum(w)
                    cumulative_x = np.cumsum(w * x)
                    cumulative_x2 = np.cumsum(w * x * x)
                    total_w = float(cumulative_w[-1])
                    total_x = float(cumulative_x[-1])
                    total_x2 = float(cumulative_x2[-1])
                    best = None
                    for cut in range(1, len(x)):
                        left_w = float(cumulative_w[cut - 1])
                        right_w = total_w - left_w
                        if left_w < 0.05 or right_w < 0.05:
                            continue
                        left_x = float(cumulative_x[cut - 1])
                        right_x = total_x - left_x
                        left_sse = float(
                            cumulative_x2[cut - 1]
                            - left_x * left_x / left_w
                        )
                        right_sse = float(
                            total_x2
                            - cumulative_x2[cut - 1]
                            - right_x * right_x / right_w
                        )
                        score = max(0.0, left_sse) + max(0.0, right_sse)
                        if best is None or score < best[0]:
                            best = (
                                score,
                                left_w,
                                right_w,
                                left_x / left_w,
                                right_x / right_w,
                            )
                    if best is not None:
                        _, mass_low, mass_high, center_low, center_high = best
                        branch_stats.update(
                            center_low=float(center_low),
                            center_high=float(center_high),
                            mass_low=float(mass_low),
                            mass_high=float(mass_high),
                            weighted_center=float(
                                np.sum(seed_weight * level)
                            ),
                            eval_rows=np.flatnonzero(eval_mask)
                            .astype(int)
                            .tolist(),
                            seed_count=int(len(level)),
                        )
        except Exception as exc:
            branch_stats['error'] = repr(exc)
    return out
`;

if (!selectorSource.includes(oldFunction)) {
  throw new Error("Could not find the PF ensemble function to replace");
}
selectorSource = selectorSource.replace(oldFunction, newFunction);
setCellSource(11, selectorSource);

let inferenceSource = cellSource(26);
inferenceSource = inferenceSource.replace(
  "rows = []\nbimodal_report_rows = []\n",
  "rows = []\nbimodal_report_rows = []\nPF_SEED_BRANCH_STATS = {}\n",
);
inferenceSource = inferenceSource.replace(
  "    try:\n        pf_by_scale = run_pf_lik_ensemble_scales(hw_te, tw_ref, n_particles=SP45_SELECTOR_N_PARTICLES, n_seeds=int(globals().get('SELECTOR_PF_SEEDS', SP45_SELECTOR_N_SEEDS)))\n",
  "    try:\n        _seed_branch = {}\n        pf_by_scale = run_pf_lik_ensemble_scales(\n            hw_te,\n            tw_ref,\n            n_particles=SP45_SELECTOR_N_PARTICLES,\n            n_seeds=int(globals().get('SELECTOR_PF_SEEDS', SP45_SELECTOR_N_SEEDS)),\n            branch_stats=_seed_branch,\n        )\n        if _seed_branch:\n            PF_SEED_BRANCH_STATS[str(wid)] = _seed_branch\n",
);
if (!inferenceSource.includes("PF_SEED_BRANCH_STATS = {}")) {
  throw new Error("Could not initialize PF seed branch statistics");
}
if (!inferenceSource.includes("branch_stats=_seed_branch")) {
  throw new Error("Could not wire PF seed branch statistics into inference");
}
setCellSource(26, inferenceSource);

notebook.cells.push({
  cell_type: "markdown",
  metadata: {},
  source:
    "## PF-seed posterior branch hedge\n\n" +
    "This final layer uses only the distribution of the existing 128 seeded PF trajectories. " +
    "It applies a bounded midpoint hedge when both posterior branches carry substantial mass. " +
    "Unlike public leaderboard probes, it contains no hardcoded well IDs, hashes, or per-well offsets.\n",
});

notebook.cells.push({
  cell_type: "code",
  execution_count: null,
  metadata: {},
  outputs: [],
  source: `# Hidden-shape-safe PF-seed posterior branch hedge.
import hashlib as _bh_hashlib
import json as _bh_json
from pathlib import Path as _BhPath

import numpy as _bh_np
import pandas as _bh_pd

_BH_STRENGTH = 0.60
_BH_MIN_MASS = 0.25
_BH_SEP_LOW = 4.0
_BH_SEP_HIGH = 40.0
_BH_CAP = 2.0
_BH_WORK = (
    _BhPath('/kaggle/working')
    if _BhPath('/kaggle/working').exists()
    else _BhPath('.')
)
_BH_SUB = _BH_WORK / 'submission.csv'


def _bh_sha256(path):
    digest = _bh_hashlib.sha256()
    with open(path, 'rb') as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b''):
            digest.update(chunk)
    return digest.hexdigest()


def _bh_find_sample():
    candidates = []
    cfg = globals().get('CFG')
    if cfg is not None and hasattr(cfg, 'dataset_path'):
        candidates.append(_BhPath(cfg.dataset_path) / 'sample_submission.csv')
    candidates.extend([
        _BhPath(
            '/kaggle/input/competitions/'
            'rogii-wellbore-geology-prediction/sample_submission.csv'
        ),
        _BhPath(
            '/kaggle/input/rogii-wellbore-geology-prediction/'
            'sample_submission.csv'
        ),
    ])
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise FileNotFoundError('PF branch hedge could not locate sample_submission.csv')


if not _BH_SUB.exists():
    raise FileNotFoundError(f'PF branch hedge missing base submission: {_BH_SUB}')

_sample = _bh_pd.read_csv(_bh_find_sample(), dtype={'id': 'string'})[['id']]
_sub = _bh_pd.read_csv(_BH_SUB, dtype={'id': 'string'})
if list(_sub.columns) != ['id', 'tvt']:
    raise RuntimeError(
        f'PF branch hedge expected id,tvt columns, got {list(_sub.columns)}'
    )
if len(_sub) != len(_sample) or not _sub['id'].equals(_sample['id']):
    raise RuntimeError('PF branch hedge base submission does not match sample order')
if _sub['id'].duplicated().any():
    raise RuntimeError('PF branch hedge base submission has duplicate IDs')
_sub['tvt'] = _bh_pd.to_numeric(_sub['tvt'], errors='coerce')
_base_tvt = _sub['tvt'].to_numpy(dtype=float)
if not _bh_np.isfinite(_base_tvt).all():
    raise RuntimeError('PF branch hedge base submission contains non-finite TVT')

_before_path = _BH_WORK / 'submission_before_pf_seed_branch_hedge.csv'
_sub.to_csv(_before_path, index=False)
_before_sha = _bh_sha256(_before_path)
_well = _sub['id'].astype(str).str.rsplit('_', n=1).str[0]
_row = _bh_pd.to_numeric(
    _sub['id'].astype(str).str.rsplit('_', n=1).str[-1],
    errors='raise',
).astype(int)
_final_tvt = _base_tvt.copy()
_reports = []

for _wid, _stats in sorted(
    (globals().get('PF_SEED_BRANCH_STATS', {}) or {}).items()
):
    _reason = 'not_qualified'
    _shift = 0.0
    _moved = 0
    try:
        _low = float(_stats['center_low'])
        _high = float(_stats['center_high'])
        _mass_low = float(_stats['mass_low'])
        _mass_high = float(_stats['mass_high'])
        _weighted = float(_stats['weighted_center'])
        _separation = abs(_high - _low)
        _minor_mass = min(_mass_low, _mass_high)
        if _minor_mass < _BH_MIN_MASS:
            _reason = 'skip_minor_mass'
        elif not (_BH_SEP_LOW <= _separation <= _BH_SEP_HIGH):
            _reason = 'skip_separation'
        else:
            _midpoint = 0.5 * (_low + _high)
            _shift = float(
                _bh_np.clip(
                    _BH_STRENGTH * (_midpoint - _weighted),
                    -_BH_CAP,
                    _BH_CAP,
                )
            )
            _eval_rows = set(int(value) for value in _stats.get('eval_rows', []))
            _mask = _well.eq(str(_wid)).to_numpy()
            if _eval_rows:
                _mask &= _row.isin(_eval_rows).to_numpy()
            if abs(_shift) >= 0.01 and bool(_mask.any()):
                _final_tvt[_mask] += _shift
                _moved = int(_mask.sum())
                _reason = 'applied'
            else:
                _reason = 'skip_zero_or_missing_rows'
        _reports.append({
            'well': str(_wid),
            'reason': _reason,
            'center_low': _low,
            'center_high': _high,
            'mass_low': _mass_low,
            'mass_high': _mass_high,
            'minor_mass': _minor_mass,
            'separation': _separation,
            'weighted_center': _weighted,
            'shift': _shift,
            'moved_rows': _moved,
            'seed_count': int(_stats.get('seed_count', 0)),
        })
    except Exception as exc:
        _reports.append({
            'well': str(_wid),
            'reason': 'error',
            'error': repr(exc),
            'shift': 0.0,
            'moved_rows': 0,
        })

if not _bh_np.isfinite(_final_tvt).all():
    raise RuntimeError('PF branch hedge produced non-finite TVT')
_final = _sub.copy()
_final['tvt'] = _final_tvt
if not _final['id'].equals(_sample['id']):
    raise RuntimeError('PF branch hedge changed official ID order')
_final.to_csv(_BH_SUB, index=False)

_report = _bh_pd.DataFrame(_reports)
_report.to_csv(_BH_WORK / 'pf_seed_branch_hedge_report.csv', index=False)
_delta = _final_tvt - _base_tvt
_audit = {
    'status': 'ok',
    'rows': int(len(_final)),
    'unique_ids': int(_final['id'].nunique()),
    'finite_tvt': bool(_bh_np.isfinite(_final_tvt).all()),
    'branch_stats_wells': int(len(_reports)),
    'applied_wells': int(
        sum(item.get('reason') == 'applied' for item in _reports)
    ),
    'moved_rows': int(_bh_np.count_nonzero(_delta)),
    'mean_abs_move': float(_bh_np.mean(_bh_np.abs(_delta))),
    'max_abs_move': float(_bh_np.max(_bh_np.abs(_delta))),
    'before_sha256': _before_sha,
    'final_sha256': _bh_sha256(_BH_SUB),
    'parameters': {
        'strength': _BH_STRENGTH,
        'minimum_minor_mass': _BH_MIN_MASS,
        'minimum_separation_ft': _BH_SEP_LOW,
        'maximum_separation_ft': _BH_SEP_HIGH,
        'shift_cap_ft': _BH_CAP,
    },
}
with (_BH_WORK / 'pf_seed_branch_hedge_audit.json').open('w') as handle:
    _bh_json.dump(_audit, handle, indent=2, sort_keys=True)
print('PF seed-branch hedge audit:', _bh_json.dumps(_audit, indent=2), flush=True)
if len(_report):
    print(_report.to_string(index=False), flush=True)
`,
});

for (const cell of notebook.cells) {
  if (cell.cell_type === "code") {
    cell.outputs = [];
    cell.execution_count = null;
  }
}

fs.writeFileSync(targetPath, `${JSON.stringify(notebook, null, 1)}\n`);

const metadata = JSON.parse(fs.readFileSync(sourceMetadataPath, "utf8"));
metadata.id = "dalloliogm/rogii-pf-seed-branch-hedge";
metadata.title = "ROGII PF Seed Branch Hedge";
metadata.code_file = path.basename(targetPath);
fs.writeFileSync(targetMetadataPath, `${JSON.stringify(metadata, null, 2)}\n`);

console.log(targetPath);
console.log(targetMetadataPath);
