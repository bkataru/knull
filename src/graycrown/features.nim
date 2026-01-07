## graycrown/features - Feature detection and description
##
## This module provides:
## - FAST corner detection
## - ORB feature extraction (Oriented FAST with rotated BRIEF)
## - Feature matching

{.push raises: [].}

import ./core
import ./image

# ============================================================================
# FAST Corner Detection
# ============================================================================

const
  # Bresenham circle of radius 3 (16 pixels)
  FastDx: array[16, int] = [0, 1, 2, 3, 3, 3, 2, 1, 0, -1, -2, -3, -3, -3, -2, -1]
  FastDy: array[16, int] = [-3, -3, -2, -1, 0, 1, 2, 3, 3, 3, 2, 1, 0, -1, -2, -3]

proc fastCorner*(
    img: ImageView | GrayImage,
    scoremap: var ImageView | var GrayImage,
    keypoints: var openArray[Keypoint],
    maxKeypoints: uint32,
    threshold: uint32,
): uint32 =
  ## FAST corner detection (Features from Accelerated Segment Test)
  ##
  ## Detects corners where at least 9 contiguous pixels on a Bresenham
  ## circle of radius 3 are all brighter or all darker than the center.
  ##
  ## Parameters:
  ## - img: Input grayscale image
  ## - scoremap: Output score map (same size as img, used for NMS)
  ## - keypoints: Output array of detected keypoints
  ## - maxKeypoints: Maximum number of keypoints to return
  ## - threshold: Intensity difference threshold (typically 10-30)
  ##
  ## Returns: Number of keypoints detected
  assert img.isValid and scoremap.isValid, ""
