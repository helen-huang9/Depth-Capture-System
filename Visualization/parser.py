import argparse
import os

def parse_args():
    """ Perform command-line argument parsing. """

    parser = argparse.ArgumentParser(
        description="3D Reconstruction from Depth Maps")
    parser.add_argument(
        '--data',
        default=os.getcwd() + '/Visualization/data/',
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