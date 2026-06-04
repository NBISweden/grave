#!/usr/bin/env bash
# accuracy.sh
# Usage:   accuracy.sh <input.bed> [overlap_threshold] [output_format]
# Example: accuracy.sh sample.bed 0.9 table

INPUT="${1:?Error: please supply a BED file}"
THRESHOLD="${2:-0.9}"      # fraction of true read length that must overlap
FORMAT="${3:-report}"      # output format: 'report' (default) or 'table'

awk -v thr="$THRESHOLD" -v fmt="$FORMAT" '
BEGIN {
    total = 0; unmapped = 0; pfail = 0
    wrong_chr = 0; no_ovlp = 0; partial = 0; accurate = 0
    sum_err = 0; n_err = 0
}
{
    total++

    # ── Mapped position: 0-based half-open BED ──────────────────────────
    map_chr   = $1
    map_start = int($2)
    map_end   = int($3)

    if (map_chr == "*" || map_chr == ".") { unmapped++; next }

    # ── True source from read name (col 4) ──────────────────────────────
    # Pattern: ...CONTIG:start-end_...  (1-based coords embedded in name)
    # e.g. T0_RID4246203_S1_CBDTXI010000012.1:1234643-1234712_length:70_mod0000
    # NOTE: assumes contig name itself contains no underscores
    if (match($4, /[A-Za-z0-9.]+:[0-9]+-[0-9]+/)) {
        src = substr($4, RSTART, RLENGTH)
        split(src, a, ":")
        true_chr   = a[1]
        split(a[2], b, "-")
        true_start = int(b[1]) - 1   # 1-based in name → 0-based BED
        true_end   = int(b[2])
        true_len   = true_end - true_start
    } else {
        pfail++
        print "WARN: cannot parse true source from: " $4 > "/dev/stderr"
        next
    }

    # ── Classify ────────────────────────────────────────────────────────

    if (map_chr != true_chr) { wrong_chr++; next }

    ov_s = (map_start > true_start) ? map_start : true_start
    ov_e = (map_end   < true_end)   ? map_end   : true_end
    ov_l = ov_e - ov_s

    if (ov_l <= 0) { no_ovlp++; next }

    frac = ov_l / true_len          # fraction of true read length covered

    err = map_start - true_start    # signed start-position error
    if (err < 0) err = -err
    sum_err += err
    n_err++

    if (frac >= thr) accurate++
    else             partial++
}
END {
    d = (total > 0) ? total : 1
    if (fmt == "table") {
        printf "file\tthreshold_pct\ttotal_lifted\tunmapped_n\tunmapped_pct\tparse_fail_n\tparse_fail_pct\twrong_contig_n\twrong_contig_pct\tcorrect_tig_no_overlap_n\tcorrect_tig_no_overlap_pct\tsub_threshold_n\tsub_threshold_pct\taccurate_n\taccurate_pct\tmean_start_err_bp\n"
        printf "%s\t%.0f\t%d\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\t%.1f\n", \
            FILENAME, thr*100, total, \
            unmapped,  unmapped/d*100,  \
            pfail,     pfail/d*100,     \
            wrong_chr, wrong_chr/d*100, \
            no_ovlp,   no_ovlp/d*100,   \
            partial,   partial/d*100,   \
            accurate,  accurate/d*100,  \
            (n_err > 0 ? sum_err/n_err : 0)
    } else {
        printf "\n=== Mapping Accuracy ===\n"
        printf "File                              : %s\n",   FILENAME
        printf "Overlap threshold                 : %.0f%%\n\n", thr*100
        printf "Total reads                       : %d\n",       total
        printf "  Unmapped (chr * or .)           : %d\t(%.2f%%)\n", unmapped,  unmapped/d*100
        printf "  Read name parse failures        : %d\t(%.2f%%)\n", pfail,     pfail/d*100
        printf "  Wrong contig                    : %d\t(%.2f%%)\n", wrong_chr, wrong_chr/d*100
        printf "  Correct contig, no overlap      : %d\t(%.2f%%)\n", no_ovlp,   no_ovlp/d*100
        printf "  Partial overlap  (<%.0f%%)      : %d\t(%.2f%%)\n", thr*100,   partial,   partial/d*100
        printf "  Accurately mapped (>=%.0f%%)    : %d\t(%.2f%%)\n", thr*100,   accurate,  accurate/d*100
        if (n_err > 0)
            printf "\nMean start error (overlapping reads) : %.1f bp\n", sum_err/n_err
    }
}
' "$INPUT"