#!/usr/bin/env fish

# MK52 magnetic heatbed's drawings and magnet locations are found here:
# https://github.com/prusa3d/Heatbed_MK52_magnetic

# Location of chosen 0,0 coordinate on the heatbed relative to the global 0,0
# coordinate in FreeCAD.
set -l home_offset 21.128181 246.957275

# Everything in the heatbed DXF is scaled way up for some reason.
set -l scale 25.4

# Probe offset (mm) from the nozzle in real units (not in FreeCAD).
set -l probe 36 18

# Margin (mm) around the magnet in real units, any higher and we get overlapping
# regions.
set -l margin 1.145833

# List of all faulty regions (embedded magnet locations) in the imported DXF.
set -l faulty_regions \
   772.449646 -127.000053 1458.249634   38.099949 \
  1597.949585 -127.000053 2283.749756   38.099949 \
  4167.850586 -127.000053 4853.650391   38.099949 \
  4993.350586 -127.000053 5679.150391   38.099949 \
  6165.850098  985.604797 6330.950195 1671.404785 \
  6158.660645 1841.090820 6323.760742 2526.890869 \
  6158.660645 3387.044189 6323.760742 4072.844238 \
  6165.850098 4168.700195 6330.950195 4854.500000 \
  5627.612793 5747.627930 6313.412598 5912.728027 \
  4063.789551 5725.822754 4749.589355 5890.922363 \
  1676.610596 5725.822754 2362.410645 5890.922363 \
    82.995461 5753.100098  768.795471 5918.200195 \
    76.844543 4995.944824  241.944550 5681.745117 \
   114.300003 4216.246094  279.399994 4902.045898 \
   127.839241 3392.641104  292.939240 4078.431152 \
   102.439240 1830.694580  267.539246 2516.494629 \
    95.250000 1085.849976  260.350006 1771.649902 \
   114.30003   311.149963  279.39994   996.949951 \
  3924.000000  -31.750051 3594.100098  654.049927 \
  5120.350586  558.799927 5806.150391  723.899963 \
  5447.398926 2641.599854 5612.499023 3327.399902 \
  4711.818359 5290.003418 5397.618164 5455.103027 \
  2791.736084 5187.950195 2956.836182 5873.750000 \
   781.049988 2641.599854  946.150024 3327.399902 \
  3143.250000 1441.499951 3308.350098 2127.250000 \
  4152.899902 2901.949951 4838.700195 3067.050049 \
  3143.250000 3841.750000 3308.350098 4527.549805 \
  1612.900024 2901.949951 2298.699951 3067.050049

set -l x_start -1
set -l y_start -1
set -l x_end -1
set -l y_end -1
set -l region_counter 1
for coord in $faulty_regions
  if test $x_start -eq -1
    set x_start $coord
  else if test $y_start -eq -1
    set y_start $coord
  else if test $x_end -eq -1
    set x_end $coord
  else if test $y_end -eq -1
    set y_end $coord
  end

  if test $x_start -ne -1 -a $y_start -ne -1 -a $x_end -ne -1 -a $y_end -ne -1
    set x_start (math \($x_start - $home_offset[1]\) / $scale - $probe[1] - $margin)
    set y_start (math \($y_start - $home_offset[2]\) / $scale - $probe[2] - $margin)
    set x_end (math \($x_end - $home_offset[1]\) / $scale - $probe[1] + $margin)
    set y_end (math \($y_end - $home_offset[2]\) / $scale - $probe[2] + $margin)
    printf "faulty_region_%d_min: %f, %f\n" $region_counter $x_start $y_start
    printf "faulty_region_%d_max: %f, %f\n" $region_counter $x_end $y_end
    set region_counter (math "$region_counter + 1")
    set x_start -1
    set y_start -1
    set x_end -1
    set y_end -1
  end
end
