import json
import numpy as np

class DepthData:
    def __init__(self, depth_file, scaling_factor, width, height, min_depth, max_depth, invert):
        self.scale = scaling_factor
        self.width = width
        self.height = height
        self.min_depth = min_depth
        self.max_depth = max_depth
        self.invert = invert

        self.load_depth_data(depth_file)
        self.calculate3DPoints()

    """
    Read data from depth data file for relevant information. Gets the scaled intrinsic matrix
    and depth data points.

    Params:
    - file: file path to depth data
    """
    def load_depth_data(self, file):
        with open(file) as f:
            data = json.load(f)

            # Getting and scaling intrinsic matrix
            self.intrinsic = np.array(data["calibration_data"]["intrinsic_matrix"]).reshape((3,3))
            self.intrinsic = self.intrinsic.transpose()

            self.intrinsic[0,0] *= self.scale
            self.intrinsic[1,1] *= self.scale
            self.intrinsic[0,2] *= self.scale
            self.intrinsic[1,2] *= self.scale

            # Getting the depth data as a 2d array
            self.depth_data = np.array(data["depth_data"]).astype('float32')
            self.depth_data = self.depth_data.transpose()
            self.depth_data = np.fliplr(self.depth_data)

            # Invert depth data if requested
            if self.invert:
                max = np.amax(self.depth_data)
                for i in range(self.depth_data.shape[0]):
                    for j in range(self.depth_data.shape[1]):
                        self.depth_data[i][j] = max - self.depth_data[i][j]

    """
    Project 2D points to 3D points using intrinsic matrix and depth data.

    Params:
        - pts: 2d array of (x,y) points
    """
    def calculate3DPoints(self):
        # Get focal length and camera center
        fx = self.intrinsic[0,0]
        fy = self.intrinsic[1,1]
        cx = self.intrinsic[0,2]
        cy = self.intrinsic[1,2]

        # Set up 2D points (all possible (x,y) positions)
        rows, cols = self.depth_data.shape
        c, r = np.meshgrid(np.arange(cols), np.arange(rows), sparse=True)

        valid = (self.depth_data > self.min_depth) & (self.depth_data < self.max_depth)

        # Perform calculations to convert 2d points to 3d points
        z = np.where(valid, self.depth_data, -1.0)
        x = np.where(valid, z * (c - cx) / fx, 0)
        y = np.where(valid, z * (r - cy) / fy, 0)
        xyz = np.dstack((x, y, z))

        # Store 3D points (N, 3)
        self.points3d = xyz.reshape(rows*cols, 3)
