#!/usr/bin/env python3
"""
Generate test image variations for OMR pipeline validation.
Creates variations with rotation, brightness changes, and noise.
"""

from PIL import Image, ImageEnhance, ImageOps
import numpy as np
import os

def add_noise(image, noise_level=0.02):
    """Add Gaussian noise to image."""
    img_array = np.array(image)
    noise = np.random.normal(0, noise_level * 255, img_array.shape)
    noisy_array = np.clip(img_array + noise, 0, 255).astype(np.uint8)
    return Image.fromarray(noisy_array)

def generate_variations():
    """Generate test image variations."""
    input_path = 'assets/test_sheet_filled.png'
    output_dir = 'assets/gallery'

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Load original image
    original = Image.open(input_path)

    # 1. Original (baseline)
    original.save(f'{output_dir}/01_original.png')
    print('✓ Created: 01_original.png')

    # 2. Rotated +10 degrees (with white background to simulate real photo)
    rotated_10 = original.rotate(10, expand=True, fillcolor='white')
    rotated_10.save(f'{output_dir}/02_rotated_10deg.png')
    print('✓ Created: 02_rotated_10deg.png')

    # 3. Rotated -15 degrees
    rotated_minus15 = original.rotate(-15, expand=True, fillcolor='white')
    rotated_minus15.save(f'{output_dir}/03_rotated_minus15deg.png')
    print('✓ Created: 03_rotated_minus15deg.png')

    # 4. Dim lighting (reduced brightness)
    enhancer = ImageEnhance.Brightness(original)
    dim = enhancer.enhance(0.6)  # 60% brightness
    dim.save(f'{output_dir}/04_dim_lighting.png')
    print('✓ Created: 04_dim_lighting.png')

    # 5. Bright lighting (increased brightness)
    bright = enhancer.enhance(1.4)  # 140% brightness
    bright.save(f'{output_dir}/05_bright_lighting.png')
    print('✓ Created: 05_bright_lighting.png')

    # 6. Added noise
    noisy = add_noise(original, noise_level=0.015)
    noisy.save(f'{output_dir}/06_noisy.png')
    print('✓ Created: 06_noisy.png')

    # 7. Combined: slight rotation + dim lighting
    combined = original.rotate(8, expand=True, fillcolor='white')
    enhancer_combined = ImageEnhance.Brightness(combined)
    combined = enhancer_combined.enhance(0.7)
    combined.save(f'{output_dir}/07_rotated_dim.png')
    print('✓ Created: 07_rotated_dim.png')

    print('\n✅ Successfully created 7 test image variations!')
    print(f'   Location: {output_dir}/')

if __name__ == '__main__':
    # Change to omr_spike directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    generate_variations()
