import os
from pathlib import Path

# Get the base directory
BASE_DIR = Path(__file__).resolve().parent

# Define media folders
MEDIA_ROOT = BASE_DIR / 'media'
FOLDERS = [
    'raise_up/images',
    'raise_up/videos',
]

def create_folders():
    """Create necessary media folders for file uploads"""
    for folder in FOLDERS:
        folder_path = MEDIA_ROOT / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        print(f"✓ Created/verified folder: {folder_path}")
    
    print("\n✅ All media folders are ready!")

if __name__ == "__main__":
    create_folders()
