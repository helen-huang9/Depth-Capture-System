import numpy as np
import matplotlib.pyplot as plt
import plotly.graph_objects as go
import open3d as o3d
from skimage import io

def show_point_cloud(points3d, colors):
    """
    Show 3D points with their corresponding colors
    """
    fig = go.Figure(data=[go.Scatter3d(
        x=points3d[:, 0],
        y=points3d[:, 1],
        z=points3d[:, 2],
        mode='markers',
        marker=dict(
            size=2,
            color=colors,
            opacity=1
        )
    )])

    # tight layout
    # fig.update_layout(margin=dict(l=0, r=0, b=0, t=0), scene=dict(xaxis=dict(tickvals=[0, 0.5, 1, 1.5, 2]), yaxis=dict(tickvals=[0, 0.5, 1, 1.5, 2]), zaxis=dict(tickwidth=0.5, tickvals=[0, 0.5, 1, 1.5, 2])))
    fig.update_layout(margin=dict(l=0, r=0, b=0, t=0))
    fig.show()

def show_voxel_model(points3d, points3d_color, voxel_size=0.05):
    """
    Creates a voxel grid based on the 3d points and colors found.
    Make sure that open3d is installed in environment. To do so, enter
    the cs1430 environment and run the commmand 'pip install open3d'
    """
    pcd = o3d.geometry.PointCloud()
    pcd.points = o3d.utility.Vector3dVector(points3d)
    pcd.colors = o3d.utility.Vector3dVector(points3d_color)
    voxel_grid = o3d.geometry.VoxelGrid.create_from_point_cloud(pcd, voxel_size) 
    o3d.visualization.draw_geometries([voxel_grid])

def rectify_pcd(pts1, pts1_color, K, depth_width, depth_height):
    # Reshape color so it is same shape as pts1
    pts1_color = np.reshape(pts1_color, (depth_width*depth_height, 3))

    # Delete some pixel points to improve performance
    pts2 = np.empty((0,3))
    pts2_color = np.empty((0,3))
    for i in range(0, len(pts1), K*(depth_width)): # (row filter)
        pts2 = np.append(pts2, pts1[i:i+depth_width, :], axis=0)
        pts2_color = np.append(pts2_color, pts1_color[i:i+depth_width, :], axis=0)
    pts2 = pts2[0::K] # (column filter)
    pts2_color = pts2_color[0::K]

    # Get rid of points where Z == -1 and make sure to do the same for the color
    indices_to_delete = np.argwhere(pts2[:,2] == -1.0)
    xyz = np.delete(pts2, indices_to_delete, 0)
    xyz_color = np.delete(pts2_color, indices_to_delete, 0)

    return xyz, xyz_color


def ICP(pts1, pts2):
    """
    Implements the Iterative Closest Point algorithm. 
    (Note: the inputs are Python lists, not Numpy arrays. The return type should also be of Python lists)

    =====================
    Running on Test Data:
    =====================
    I took three sets of test data that you can try your ICP implementation on. They are `data/ICP_test/1`,
    `data/ICP_test/2` and `data/ICP_test/3`. The follow parameters should be used for each test:
    (Note: The min/max depth parameters determines the 3D points we choose to display. 
        They points displayed have Z coords in range (min-depth, max-depth))

    - ICP_test/1 : --images ICP_test/1 --iphone-version 10 --min-depth 0.0 --max-depth 0.5
    - ICP_test/2 : --images ICP_test/2 --iphone-version 10 --min-depth 0.0 --max-depth 0.5
    - ICP_test/3 : --images ICP_test/3 --iphone-version 10 --min-depth 0.0 --max-depth 0.6

    If you would like to see the intermediate depth maps of each image, add the flag: '--show-depth True'

    ===============================================
    Changing the Num of Point Cloud Images to Show:
    ===============================================
    You can change the number of point cloud images that are displayed in the final point cloud by
    changing the `K` value in main.py on line 130. Right now, I have it set so only 2 images are used
    in total for ICP.

    =======
    Params:
    =======
    - pts1 : 2D Python list of shape (N, 3) where N is the number of 3D points. The point cloud of image 1.
    - pts2 : 2D Python list of shape (N, 3) where N is the number of 3D points. The point cloud of image 2.

    =======
    Returns:
    =======
    - all_pts : 2D Python list of shape (2N, 3). This is the combination of pts1 and pts2 after ICP 
            (and thus the combination of images 1 and 2)
    """

    all_pts = []

    # TODO: Implement ICP Here

    all_pts += pts1
    all_pts += pts2
    return all_pts