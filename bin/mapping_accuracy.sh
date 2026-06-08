#!/usr/bin/env bash
# accuracy.sh
# Usage:   accuracy.sh <input.bed> [overlap_threshold] [max_left_overhang] [max_right_overhang] [output_format]
# Example: accuracy.sh sample.bed 0.0 2 2 report
# Note: overhang thresholds allow small alignment boundary slop (in bp). Set to 0 for strict mode.

INPUT="${1:?Error: please supply a BED file}"
THRESHOLD="${2:-0.0}"           # fraction of true read length that must overlap (default: any overlap)
MAX_LEFT="${3:-3}"              # max bp overhang on 5' side (0 = strict)
MAX_RIGHT="${4:-3}"             # max bp overhang on 3' side (0 = strict)
FORMAT="${5:-report}"           # output format: 'report' (default) or 'table'

awk -v thr="$THRESHOLD" -v max_left="$MAX_LEFT" -v max_right="$MAX_RIGHT" -v fmt="$FORMAT" '
BEGIN {
    total = 0; unmapped = 0; pfail = 0
    wrong_chr = 0; no_ovlp = 0; partial = 0; accurate = 0
    overhang_left = 0; overhang_right = 0; overhang_either = 0; overhang_both = 0
    sum_err = 0; n_err = 0
    sum_left_overhang = 0; sum_right_overhang = 0
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

    # ── Detect overhang: alignment extends beyond true region ────────
    left_overhang  = (map_start < true_start) ? (true_start - map_start) : 0
    right_overhang = (map_end > true_end)     ? (map_end - true_end)     : 0

    if (left_overhang > 0 || right_overhang > 0) {
        # Only count overhangs that EXCEED tolerance (these are violations)
        if (left_overhang > max_left || right_overhang > max_right) {
            overhang_either++
            # Accumulate only the excessive amount
            if (left_overhang > max_left) sum_left_overhang += (left_overhang - max_left)
            if (right_overhang > max_right) sum_right_overhang += (right_overhang - max_right)

            if (left_overhang > max_left && right_overhang > max_right) {
                overhang_both++
            } else if (left_overhang > max_left) {
                overhang_left++
            } else {
                overhang_right++
            }
        }
    }

    # Classify: accurate if coverage meets threshold AND overhang within tolerance
    if (frac >= thr && left_overhang <= max_left && right_overhang <= max_right) {
        accurate++
    } else {
        partial++
    }
}
END {
    d = (total > 0) ? total : 1
    if (fmt == "table") {
        printf "file\tthreshold_pct\ttotal\tunmapped_n\tunmapped_pct\tparse_fail_n\tparse_fail_pct\twrong_contig_n\twrong_contig_pct\tno_overlap_n\tno_overlap_pct\tpartial_n\tpartial_pct\taccurate_n\taccurate_pct\toverhang_any_n\toverhang_any_pct\toverhang_left_n\toverhang_right_n\toverhang_both_n\tmean_start_err_bp\n"
        printf "%s\t%.0f\t%d\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\t%d\t%d\t%d\t%.1f\n", \
            FILENAME, thr*100, total, \
            unmapped,  unmapped/d*100,  \
            pfail,     pfail/d*100,     \
            wrong_chr, wrong_chr/d*100, \
            no_ovlp,   no_ovlp/d*100,   \
            partial,   partial/d*100,   \
            accurate,  accurate/d*100,  \
            overhang_either, overhang_either/d*100, \
            overhang_left, overhang_right, overhang_both, \
            (n_err > 0 ? sum_err/n_err : 0)
    } else {
        printf "\n=== Mapping Accuracy ===\n"
        printf "File                              : %s\n",   FILENAME
        printf "Overlap threshold                 : %.0f%%\n", thr*100
        printf "Overhang tolerance (L/R)          : %d bp / %d bp\n\n", max_left, max_right
        printf "Total reads                       : %d\n",       total
        printf "  Unmapped (chr * or .)           : %d\t(%.2f%%)\n", unmapped,  unmapped/d*100
        printf "  Read name parse failures        : %d\t(%.2f%%)\n", pfail,     pfail/d*100
        printf "  Wrong contig                    : %d\t(%.2f%%)\n", wrong_chr, wrong_chr/d*100
        printf "  Correct contig, no overlap      : %d\t(%.2f%%)\n", no_ovlp,   no_ovlp/d*100
        printf "  Partial/inaccurate              : %d\t(%.2f%%)\n", partial,   partial/d*100
        printf "  Accurately mapped               : %d\t(%.2f%%)\n", accurate,  accurate/d*100
        if (n_err > 0)
            printf "\nMean start error (overlapping reads) : %.1f bp\n", sum_err/n_err
        printf "\n=== Boundary Violations (Overhang) ===\n"
        printf "Reads exceeding overhang limits   : %d\t(%.2f%%)\n", overhang_either, overhang_either/d*100
        printf "  Left overhang only              : %d\t(%.2f%%)\t mean excess: %.1f bp\n", overhang_left, overhang_left/d*100, (overhang_left > 0 ? sum_left_overhang/overhang_left : 0)
        printf "  Right overhang only             : %d\t(%.2f%%)\t mean excess: %.1f bp\n", overhang_right, overhang_right/d*100, (overhang_right > 0 ? sum_right_overhang/overhang_right : 0)
        printf "  Both sides exceed limits        : %d\t(%.2f%%)\n", overhang_both, overhang_both/d*100
    }
}
' "$INPUT"