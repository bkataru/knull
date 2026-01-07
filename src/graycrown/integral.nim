## graycrown/integral - Integral images (summed area tables)
##
## This module provides:
## - Integral image computation
## - Fast region sum queries
## - Fast region mean queries
##
## Integral images enable O(1) computation of any rectangular sum
## after O(n) preprocessing, useful for adaptive thresholding,
## feature computation, and more.

{.push raises: [].}

import ./core

# ============================================================================
# Integral Image Type
# ============================================================================

type IntegralImage* = object
  ## Integral image (summed area table)
  ## Each pixel contains sum of all pixels above and to the left
  width*, height*: uint32
  data*: ptr UncheckedArray[uint32]

func initIntegralImage*(
    data: ptr UncheckedArray[uint32], width, height: uint32
): IntegralImage =
  ## Create integral image from existing buffer
  ## Buffer size must be at least width * height * sizeof(uint32)
  IntegralImage(width: width, height: height, data: data)

func initIntegralImage*(
    data: var openArray[uint32], width, height: uint32
): IntegralImage =
  ## Create integral image from openArray
  assert data.len >= int(width * height), "Buffer too small"
  IntegralImage(
    width: width, height: height, data: cast[ptr UncheckedArray[uint32]](addr data[0])
  )

func isValid*(ii: IntegralImage): bool {.inline.} =
  ii.data != nil and ii.width > 0 and ii.height > 0

func `[]`*(ii: IntegralImage, x, y: uint32): uint32 {.inline.} =
  ## Get integral value at (x, y)
  if x < ii.width and y < ii.height:
    ii.data[y * ii.width + x]
  else:
    0

func `[]`*(ii: IntegralImage, x, y: int): uint32 {.inline.} =
  ## Get integral value with signed coordinates
  ## Returns 0 for negative coordinates (useful for boundary handling)
  if x >= 0 and y >= 0 and uint32(x) < ii.width and uint32(y) < ii.height:
    ii.data[uint32(y) * ii.width + uint32(x)]
  else:
    0

# ============================================================================
# Integral Image Computation
# ============================================================================

proc computeIntegral*(src: ImageView | GrayImage, ii: var IntegralImage) =
  ## Compute integral image from grayscale source
  ##
  ## After computation, ii[x, y] = sum of all src pixels from (0,0) to (x,y)
  assert src.isValid, "Source image must be valid"
  assert ii.width == src.width and ii.height == src.height,
    "Integral image dimensions must match source"

  var rowSum: uint32 = 0

  for y in 0'u32 ..< src.height:
    rowSum = 0
    for x in 0'u32 ..< src.width:
      rowSum += uint32(src[x, y])
      let above =
        if y > 0:
          ii[x, y - 1]
        else:
          0'u32
      ii.data[y * ii.width + x] = rowSum + above

proc computeIntegral*(src: ImageView | GrayImage, data: var openArray[uint32]) =
  ## Compute integral image directly into an array
  var ii = initIntegralImage(data, src.width, src.height)
  computeIntegral(src, ii)

# ============================================================================
# Region Sum Queries
# ============================================================================

func regionSum*(ii: IntegralImage, x, y, w, h: uint32): uint32 =
  ## Get sum of pixels in rectangular region using integral image
  ##
  ## Computes sum in O(1) time using:
  ## sum = D + A - B - C
  ## where A, B, C, D are the four corners of the region
  ##
  ##   (x-1,y-1)       (x+w-1,y-1)
  ##       A ───────────── B
  ##       │               │
  ##       │   Region      │
  ##       │               │
  ##       C ───────────── D
  ##  (x-1,y+h-1)     (x+w-1,y+h-1)
  assert ii.isValid, "Integral image must be valid"
  assert x + w <= ii.width and y + h <= ii.height, "Region out of bounds"

  let x2 = int(x + w - 1)
  let y2 = int(y + h - 1)

  # Get corner values (handle boundary cases)
  let a = ii[int(x) - 1, int(y) - 1] # Top-left (outside region)
  let b = ii[x2, int(y) - 1] # Top-right (outside region)
  let c = ii[int(x) - 1, y2] # Bottom-left (outside region)
  let d = ii[x2, y2] # Bottom-right (inside region)

  d + a - b - c

func regionSum*(ii: IntegralImage, roi: Rect): uint32 {.inline.} =
  ## Get sum of pixels in rectangular ROI
  regionSum(ii, roi.x, roi.y, roi.w, roi.h)

func regionMean*(ii: IntegralImage, x, y, w, h: uint32): uint32 =
  ## Get mean of pixels in rectangular region
  let sum = regionSum(ii, x, y, w, h)
  let area = w * h
  if area > 0:
    sum div area
  else:
    0

func regionMean*(ii: IntegralImage, roi: Rect): uint32 {.inline.} =
  ## Get mean of pixels in rectangular ROI
  regionMean(ii, roi.x, roi.y, roi.w, roi.h)

# ============================================================================
# Integral Image Based Blur (Box Filter)
# ============================================================================

proc integralBlur*(
    dst: var ImageView | var GrayImage, ii: IntegralImage, radius: uint32
) =
  ## Apply box blur using pre-computed integral image
  ## Much faster than naive box blur for large radii
  assert dst.isValid, "Destination must be valid"
  assert ii.width == dst.width and ii.height == dst.height,
    "Integral image dimensions must match"

  for y in 0'u32 ..< dst.height:
    for x in 0'u32 ..< dst.width:
      # Compute window bounds (clamped to image)
      let x1 =
        if x >= radius:
          x - radius
        else:
          0'u32
      let y1 =
        if y >= radius:
          y - radius
        else:
          0'u32
      let x2 = min(x + radius, dst.width - 1)
      let y2 = min(y + radius, dst.height - 1)

      let w = x2 - x1 + 1
      let h = y2 - y1 + 1

      let mean = regionMean(ii, x1, y1, w, h)
      dst[x, y] = uint8(min(mean, 255'u32))

# ============================================================================
# Integral Image Based Adaptive Threshold
# ============================================================================

proc integralAdaptiveThreshold*(
    dst: var ImageView | var GrayImage,
    src: ImageView | GrayImage,
    ii: IntegralImage,
    radius: uint32,
    c: int = 0,
) =
  ## Adaptive thresholding using pre-computed integral image
  ##
  ## Much faster than naive adaptive threshold for large windows
  assert dst.isValid and src.isValid, "Images must be valid"
  assert ii.width == src.width and ii.height == src.height, "Dimensions must match"

  for y in 0'u32 ..< src.height:
    for x in 0'u32 ..< src.width:
      # Compute window bounds
      let x1 =
        if x >= radius:
          x - radius
        else:
          0'u32
      let y1 =
        if y >= radius:
          y - radius
        else:
          0'u32
      let x2 = min(x + radius, src.width - 1)
      let y2 = min(y + radius, src.height - 1)

      let w = x2 - x1 + 1
      let h = y2 - y1 + 1

      let localMean = int(regionMean(ii, x1, y1, w, h))
      let thresh = localMean - c

      dst[x, y] = if int(src[x, y]) > thresh: MaxPixel else: MinPixel

# ============================================================================
# Squared Integral Image (for variance computation)
# ============================================================================

type IntegralImageSq* = object
  ## Squared integral image for variance computation
  ## Each pixel contains sum of squares of all pixels above and to the left
  width*, height*: uint32
  data*: ptr UncheckedArray[uint64]

func initIntegralImageSq*(
    data: ptr UncheckedArray[uint64], width, height: uint32
): IntegralImageSq =
  IntegralImageSq(width: width, height: height, data: data)

func isValid*(iisq: IntegralImageSq): bool {.inline.} =
  iisq.data != nil and iisq.width > 0 and iisq.height > 0

func `[]`*(iisq: IntegralImageSq, x, y: int): uint64 {.inline.} =
  if x >= 0 and y >= 0 and uint32(x) < iisq.width and uint32(y) < iisq.height:
    iisq.data[uint32(y) * iisq.width + uint32(x)]
  else:
    0

proc computeIntegralSq*(src: ImageView | GrayImage, iisq: var IntegralImageSq) =
  ## Compute squared integral image
  assert src.isValid, "Source image must be valid"
  assert iisq.width == src.width and iisq.height == src.height, "Dimensions must match"

  var rowSum: uint64 = 0

  for y in 0'u32 ..< src.height:
    rowSum = 0
    for x in 0'u32 ..< src.width:
      let pixel = uint64(src[x, y])
      rowSum += pixel * pixel
      let above =
        if y > 0:
          iisq[int(x), int(y) - 1]
        else:
          0'u64
      iisq.data[y * iisq.width + x] = rowSum + above

func regionSumSq*(iisq: IntegralImageSq, x, y, w, h: uint32): uint64 =
  ## Get sum of squared pixels in region
  let x2 = int(x + w - 1)
  let y2 = int(y + h - 1)

  let a = iisq[int(x) - 1, int(y) - 1]
  let b = iisq[x2, int(y) - 1]
  let c = iisq[int(x) - 1, y2]
  let d = iisq[x2, y2]

  d + a - b - c

func regionVariance*(
    ii: IntegralImage, iisq: IntegralImageSq, x, y, w, h: uint32
): float32 =
  ## Compute variance in region using integral images
  ## Var(X) = E[X²] - E[X]²
  let n = float32(w * h)
  if n <= 1.0'f32:
    return 0.0'f32

  let sum = float32(regionSum(ii, x, y, w, h))
  let sumSq = float32(regionSumSq(iisq, x, y, w, h))

  let mean = sum / n
  let meanSq = sumSq / n

  meanSq - mean * mean

{.pop.} # raises: []
