import argparse
import os
from skimage import io
from skimage.transform import rescale
import numpy as np
import open3d as o3d
import matplotlib.pyplot as plt

from helpers import show_point_cloud, show_voxel_model, rectify_pcd, ICP
from depth_data import DepthData

def parse_args():
    """ Perform command-line argument parsing. """

    parser = argparse.ArgumentParser(
        description="3D Reconstruction from Depth Maps")
    parser.add_argument(
        '--data',
        default=os.getcwd() + '/../data/',
        help='Folder where RGBD data is stored')
    parser.add_argument(
        '--images',
        required=True,
        help='Folder with RGBD data to use')
    parser.add_argument(
        '--color-folder',
        default='color',
        type=str,
        help='Name of folder containing RGB Image')
    parser.add_argument(
        '--depth-folder',
        default='depth',
        type=str,
        help='Name of folder containing depth data files (JSON format)'
    ),
    parser.add_argument(
        '--iphone-version',
        required=True,
        choices=['10', '12', '13'],
        help='iPhone version. Necessary because camera image dimensions are different across versions'
    ),
    parser.add_argument(
        '--min-depth',
        type=float,
        default=0.0,
        help='Minimum depth distance bound. Disregards any depths below this threshold.'
    ),
    parser.add_argument(
        '--max-depth',
        type=float,
        default=2.0,
        help='Maximum depth distance bound. Disregards any depths above this threshold.'
    ),
    parser.add_argument(
        '--show-depth',
        type=bool,
        default=False,
        help='Show intermediate depth images with corresponding colored image.'
    )

    return parser.parse_args()


def main():
    args = parse_args()

    # Get camera and depth map dimensions
    if args.iphone_version == '10':
        img_width = 4032
        img_height = 3024
        depth_width = 768
        depth_height = 576
        invert_depth = False
    elif args.iphone_version == '12':
        img_width = 2049
        img_height = 1537
        invert_depth = True

        # Front Camera depth dimensions
        # depth_width = 640
        # depth_height = 480
        
        # Back Camera depth dimensions
        depth_width = 768
        depth_height = 576

    elif args.iphone_version == '13':
        img_width = 4032
        img_height = 3024
        invert_depth = False

        # Back Camera depth dimensions
        depth_width = 768
        depth_height = 576
    else:
        print("Unknown iPhone version inputted")

    # Get depth bounds
    min_depth = args.min_depth
    max_depth = args.max_depth

    print("Loading all color images and depth data...")

    # Get RGB image and depth file paths
    # (Sort the image and depth files because the color images and depth files correspond by number/order)
    data_folder = os.path.join(args.data, args.images)
    color_dir_path = os.path.join(data_folder, args.color_folder)
    color_image_files = os.listdir(color_dir_path)
    color_image_files.sort()

    depth_dir_path = os.path.join(data_folder, args.depth_folder)
    depth_files = os.listdir(depth_dir_path)
    depth_files.sort()

    # Get all color images
    color_images = []
    scaling_factor = depth_width/img_width
    for color_file in color_image_files:
        # Read in RGB image and convert to same size as depth data. Add scaled colored image to color_images[]
        rgb_img = io.imread(os.path.join(color_dir_path, color_file))
        scaled_rgb_img = np.empty([depth_width, depth_height, 3], dtype=np.float32)
        scaled_rgb_img[:,:,0] = rescale(rgb_img[:,:,0], scaling_factor, anti_aliasing=True)
        scaled_rgb_img[:,:,1] = rescale(rgb_img[:,:,1], scaling_factor, anti_aliasing=True)
        scaled_rgb_img[:,:,2] = rescale(rgb_img[:,:,2], scaling_factor, anti_aliasing=True)
        color_images.append(scaled_rgb_img)
    
    # Get all depth data
    depth_data = []
    for depth_file in depth_files:
        # Read in the depth data file to get points3d and add the DepthData to depth_data[]
        path = os.path.join(depth_dir_path, depth_file)
        depth = DepthData(path, scaling_factor, depth_width, depth_height, min_depth, max_depth, invert_depth)
        depth_data.append(depth)

    print("Successfully loaded all color images and depth data!")

    # Show depth map and color image
    if args.show_depth:
        for i in range(len(color_images)):
            plt.imshow(depth_data[i].depth_data)
            plt.colorbar()
            plt.show()
            plt.imshow(color_images[i])
            plt.show()

    # Add 3d world XYZ points (Nx3) and associated RGB colors (Nx3) to 3d points to displayed in point cloud
    K = 1
    num_images = len(color_images)
    num_cloud_points = min(K, num_images)
    points3d = []
    points3d_color = []


    x = 0
    xyz, xyz_color = rectify_pcd(depth_data[x].points3d, color_images[x], K, depth_width, depth_height)
    show_point_cloud(xyz, xyz_color)
    show_voxel_model(xyz, xyz_color, voxel_size=0.003)
    
    # # Iterate through each image
    # for p in range(num_cloud_points):
    #     # Rectify and downsample image's point cloud
    #     xyz, xyz_color = rectify_pcd(depth_data[p].points3d, color_images[p], K, depth_width, depth_height)
    #     show_voxel_model(xyz, xyz_color, voxel_size=0.001)

    #     # Call ICP to match cloud points
    #     # points3d = ICP(points3d, xyz.tolist())
    #     # points3d_color += xyz_color.tolist()

    # points3d = np.array(points3d)
    # points3d_color = np.array(points3d_color)

    # Show point cloud / voxel model with 3d points (Nx3) and associated colors (Nx3)
    # show_point_cloud(points3d, points3d_color)
    # show_voxel_model(points3d, points3d_color, voxel_size=0.001)

if __name__ == '__main__':
    main()
