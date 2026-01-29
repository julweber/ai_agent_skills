---
name: list-most-intensive-processes
description: Lists the top N most intensive processes running on the system based on CPU time and memory usage. Uses Python to gather process information from the operating system.
---

# List Most Intensive Processes

## When to use this skill

Use this skill when:
- The user wants to identify which processes are consuming the most CPU time and memory
- You need to analyze system performance or find resource-hungry processes for optimization
- A user requests to see top N processes by CPU and memory usage

## How it works

This skill uses Python's psutil library to gather real-time process information from the operating system, including CPU percentage, memory usage, and process names. It then sorts processes by combined CPU + Memory scores to identify the most intensive ones.

## Usage

To use this skill, provide:
1. The number of top processes to return (N)
2. Optional: A threshold for minimum resource usage (to filter out low-impact processes)

Example:
```
list-most-intensive-processes 10
```

This will list the 10 most intensive processes in terms of combined CPU and memory usage.

## Requirements

- Python 3.x installed on the system
- psutil library (install with `pip install psutil`)
- Read access to system process information