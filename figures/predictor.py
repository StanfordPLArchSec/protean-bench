#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator
import os
import argparse
import sys
from scipy.stats import pearsonr

ourtrack = "ProtTrack"

parser = argparse.ArgumentParser()
parser.add_argument("--annotate", action="append", default=[])
parser.add_argument("--rotate", "-r", type=float, default=40)
parser.add_argument("--width", "-w", type=float, default=7.5/2-0.5)
parser.add_argument("--height", type=float, default=1)
parser.add_argument("--ms", type=int, default=3, help="Marker size")
parser.add_argument("--lw", type=int, default=1, help="Line width")
parser.add_argument("--font-size", type=int, default=7, help="Font size")
parser.add_argument("--no-crop", action="store_true")
parser.add_argument("--output", "-o", required=True)
parser.add_argument("--rate-csv", required=True)
parser.add_argument("--runtime-csv", required=True)
args = parser.parse_args()

plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams["font.size"] = args.font_size

# Load and parse predictor mispredict rate (tab-separated)
mispredict_df = pd.read_csv(args.rate_csv)
runtime_df = pd.read_csv(args.runtime_csv)

# Convert percentage strings to float
def parse_percent_col(col):
    return col.str.rstrip('%').astype(float) / 100.0

# Process data
mispredict_rates = mispredict_df.iloc[0].apply(lambda x: x * 100)
runtime_overheads = runtime_df.iloc[0].apply(lambda x: (x - 1) * 100)

# Format x-axis labels
predictor_sizes = mispredict_df.columns.to_list()
predictor_labels = ['∞' if x == 'infinite' else x for x in predictor_sizes]
x_vals = list(range(len(predictor_labels)))

# Plotting
fig, ax1 = plt.subplots(figsize=(args.width, args.height))

# Mispredict rate line
# ax1.set_xlabel("access predictor size")
ax1.set_ylabel("access mispredict\nrate (%)", color='tab:blue')
ax1.plot(x_vals, mispredict_rates, color='tab:blue', marker='o', ms=args.ms, lw=args.lw, label='Mispredict rate')
ax1.tick_params(axis='y', labelcolor='tab:blue')
# ax1.set_ylim([ymin, ymax])
if False:
    for i, val in enumerate(mispredict_rates):
        offs = 5
        if i == 0:
            offs = -offs - 10
        ax1.annotate(f"{val:.1f}%", (i,val), textcoords="offset points", xytext=(0,offs), ha="center", color="tab:blue")

# Runtime overhead line
ax2 = ax1.twinx()
ax2.set_ylabel(ourtrack + " runtime\noverhead (%)", color='tab:orange')
ax2.plot(x_vals, runtime_overheads, color='tab:orange', marker='x', ms=args.ms, lw=args.lw, label='runtime\noverhead')
ax2.tick_params(axis='y', labelcolor='tab:orange')
# ax2.set_ylim([ymin, ymax])
if False:
    for i, val in enumerate(runtime_overheads):
        offs = 15
        if i == 0:
            offs = -offs - 10
        ax2.annotate(f"{val:.1f}%", (i, val), textcoords="offset points", xytext=(0, offs), ha='center', color='tab:orange')

for pred_size in args.annotate:
    i = predictor_sizes.index(pred_size)
    runtime_val = runtime_overheads[i]
    mispred_val = mispredict_rates[i]
    ax1.annotate(f"{mispred_val:.1f}%", (i, mispred_val), textcoords="offset points", xytext=(0, 5), ha="left", color="tab:blue")
    ax2.annotate(f"{runtime_val:.1f}%", (i, runtime_val), textcoords="offset points", xytext=(0, 12), ha="left", color="tab:orange")

# Combined legend
lines_1, labels_1 = ax1.get_legend_handles_labels()
lines_2, labels_2 = ax2.get_legend_handles_labels()
if False:
    ax1.legend(lines_1 + lines_2, labels_1 + labels_2, loc='upper right')


ax1.set_ylim([0, 20])
ax2.set_ylim([25, 35])
ax1.yaxis.set_major_locator(MultipleLocator(4))
ax2.yaxis.set_major_locator(MultipleLocator(2))
print(ax2.get_ylim()) # 25, 45

for ax in [ax1, ax2]:
    # ax.set_yscale("log")
    ax.set_xticks(x_vals[::1])
    ax.set_xticklabels(predictor_labels[::1])
    ax.set_xlim(x_vals[0], x_vals[-1])
    for label in ax.get_xticklabels():
        label.set_rotation(args.rotate)
        label.set_horizontalalignment("right")
    pass

for label in ax1.get_xticklabels():
    if label.get_text() == "1024":
        label.set_fontweight("bold")

plt.setp(ax1.get_xticklabels(), y=0.075)

# plt.title("MierosTrack: Mispredict Rate and Runtime Overhead vs. Predictor Size")
fig.tight_layout()
pdf = args.output
plt.savefig(pdf)
if not args.no_crop:
    os.system(f"pdf-crop-margins -p10 --modifyOriginal {pdf}")
# plt.show()
# os.system(f"open {pdf}")




r, p_value = pearsonr(mispredict_rates, runtime_overheads)
print(f"Pearson r = {r:.3f}, p = {p_value:.3g}")
