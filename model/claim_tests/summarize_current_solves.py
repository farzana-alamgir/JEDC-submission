"""Export compact convergence evidence without altering any solver inputs."""
import csv
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'results/current_branch_claims'


def main():
    summaries=[]
    for stage,relaxation in [('',1.),('damped',.2),('damped005',.05)]:
        for economy in ['bm','mp']:
            directory=OUT/stage/'raw'/economy
            path=directory/'convergence.csv'
            if not path.exists():
                continue
            with path.open() as f:
                rows=list(csv.DictReader(f))
            if not rows:
                continue
            # Keep the complete compact iteration history outside the ignored raw folder.
            label=stage or 'original_updates'
            (OUT/f'{label}_{economy}_convergence.csv').write_text(path.read_text())
            latest=rows[-1]
            pricing=directory/'pricing_residual.csv'
            raw_residual=None
            if pricing.exists():
                lines=pricing.read_text().splitlines()
                if lines:
                    raw_residual=float(lines[-1].split(',')[1])
                (OUT/f'{label}_{economy}_pricing_residual.csv').write_text(pricing.read_text())
            status=directory/'solve_status.txt'
            manifest=json.loads((OUT/stage/(economy+'_manifest.json')).read_text())
            assert hashlib.sha256((OUT/stage/'branch_source.f90').read_bytes()).hexdigest()==manifest['source_sha256']
            summaries.append(dict(update_method=label,economy=economy,relaxation=relaxation,
                iterations=int(latest['iteration']),
                value_change=float(latest['value_change']),paid_price_change=float(latest['paid_price_change']),
                default_changes=int(latest['default_changes']),debt_choice_changes=int(latest['debt_choice_changes']),
                raw_price_schedule_residual=raw_residual,
                status=status.read_text().strip() if status.exists() else 'RUNNING',
                tolerance=manifest['tolerance'],source_commit=manifest['commit'],
                source_sha256=manifest['source_sha256']))
    if summaries:
        with (OUT/'solve_diagnostics.csv').open('w',newline='') as f:
            writer=csv.DictWriter(f,fieldnames=list(summaries[0]))
            writer.writeheader();writer.writerows(summaries)
    print(json.dumps(summaries,indent=2))


if __name__=='__main__':
    main()
