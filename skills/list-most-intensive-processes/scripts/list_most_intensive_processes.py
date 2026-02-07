#!/usr/bin/env python3

import psutil
import sys
from collections import namedtuple

# Define a named tuple to represent process information
ProcessInfo = namedtuple('ProcessInfo', ['pid', 'name', 'cpu_percent', 'memory_mb'])

def get_most_intensive_processes(n, min_memory_mb):
    """
    Get the top N most intensive processes based on CPU and memory usage.
    
    Args:
        n: Number of top processes to return
        min_memory_mb: Minimum memory usage in MB to include processes
        
    Returns:
        list: List of ProcessInfo tuples sorted by combined resource usage (highest first)
    """
    processes = []
    
    try:
        # Iterate through all running processes
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_info']):
            try:
                # Get process info
                pid = proc.info['pid']
                name = proc.info['name']
                
                # Handle potential None values from cpu_percent and memory_info
                cpu_percent = proc.info['cpu_percent'] or 0.0
                memory_info = proc.info['memory_info']
                
                if memory_info is not None:
                    memory_mb = memory_info.rss / 1024 / 1024  # Convert bytes to MB
                else:
                    memory_mb = 0
                
                # Filter by minimum memory if specified
                if memory_mb < min_memory_mb:
                    continue
                    
                # Calculate combined resource usage (simple sum for now)
                combined_score = cpu_percent + memory_mb
                
                processes.append(ProcessInfo(pid, name, cpu_percent, memory_mb))
                
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                # Skip processes that disappear or can't be accessed
                continue
    
    except Exception as e:
        raise RuntimeError(f"Error collecting process information: {e}")
    
    # Sort by combined resource usage in descending order and return top N
    processes.sort(key=lambda x: x.cpu_percent + x.memory_mb, reverse=True)
    
    return processes[:n]

def format_file_size(size_mb):
    """
    Convert MB to human readable format.
    
    Args:
        size_mb: Size in MB
        
    Returns:
        str: Human readable file size
    """
    if size_mb == 0:
        return "0 MB"
    
    size_names = ["MB", "GB", "TB"]
    i = 0
    while size_mb >= 1024 and i < len(size_names) - 1:
        size_mb /= 1024
        i += 1
    
    return f"{size_mb:.1f} {size_names[i]}"

def main():
    if len(sys.argv) < 2:
        print("Usage: list_most_intensive_processes.py <number_of_processes> [min_memory_mb]")
        sys.exit(1)
    
    try:
        n = int(sys.argv[1])
        if n <= 0:
            raise ValueError
    except ValueError:
        print("Error: Number of processes must be a positive integer")
        sys.exit(1)
    
    min_memory_mb = 0.0
    if len(sys.argv) >= 3:
        try:
            min_memory_mb = float(sys.argv[2])
        except ValueError:
            print("Error: Minimum memory must be a number")
            sys.exit(1)
    
    try:
        intensive_processes = get_most_intensive_processes(n, min_memory_mb)
        
        if not intensive_processes:
            print(f"No processes found with minimum memory threshold of {min_memory_mb} MB")
            return
        
        print(f"Top {n} most intensive processes (by CPU + Memory):")
        print("-" * 80)
        print(f"{'Rank':<4} {'PID':<8} {'CPU%':<8} {'Memory':<12} {'Process Name'}")
        print("-" * 80)
        
        for i, proc in enumerate(intensive_processes, 1):
            memory_str = format_file_size(proc.memory_mb)
            print(f"{i:<4} {proc.pid:<8} {proc.cpu_percent:<8.1f} {memory_str:<12} {proc.name}")
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()