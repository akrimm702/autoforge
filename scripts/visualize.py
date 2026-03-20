#!/usr/bin/env python3
"""
AutoForge Visualizer v2
Generates rich progress charts from results.tsv with trend lines,
regression markers, eval category breakdowns, and multi-run comparisons.

Usage:
  python3 visualize.py [results.tsv] [--output ./results/progress.png] [--title "Skill Name"]
  python3 visualize.py results1.tsv results2.tsv --compare --output comparison.png
  python3 visualize.py results.tsv --breakdown --output breakdown.png
"""

import sys
import csv
import argparse
from pathlib import Path
from typing import List, Dict, Optional


def read_tsv(path: str) -> List[Dict]:
    """Read TSV file, return list of row dicts."""
    rows = []
    with open(path, newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            rows.append(row)
    return rows


def parse_rate(val: str) -> float:
    """Parse '83%' or '0.83' to float 0-100."""
    val = val.strip().rstrip("%")
    try:
        v = float(val)
        return v * 100 if v <= 1.0 else v
    except ValueError:
        return 0.0


def ascii_chart(rows: List[Dict], title: str) -> str:
    """Generate ASCII fallback chart."""
    lines = [f"\n📊 {title}", "─" * 60]

    iterations = list(range(1, len(rows) + 1))
    pass_rates = [parse_rate(r.get("pass_rate", "0")) for r in rows]
    statuses = [r.get("status", "keep") for r in rows]
    keep_set = {"keep", "improved", "retained", "baseline", "best"}

    best_rate = max(pass_rates) if pass_rates else 0
    best_iter = pass_rates.index(best_rate) + 1 if pass_rates else 0

    for x, y, s in zip(iterations, pass_rates, statuses):
        bar = "█" * int(y / 5) + "░" * (20 - int(y / 5))
        icon = "✅" if s in keep_set else ("⬇️" if s == "regression" else "❌")
        # Trend indicator
        trend = ""
        if x > 1:
            prev = pass_rates[x - 2]
            if y > prev:
                trend = " ↑"
            elif y < prev:
                trend = " ↓"
        lines.append(f"  Iter {x:2d} {icon}  {bar} {y:5.1f}%{trend}")

    lines.append("─" * 60)
    lines.append(f"  🏆 Best: {best_rate:.0f}% @ Iter {best_iter}")

    # Stats
    improved = sum(1 for s in statuses if s == "improved")
    discarded = sum(1 for s in statuses if s == "discard")
    delta = best_rate - pass_rates[0] if pass_rates else 0
    lines.append(f"  ✅ {improved} improved  ❌ {discarded} discarded  📈 Δ+{delta:.0f}%")
    lines.append("─" * 60)
    lines.append("(matplotlib not installed — ASCII fallback)\n")
    return "\n".join(lines)


def matplotlib_chart(rows: List[Dict], title: str, output: str) -> str:
    """Generate rich matplotlib chart."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    import numpy as np

    iterations = list(range(1, len(rows) + 1))
    pass_rates = [parse_rate(r.get("pass_rate", "0")) for r in rows]
    statuses = [r.get("status", "keep") for r in rows]
    changes = [r.get("change_description", "") for r in rows]

    keep_set = {"keep", "improved", "retained", "baseline", "best"}

    fig, ax = plt.subplots(figsize=(12, 6))
    fig.patch.set_facecolor("#0d1117")
    ax.set_facecolor("#161b22")

    # Main line with gradient effect
    ax.plot(iterations, pass_rates, color="#58a6ff", linewidth=2.5, zorder=3,
            marker="o", markersize=6, markerfacecolor="#58a6ff", markeredgecolor="#0d1117")

    # Fill area under curve
    ax.fill_between(iterations, pass_rates, alpha=0.15, color="#58a6ff")

    # Trend line (linear regression)
    if len(iterations) >= 3:
        z = np.polyfit(iterations, pass_rates, 1)
        p = np.poly1d(z)
        trend_x = np.linspace(1, len(iterations), 100)
        ax.plot(trend_x, p(trend_x), color="#f0883e", linewidth=1.5,
                linestyle="--", alpha=0.7, label=f"Trend ({z[0]:+.1f}%/iter)")

    # Color points by status
    for x, y, status in zip(iterations, pass_rates, statuses):
        if status == "discard":
            color, marker = "#f85149", "X"
        elif status == "regression":
            color, marker = "#da3633", "v"
        elif status == "baseline":
            color, marker = "#8b949e", "D"
        elif status == "improved":
            color, marker = "#3fb950", "^"
        elif status == "retained":
            color, marker = "#58a6ff", "s"
        else:
            color, marker = "#58a6ff", "o"
        ax.scatter(x, y, color=color, s=120, zorder=4, marker=marker, edgecolors="#0d1117", linewidths=1)

    # Regression markers (v2)
    for i in range(1, len(pass_rates)):
        if pass_rates[i] < pass_rates[i - 1] and statuses[i] != "baseline":
            ax.annotate("", xy=(iterations[i], pass_rates[i]),
                        xytext=(iterations[i], pass_rates[i - 1]),
                        arrowprops=dict(arrowstyle="->", color="#f85149", lw=1.5, alpha=0.6))

    # Threshold lines
    ax.axhline(y=100, color="#3fb950", linestyle=":", linewidth=1, alpha=0.3)
    ax.axhline(y=80, color="#f0883e", linestyle=":", linewidth=1, alpha=0.3)

    # Right-side labels for thresholds
    ax.text(len(iterations) + 0.3, 100, "100%", color="#3fb950", fontsize=8, alpha=0.6, va="center")
    ax.text(len(iterations) + 0.3, 80, "80%", color="#f0883e", fontsize=8, alpha=0.6, va="center")

    # Axes styling
    ax.set_xlabel("Iteration", color="#8b949e", fontsize=11)
    ax.set_ylabel("Pass Rate (%)", color="#8b949e", fontsize=11)
    ax.set_title(title, color="#f0f6fc", fontsize=14, fontweight="bold", pad=15)
    ax.set_ylim(0, 110)
    ax.set_xlim(0.5, len(iterations) + 0.5)
    ax.set_xticks(iterations)
    ax.tick_params(colors="#8b949e")
    for spine in ax.spines.values():
        spine.set_edgecolor("#30363d")
    ax.grid(axis="y", color="#21262d", linewidth=0.5)

    # Legend
    legend_items = [
        mpatches.Patch(color="#3fb950", label="Improved"),
        mpatches.Patch(color="#58a6ff", label="Retained"),
        mpatches.Patch(color="#f85149", label="Discard"),
        mpatches.Patch(color="#8b949e", label="Baseline"),
    ]
    if len(iterations) >= 3 and 'z' in dir():
        legend_items.append(mpatches.Patch(color="#f0883e", label=f"Trend ({z[0]:+.1f}%/iter)"))
    ax.legend(handles=legend_items, facecolor="#161b22", labelcolor="#8b949e",
              framealpha=0.9, edgecolor="#30363d", fontsize=9)

    # Annotate best
    best_idx = pass_rates.index(max(pass_rates))
    ax.annotate(f"Best: {max(pass_rates):.0f}%",
                xy=(iterations[best_idx], pass_rates[best_idx]),
                xytext=(iterations[best_idx] + 0.5, min(pass_rates[best_idx] + 8, 108)),
                color="#f0f6fc", fontsize=11, fontweight="bold",
                arrowprops=dict(arrowstyle="->", color="#f0f6fc", lw=1.2))

    # Stats box (v2)
    delta = max(pass_rates) - pass_rates[0]
    improved = sum(1 for s in statuses if s == "improved")
    discarded = sum(1 for s in statuses if s == "discard")
    stats_text = (f"Δ+{delta:.0f}%  |  {improved} improved  |  "
                  f"{discarded} discarded  |  {len(iterations)} iterations")
    fig.text(0.5, 0.02, stats_text, ha="center", color="#8b949e", fontsize=9,
             fontstyle="italic")

    # Save
    Path(output).parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout(rect=[0, 0.05, 1, 1])
    plt.savefig(output, dpi=150, bbox_inches="tight", facecolor=fig.get_facecolor())
    plt.close()
    print(f"Chart saved: {output}")
    return output


def comparison_chart(files: List[str], title: str, output: str) -> str:
    """Generate multi-run comparison chart (v2)."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(12, 6))
    fig.patch.set_facecolor("#0d1117")
    ax.set_facecolor("#161b22")

    colors = ["#58a6ff", "#3fb950", "#f0883e", "#bc8cff", "#f778ba"]
    max_iter = 0

    for idx, fpath in enumerate(files):
        rows = read_tsv(fpath)
        if not rows:
            continue
        iterations = list(range(1, len(rows) + 1))
        rates = [parse_rate(r.get("pass_rate", "0")) for r in rows]
        color = colors[idx % len(colors)]
        label = Path(fpath).stem.replace("-results", "")
        ax.plot(iterations, rates, color=color, linewidth=2, marker="o",
                markersize=5, label=label)
        ax.fill_between(iterations, rates, alpha=0.08, color=color)
        max_iter = max(max_iter, len(iterations))

    ax.set_xlabel("Iteration", color="#8b949e", fontsize=11)
    ax.set_ylabel("Pass Rate (%)", color="#8b949e", fontsize=11)
    ax.set_title(title, color="#f0f6fc", fontsize=14, fontweight="bold", pad=15)
    ax.set_ylim(0, 110)
    ax.tick_params(colors="#8b949e")
    for spine in ax.spines.values():
        spine.set_edgecolor("#30363d")
    ax.grid(axis="y", color="#21262d", linewidth=0.5)
    ax.legend(facecolor="#161b22", labelcolor="#8b949e", framealpha=0.9,
              edgecolor="#30363d", fontsize=9)

    Path(output).parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(output, dpi=150, bbox_inches="tight", facecolor=fig.get_facecolor())
    plt.close()
    print(f"Comparison chart saved: {output}")
    return output


def main():
    parser = argparse.ArgumentParser(description="AutoForge Visualizer v2")
    parser.add_argument("results", nargs="+", help="Path(s) to results TSV file(s)")
    parser.add_argument("--output", default="./results/af-progress.png", help="Output PNG path")
    parser.add_argument("--title", default="AutoForge Progress", help="Chart title")
    parser.add_argument("--compare", action="store_true", help="Multi-run comparison mode")
    parser.add_argument("--breakdown", action="store_true", help="Show eval category breakdown")
    args = parser.parse_args()

    # Multi-run comparison
    if args.compare and len(args.results) > 1:
        try:
            comparison_chart(args.results, args.title, args.output)
        except ImportError:
            print("matplotlib required for comparison charts")
            sys.exit(1)
        return

    # Single run
    rows = read_tsv(args.results[0])
    if not rows:
        print("No data in results file.")
        sys.exit(1)

    try:
        matplotlib_chart(rows, args.title, args.output)
    except ImportError:
        print(ascii_chart(rows, args.title))


if __name__ == "__main__":
    main()
