## graycrown/cascades/frontalface - LBP Cascade for frontal face detection
##
## This cascade is converted from OpenCV's lbpcascade_frontalface.xml
## Window size: 24x24 pixels
## Features: 136
## Stages: 20
##
## Usage:
## ```nim
## import graycrown
## import graycrown/cascades/frontalface
##
## # Compute integral image
## var iiData: array[imgSize, uint32]
## var ii = initIntegralImage(iiData, width, height)
## computeIntegral(img.toView, ii)
##
## # Detect faces
## var faces: array[100, Rect]
## let n = lbpDetect(frontalfaceCascade, ii, faces, 100)
## ```

import ../core
import ../lbp

const
  FrontalfaceWindowW* = 24
  FrontalfaceWindowH* = 24
  FrontalfaceNFeatures* = 136
  FrontalfaceNWeaks* = 139
  FrontalfaceNStages* = 20

# Feature rectangles: [x, y, w, h] * nFeatures
const frontalfaceFeatures: array[136 * 4, int8] = [
  0'i8,
  0,
  3,
  5, # 0
  0'i8,
  0,
  4,
  2, # 1
  0'i8,
  0,
  6,
  3, # 2
  0'i8,
  1,
  2,
  3, # 3
  0'i8,
  1,
  3,
  3, # 4
  0'i8,
  1,
  3,
  7, # 5
  0'i8,
  4,
  3,
  3, # 6
  0'i8,
  11,
  3,
  4, # 7
  0'i8,
  12,
  8,
  4, # 8
  0'i8,
  14,
  4,
  3, # 9
  1'i8,
  0,
  5,
  3, # 10
  1'i8,
  1,
  2,
  2, # 11
  1'i8,
  3,
  3,
  1, # 12
  1'i8,
  7,
  4,
  4, # 13
  1'i8,
  12,
  2,
  2, # 14
  1'i8,
  13,
  4,
  1, # 15
  1'i8,
  14,
  4,
  3, # 16
  1'i8,
  17,
  3,
  2, # 17
  2'i8,
  0,
  2,
  3, # 18
  2'i8,
  1,
  2,
  2, # 19
  2'i8,
  2,
  4,
  6, # 20
  2'i8,
  3,
  4,
  4, # 21
  2'i8,
  7,
  2,
  1, # 22
  2'i8,
  11,
  2,
  3, # 23
  2'i8,
  17,
  3,
  2, # 24
  3'i8,
  0,
  2,
  2, # 25
  3'i8,
  1,
  7,
  3, # 26
  3'i8,
  7,
  2,
  1, # 27
  3'i8,
  7,
  2,
  4, # 28
  3'i8,
  18,
  2,
  2, # 29
  4'i8,
  0,
  2,
  3, # 30
  4'i8,
  3,
  2,
  1, # 31
  4'i8,
  6,
  2,
  1, # 32
  4'i8,
  6,
  2,
  5, # 33
  4'i8,
  7,
  5,
  2, # 34
  4'i8,
  8,
  4,
  3, # 35
  4'i8,
  18,
  2,
  2, # 36
  5'i8,
  0,
  2,
  2, # 37
  5'i8,
  3,
  4,
  4, # 38
  5'i8,
  6,
  2,
  5, # 39
  5'i8,
  9,
  2,
  2, # 40
  5'i8,
  10,
  2,
  2, # 41
  6'i8,
  3,
  4,
  4, # 42
  6'i8,
  4,
  4,
  3, # 43
  6'i8,
  5,
  2,
  3, # 44
  6'i8,
  5,
  2,
  5, # 45
  6'i8,
  5,
  4,
  3, # 46
  6'i8,
  6,
  4,
  2, # 47
  6'i8,
  6,
  4,
  4, # 48
  6'i8,
  18,
  1,
  2, # 49
  6'i8,
  21,
  2,
  1, # 50
  7'i8,
  0,
  3,
  7, # 51
  7'i8,
  4,
  2,
  3, # 52
  7'i8,
  9,
  5,
  1, # 53
  7'i8,
  21,
  2,
  1, # 54
  8'i8,
  0,
  1,
  4, # 55
  8'i8,
  5,
  2,
  2, # 56
  8'i8,
  5,
  3,
  2, # 57
  8'i8,
  17,
  3,
  1, # 58
  8'i8,
  18,
  1,
  2, # 59
  9'i8,
  0,
  5,
  3, # 60
  9'i8,
  2,
  2,
  6, # 61
  9'i8,
  5,
  1,
  1, # 62
  9'i8,
  11,
  1,
  1, # 63
  9'i8,
  16,
  1,
  1, # 64
  9'i8,
  16,
  2,
  1, # 65
  9'i8,
  17,
  1,
  1, # 66
  9'i8,
  18,
  1,
  1, # 67
  10'i8,
  5,
  1,
  2, # 68
  10'i8,
  5,
  3,
  3, # 69
  10'i8,
  7,
  1,
  5, # 70
  10'i8,
  8,
  1,
  1, # 71
  10'i8,
  9,
  1,
  1, # 72
  10'i8,
  10,
  1,
  1, # 73
  10'i8,
  10,
  1,
  2, # 74
  10'i8,
  14,
  3,
  3, # 75
  10'i8,
  15,
  1,
  1, # 76
  10'i8,
  15,
  2,
  1, # 77
  10'i8,
  16,
  1,
  1, # 78
  10'i8,
  16,
  2,
  1, # 79
  10'i8,
  17,
  1,
  1, # 80
  10'i8,
  21,
  1,
  1, # 81
  11'i8,
  3,
  2,
  2, # 82
  11'i8,
  5,
  1,
  2, # 83
  11'i8,
  5,
  3,
  3, # 84
  11'i8,
  5,
  4,
  6, # 85
  11'i8,
  6,
  1,
  1, # 86
  11'i8,
  7,
  2,
  2, # 87
  11'i8,
  8,
  1,
  2, # 88
  11'i8,
  10,
  1,
  1, # 89
  11'i8,
  10,
  1,
  2, # 90
  11'i8,
  15,
  1,
  1, # 91
  11'i8,
  17,
  1,
  1, # 92
  11'i8,
  18,
  1,
  1, # 93
  12'i8,
  0,
  2,
  2, # 94
  12'i8,
  1,
  2,
  5, # 95
  12'i8,
  2,
  4,
  1, # 96
  12'i8,
  3,
  1,
  3, # 97
  12'i8,
  7,
  3,
  4, # 98
  12'i8,
  10,
  3,
  2, # 99
  12'i8,
  11,
  1,
  1, # 100
  12'i8,
  12,
  3,
  2, # 101
  12'i8,
  14,
  4,
  3, # 102
  12'i8,
  17,
  1,
  1, # 103
  12'i8,
  21,
  2,
  1, # 104
  13'i8,
  6,
  2,
  5, # 105
  13'i8,
  7,
  3,
  5, # 106
  13'i8,
  11,
  3,
  2, # 107
  13'i8,
  17,
  2,
  2, # 108
  13'i8,
  17,
  3,
  2, # 109
  13'i8,
  18,
  1,
  2, # 110
  13'i8,
  18,
  2,
  2, # 111
  14'i8,
  0,
  2,
  2, # 112
  14'i8,
  1,
  1,
  3, # 113
  14'i8,
  2,
  3,
  2, # 114
  14'i8,
  7,
  2,
  1, # 115
  14'i8,
  13,
  2,
  1, # 116
  14'i8,
  13,
  3,
  3, # 117
  14'i8,
  17,
  2,
  2, # 118
  15'i8,
  0,
  2,
  2, # 119
  15'i8,
  0,
  2,
  3, # 120
  15'i8,
  4,
  3,
  2, # 121
  15'i8,
  4,
  3,
  6, # 122
  15'i8,
  6,
  3,
  2, # 123
  15'i8,
  11,
  3,
  4, # 124
  15'i8,
  13,
  3,
  2, # 125
  15'i8,
  17,
  2,
  2, # 126
  15'i8,
  17,
  3,
  2, # 127
  16'i8,
  1,
  2,
  3, # 128
  16'i8,
  3,
  2,
  4, # 129
  16'i8,
  6,
  1,
  1, # 130
  16'i8,
  16,
  2,
  2, # 131
  17'i8,
  1,
  2,
  2, # 132
  17'i8,
  1,
  2,
  5, # 133
  17'i8,
  12,
  2,
  2, # 134
  18'i8,
  0,
  2,
  2, # 135
]

# Stage thresholds
const frontalfaceStageThreshold: array[20, float32] = [
  -0.752089202404022'f32, -0.487207829952240'f32, -1.159232854843140'f32,
  -0.756235599517822'f32, -0.808535814285278'f32, -0.554997146129608'f32,
  -0.877646028995514'f32, -1.113928794860840'f32, -0.824362576007843'f32,
  -1.223711609840393'f32, -0.554423093795776'f32, -0.716156065464020'f32,
  -0.674394071102142'f32, -1.204229831695557'f32, -0.840205013751984'f32,
  -1.197439432144165'f32, -0.573312819004059'f32, -0.489259690046310'f32,
  -0.591194093227386'f32, -0.761291623115540'f32,
]

# Number of weak classifiers per stage
const frontalfaceStageNWeaks: array[20, uint16] =
  [3, 4, 4, 5, 5, 5, 5, 6, 7, 7, 7, 7, 8, 9, 10, 9, 9, 9, 10, 10]

# Stage weak classifier start indices
const frontalfaceStageWeakStart: array[20, uint16] =
  [0, 3, 7, 11, 16, 21, 26, 31, 37, 44, 51, 58, 65, 73, 82, 92, 101, 110, 119, 129]

# Note: Full cascade data would include:
# - weakFeatureIdx (139 entries)
# - weakLeftVal (139 float32)
# - weakRightVal (139 float32)
# - weakSubsetOffset (139 uint16)
# - weakNumSubsets (139 uint16)
# - subsets (large array of int32 bitmasks)
#
# The full data is too large to include inline. In a real application,
# you would either:
# 1. Include the full data arrays
# 2. Load from a binary file at runtime
# 3. Use compile-time file embedding

# Placeholder cascade - actual values would need the complete dataset
# For demonstration, this shows the structure

# This is a STUB - you need to fill in the actual cascade data
# from the OpenCV lbpcascade_frontalface.xml converted to this format

when false: # Set to true when you have full cascade data
  let frontalfaceCascade* = LbpCascade(
    windowW: FrontalfaceWindowW,
    windowH: FrontalfaceWindowH,
    nFeatures: FrontalfaceNFeatures,
    nWeaks: FrontalfaceNWeaks,
    nStages: FrontalfaceNStages,
    features: cast[ptr UncheckedArray[int8]](frontalfaceFeatures[0].unsafeAddr),
      # ... fill in remaining pointers
  )
