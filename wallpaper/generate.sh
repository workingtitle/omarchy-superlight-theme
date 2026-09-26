#!/bin/bash
# Generates the Superdark and Superlight wallpapers from scratch; no source image is used.
#
# A dusk sky is built from a vertical base gradient plus soft, alpha-masked colour
# fields: a cool haze, a warm grey, a slanted peach horizon with a brighter core,
# and darker edges. It is rendered smooth in floating point at 960x600, upscaled to
# 3840x2400, then dithered with fine film grain so the gradient shows no banding.
#
# Requires ImageMagick 7 (HDRI build). Usage: ./generate.sh [output-dir]
set -euo pipefail

OUT=${1:-.}
W=3840 H=2400
GRAIN=0.3094

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# blob <name> <w> <h> <rotation> <color> <opacity> <falloff>: soft elliptical colour field
blob() {
  magick -size 1000x1000 radial-gradient:white-black -evaluate pow "$7" -evaluate multiply "$6" \
    -filter Cubic -resize "${2}x${3}!" -background black -rotate "$4" \
    \( +clone -fill "$5" -colorize 100 \) +swap -alpha off -compose copyalpha -composite "$tmp/$1.miff"
}

# sky <name> <5 base stops top->bottom> <haze> <horizon> <core> <corner> <edge> <warm> <rust>
sky() {
  local name=$1; shift
  local c=("$@")
  blob haze 900 520   0 "${c[5]}"  0.85 1.2
  blob hor 1800 560 -16 "${c[6]}"  0.95 1.3
  blob hot  760 440 -16 "${c[7]}"  0.7  1.6
  blob pl   700 420   0 "${c[8]}"  0.75 1.2
  blob lft  560 900   0 "${c[9]}"  0.9  1.2
  blob warm 800 560   0 "${c[10]}" 0.7  1.3
  blob rust 700 460 -16 "${c[11]}" 0.85 1.4
  magick \( xc:"${c[0]}" xc:"${c[1]}" xc:"${c[2]}" xc:"${c[3]}" xc:"${c[4]}" -append \) \
    -filter Cubic -resize 1x600! -scale 960x600! \
    "$tmp/lft.miff"  -geometry -250-280 -compose over -composite \
    "$tmp/warm.miff" -geometry +460+20  -compose over -composite \
    "$tmp/haze.miff" -geometry -150-120 -compose over -composite \
    "$tmp/hor.miff"  -geometry -322-5   -compose over -composite \
    "$tmp/hot.miff"  -geometry +475+135 -compose over -composite \
    "$tmp/pl.miff"   -geometry -330+390 -compose over -composite \
    "$tmp/rust.miff" -geometry +560+300 -compose over -composite \
    -blur 0x18 +repage \
    -filter Lanczos -resize "${W}x${H}!" \
    -attenuate "$GRAIN" +noise Gaussian -depth 8 "$OUT/$name.png"
}

#               base stops                                                 haze      horizon   core      corner    edge      warm      rust
sky superdark  '#213540' '#384e5c' '#465b6a' '#42525f' '#3e4048'           '#5a6f80' '#d27d54' '#e39266' '#282b35' '#1f3945' '#707079' '#ae5f40'
sky superlight '#526d7b' '#748f9d' '#8ea1ae' '#8e9aa3' '#7f7c82'           '#9fb1bf' '#f0b08c' '#f6c3a2' '#6d6a75' '#4f7282' '#b9b6ba' '#e09a78'
