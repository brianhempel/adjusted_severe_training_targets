import Printf

const data_dir = joinpath(@__DIR__, "..", "spc_realtime_mesoanalysis_mucape")
const out_dir  = joinpath(@__DIR__)

function run_gempak_prog(prog_name; params...)
  prog = open(`$prog_name`, "r+")

  for (K, v) in params
    if string(K) == "GDFILE"
      v = relpath(v) # Absolute paths can be toooo long
    end
    println(prog, "$K=$v")
  end

  out = lowercase(basename(tempname()))
  println(prog, "OUTPUT=F/$out")
  println(prog, "r")
  println(prog, "")
  println(prog, "exit")
  close(prog.in)
  wait(prog)
  out_str = read(out, String)
  rm(out)
  out_str
end

function times(fname)
  out_str = run_gempak_prog(
    "gdinfo";
    GDFILE  = fname,
    GFUNC   = "MUCP",
    GDATTIM = "ALL",
    GLEVEL  = 0,
    GVCORD  = "NONE",
  )

  #  GRID FILE: data_2003-2021/spc_realtime_mesoanalysis_mucape/sfcoa.201001.gem
  #
  #  GRID NAVIGATION:
  #      PROJECTION:          LCC
  #      ANGLES:                25.0   -95.0    25.0
  #      GRID SIZE:              151     113
  #      LL CORNER:            16.2810 -126.1380
  #      UR CORNER:            55.4814  -57.3806
  #
  #  GRID ANALYSIS BLOCK:
  #      ANALYSIS TYPE:        BARNES
  #      DELTAN:               4.000
  #      DELTAX:           -9999.000
  #      DELTAY:           -9999.000
  #      GRID AREA:            15.00 -141.00   59.00  -56.00
  #      EXTEND AREA:          14.00 -142.00   60.00  -55.00
  #      DATA AREA:            14.00 -142.00   60.00  -55.00
  #
  #  Number of grids in file:   744
  #
  #  Maximum number of grids in file:   1000
  #
  #   NUM       TIME1              TIME2           LEVL1 LEVL2  VCORD PARM
  #     1     100101/0000                              0         NONE MUCP
  #     2     100101/0100                              0         NONE MUCP
  #     3     100101/0200                              0         NONE MUCP
  #     4     100101/0300                              0         NONE MUCP
  #     5     100101/0400                              0         NONE MUCP
  #     6     100101/0500                              0         NONE MUCP
  #     7     100101/0600                              0         NONE MUCP
  #     8     100101/0700                              0         NONE MUCP
  #     9     100101/0800                              0         NONE MUCP
  #    10     100101/0900                              0         NONE MUCP
  #    11     100101/1000                              0         NONE MUCP

  lines = split(strip(split(out_str, r"PARM\n\s+")[2]), r"\s*\n\s*")
  time_strs = map(l -> split(l, r"\s+")[2], lines)
  time_strs
end


import DelimitedFiles

const grid_236 = DelimitedFiles.readdlm(joinpath(@__DIR__, "..", "..", "grid_236.csv"), ',', String; header = true)[1]


# Returns array of (lat_str, lon_str, val_str) in the same order as the points in grid_236.csv
function duuuuuump(fname, time_str)
  out_str = run_gempak_prog(
    "gdlist";
    GDFILE  = fname,
    SCALE   = 0,
    GFUNC   = "MUCP",
    GDATTIM = time_str, # "100131/1300"
    GLEVEL  = 0,
    GVCORD  = "NONE",
    GAREA   = "GRID",
    PROJ    = ""
  )

  #
  #
  # Grid file: data_2003-2021/spc_realtime_mesoanalysis_mucape/sfcoa.201001.gem
  # GRID IDENTIFIER:
  #    TIME1             TIME2         LEVL1 LEVL2   VCORD PARM
  # 100101/0000                             0          NONE MUCP
  # AREA: GRID                                                GRID SIZE:   151  113
  # COLUMNS:     1  151     ROWS:     1  113
  #
  # Scale factor: 10** 0
  #
  #
  # COLUMN:      1        2        3        4        5        6        7        8
  #              9       10       11       12       13       14       15       16
  #             17       18       19       20       21       22       23       24
  #             25       26       27       28       29       30       31       32
  #             33       34       35       36       37       38       39       40
  #             41       42       43       44       45       46       47       48
  #             49       50       51       52       53       54       55       56
  #             57       58       59       60       61       62       63       64
  #             65       66       67       68       69       70       71       72
  #             73       74       75       76       77       78       79       80
  #             81       82       83       84       85       86       87       88
  #             89       90       91       92       93       94       95       96
  #             97       98       99      100      101      102      103      104
  #            105      106      107      108      109      110      111      112
  #            113      114      115      116      117      118      119      120
  #            121      122      123      124      125      126      127      128
  #            129      130      131      132      133      134      135      136
  #            137      138      139      140      141      142      143      144
  #            145      146      147      148      149      150      151
  # ROW113  -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  # ROW112  -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00
  #         -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00

  row_strs = reverse(split(strip(replace(out_str, r"\A[\S\s]+?\s*\n\s*ROW\s*\d+\s*" => "")), r"\s*\n\s*ROW\s*\d+\s*"))

  cells = map(split, row_strs)

  # nrows = length(cells)
  # ncols = length(cells[1])

  # out_arr = Array{String,2}(undef, (nrows, ncols))

  # for i in 1:nrows
  #   for j in 1:ncols
  #     out_arr[i,j] = cells[i][j]
  #   end
  # end

  out_vec = []

  for i in 1:size(grid_236,1)
    x_str, y_str, lat_str, lon_str = @view grid_236[i, :]
    i, j = parse(Int, x_str), parse(Int, y_str)
    push!(out_vec, (lat_str, lon_str, cells[j][i]))
  end

  out_vec
end


for fname in readdir(data_dir)
  if endswith(fname, ".gem.gz")
    path = joinpath(data_dir, fname)
    run(`gunzip --keep --force $path`)
    path = replace(path, r"\.gz$" => "")

    for time_str in times(path)
      vals = duuuuuump(path, time_str)
      mucape_mask = map(r -> parse(Float32, r[3]), vals) .>= 1

      # "210501/0000"
      year  = parse(Int64, time_str[1:2]) + 2000
      month = parse(Int64, time_str[3:4])
      day   = parse(Int64, time_str[5:6])
      hour  = parse(Int64, time_str[8:9])

      yyyymm        = Printf.@sprintf "%04d%02d"            year month
      yyyymmdd_hh00 = Printf.@sprintf "%04d%02d%02d_%02d00" year month day hour

      out_path = yyyymmdd_hh00 * ".bits"

      mkpath(joinpath(out_dir, yyyymm))
      write(out_path, mucape_mask)
    end

    rm(path)
  end
end

# import PNGFiles

# function png(path, vals, w, h; val_to_color=PNGFiles.Gray)
#   vals = reshape(vals, w, h)'[:,:]
#   # Now flip vertically
#   for j in 1:(h ÷ 2)
#     row = vals[j,:]
#     vals[j,:] = vals[h - j + 1,:]
#     vals[h - j + 1,:] = row
#   end
#   PNGFiles.save(path, val_to_color.(vals); compression_level = 9)
# end

# png("lats.png", map(r -> clamp(parse(Float32,r[1])          / 90.0,   0, 1), vals), 151, 113; val_to_color=PNGFiles.Gray)
# png("lons.png", map(r -> clamp((parse(Float32,r[2]) - 180)  / 180.0,  0, 1), vals), 151, 113; val_to_color=PNGFiles.Gray)
# png("vals.png", map(r -> clamp((parse(Float32,r[3]) + 1000) / 4000.0, 0, 1), vals), 151, 113; val_to_color=PNGFiles.Gray)

# open("vals.xyz", "w") do f
#   # lon lat val
#   DelimitedFiles.writedlm(f, map(r -> (r[2], r[1], r[3]), vals), '\t')
# end
