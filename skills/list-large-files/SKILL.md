---
name: list-large-files
description: Lists the top N largest files in a given directory and its subdirectories. Uses Python to traverse directories and calculate file sizes.
---

# List Large Files

## When to use this skill

Use this skill when:
- The user wants to identify the largest files in a directory structure
- You need to analyze disk usage or find large files for cleanup
- A user requests to see top N largest files in a specific path

## How it works

This skill uses Python to recursively traverse directories and calculate file sizes, then returns the top N largest files found.

## Usage

To use this skill, provide:
1. The directory path to scan (e.g., "/home/user/documents")
2. The number of top files to return (N)

Example:
```
list-large-files /home/user 10
```

This will list the 10 largest files in /home/user and all its subdirectories.

## Requirements

- Python 3.x installed on the system
- Read access to the target directory and its contents