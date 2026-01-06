## knull/integral - Integral images (summed area tables)
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

type
  IntegralImage* = object
    ## Integral image (summed area table)
    ## Each pixel contains sum of all pixels above and to the left
    width*, height*: uint32
    data*: ptr UncheckedArray[uint32]

func initIntegralImage*(data: ptr UncheckedArray[uint32];
                        width, height: uint32): IntegralImage =
    ## Create integral image from existing buffer
    ## Buffer size must be at least width * height * sizeof(uint32)
    IntegralImage(width: width, height: height, data: data)

func initIntegralImage*(data: var openArray[uint32]; width, height: uint32): IntegralImage =
  ## Create integral image from openArray
  assert data.len >= int(width * height), "Buffer too small"
  IntegralImage(
    width: width,
    height: height,
    data: cast[ptr UncheckedArray[uint32]](addr data[0])
  )  
    
