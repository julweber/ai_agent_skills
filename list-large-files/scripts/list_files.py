#!/usr/bin/env python3

import os
import sys
from pathlib import Path

def get_large_files(directory, n):
    """
    Get the top N largest files in a directory and its subdirectories.
    
    Args:
        directory (str): The directory to scan
        n (int): Number of top largest files to return
    
    Returns:
        list: List of tuples (file_path, file_size) sorted by size (largest first)
    """
    if not os.path.exists(directory):
        raise FileNotFoundError(f"Directory {directory} does not exist")
    
    if not os.path.isdir(directory):
        raise NotADirectoryError(f"{directory} is not a directory")
        
    files = []
    
    # Walk through all directories and subdirectories
    for root, dirs, filenames in os.walk(directory):
        for filename in filenames:
            file_path = os.path.join(root, filename)
            
            try:
                # Get file size
                file_size = os.path.getsize(file_path)
                files.append((file_path, file_size))
            except (OSError, IOError):
                # Skip files we can't access
                continue
    
    # Sort by size in descending order and return top N
    files.sort(key=lambda x: x[1], reverse=True)
    
    return files[:n]

def format_file_size(size_bytes):
    """
    Convert bytes to human readable format.
    
    Args:
        size_bytes (int): Size in bytes
    
    Returns:
        str: Human readable file size
    """
    if size_bytes == 0:
        return "0 B"
    
    size_names = ["B", "KB", "MB", "GB", "TB"]
    i = 0
    while size_bytes >= 1024 and i < len(size_names) - 1:
        size_bytes /= 1024
        i += 1
    
    return f"{size_bytes:.1f} {size_names[i]}"

def main():
    if len(sys.argv) != 3:
        print("Usage: list_files.py <directory> <number_of_files>")
        sys.exit(1)
    
    directory = sys.argv[1]
    try:
        n = int(sys.argv[2])
        if n <= 0:
            raise ValueError
    except ValueError:
        print("Error: Number of files must be a positive integer")
        sys.exit(1)
    
    try:
        large_files = get_large_files(directory, n)
        
        if not large_files:
            print(f"No files found in {directory}")
            return
        
        print(f"Top {n} largest files in '{directory}':")
        print("-" * 60)
        
        for i, (file_path, file_size) in enumerate(large_files, 1):
            readable_size = format_file_size(file_size)
            print(f"{i:2d}. {readable_size:>8} - {file_path}")
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()