---
name: llama-cpp
description: Expert helper for llama.cpp tooling including llama-server and llama-cli. Manages local LLM inference with GPU acceleration, model loading from Hugging Face/Docker Hub, and fine-tuned generation parameters. Use when running or configuring local LLM servers via llama-server, executing prompts with llama-cli, or optimizing model performance.
---

# llama-cpp Skill

You are an expert on llama.cpp tooling and local LLM inference. You help users run, configure, and optimize `llama-server` and `llama-cli` for local language model execution.

## Available Tools

### llama-server
Runs a HTTP server for LLM inference. Best for:
- API-based applications
- Persistent model loading
- Multi-client access
- Integration with other tools

### llama-cli  
Direct command-line prompt execution. Best for:
- Quick testing and experimentation
- Single-shot completions
- Interactive chat sessions
- Scripted generation tasks

## Common Use Cases

### 1. Start a Local LLM Server

```bash
# Basic server with Hugging Face model
llama-server --hf-repo unsloth/phi-4-GGUF:q4_k_m -ngl auto

# Load local GGUF model
llama-server --model /path/to/model.gguf -c 8192 -ngl all

# Server on custom port with GPU offloading
llama-server --port 8080 --host 0.0.0.0 \
  --hf-repo bartowski/Llama-3.2-3B-Instruct-GGUF:Llama-3.2-3B-Instruct-Q4_K_M.gguf \
  -ngl auto -fa on

# Limit context and output tokens
llama-server --model model.gguf -c 4096 -np 1
```

**Key Server Parameters:**
- `--hf-repo <user>/<model>:<quant>` - Load from Hugging Face (e.g., `unsloth/phi-4-GGUF:q4_k_m`)
- `--docker-repo [<repo>/]<model>[:quant]` - Load from Docker Hub (e.g., `gemma3`)
- `--model <path>` - Local GGUF file path
- `-ngl, --gpu-layers N` - GPU layer offloading (`auto`, `all`, or number)
- `-c, --ctx-size N` - Context window size (default: model's native)
- `-b, --batch-size N` - Logical batch size (default: 2048)
- `-ub, --ubatch-size N` - Physical batch size (default: 512)
- `--port N` - Server port (default: 8080)
- `--host HOST` - Bind address (default: localhost)
- `-fa, --flash-attn [on|off|auto]` - Flash attention enabled
- `-sm, --split-mode {none,layer,row}` - Multi-GPU splitting

### 2. Run Direct Inference with llama-cli

```bash
# Simple prompt completion
llama-cli --model model.gguf -p "Explain quantum computing" -n 512

# Interactive chat mode
llama-cli --model model.gguf -i --chat-mode chat

# Load from Hugging Face directly
llama-cli --hf-repo unsloth/phi-4-GGUF:q4_k_m \
  -p "Write a haiku about programming" -n 256

# Read prompt from file
llama-cli --model model.gguf -f prompt.txt -n 1024

# System message + user prompt
llama-cli --model model.gguf -sys "You are a helpful assistant." \
  -p "What is the capital of France?"
```

**Key CLI Parameters:**
- `-p, --prompt` - Input text for generation
- `-sys` - System message (for chat)
- `-f, --file <path>` - Read prompt from file
- `-n, --predict N` - Tokens to generate (-1 = unlimited)
- `-i, --interactive` - Interactive mode
- `--chat-mode {none,chat,chat-map}` - Chat interaction mode

### 3. Performance Optimization

```bash
# Maximum GPU offloading (best performance on dedicated GPU)
llama-server --model model.gguf -ngl all -fa on -sm layer

# CPU-only fallback (no GPU available)
llama-server --model model.gguf -ngl 0 -t 8

# Multi-GPU splitting (2 GPUs, split layers evenly)
llama-server --model model.gguf -ngl auto -sm layer -ts 1,1

# Optimize for low VRAM with quantized KV cache
llama-server --model model.gguf -ctk q4_0 -ctv q4_0 -ngl auto

# High throughput batching
llama-server --model model.gguf -b 4096 -ub 1024 -np 4
```

**Performance Parameters:**
- `-ngl, --gpu-layers N` - Layers offloaded to GPU (`auto`, `all`, or count)
- `-sm, --split-mode {none,layer,row}` - Multi-GPU strategy
- `-ts, --tensor-split N0,N1,...` - Per-GPU proportions (e.g., `3,1`)
- `-fa, --flash-attn [on|off|auto]` - Flash attention for speed/memory
- `-ctk, --cache-type-k TYPE` - KV cache type for K (f16, q4_0, etc.)
- `-ctv, --cache-type-v TYPE` - KV cache type for V
- `-t, --threads N` - CPU threads for generation
- `-tb, --threads-batch N` - Threads for batch processing

### 4. Generation Quality Tuning

```bash
# Creative writing (higher temperature, more diverse)
llama-server --model model.gguf \
  --temp 0.8 --top-k 40 --top-p 0.95 --min-p 0.05

# Precise factual answers (lower temp, focused sampling)
llama-server --model model.gguf \
  --temp 0.1 --top-k 20 --top-p 0.8 --min-p 0.1

# JSON output with schema constraints
llama-server --model model.gguf \
  -j '{"type":"object","properties":{"name":{"type":"string"}}}' \
  --temp 0.1

# Mirostat sampling (adaptive perplexity control)
llama-server --model model.gguf \
  --mirostat 2 --mirostat-lr 0.1 --mirostat-ent 5.0
```

**Sampling Parameters:**
- `--temp, --temperature N` - Generation randomness (default: 0.8)
- `--top-k N` - Top-k sampling (40 = default, 0 = disabled)
- `--top-p N` - Nucleus sampling (0.95 = default, 1.0 = disabled)
- `--min-p N` - Minimum probability threshold (0.05 = default)
- `--repeat-penalty N` - Penalize repetition (1.0 = disabled)
- `--presence-penalty N` - Presence-based penalty (0.0 = default)
- `--frequency-penalty N` - Frequency-based penalty (0.0 = default)
- `--mirostat N` - Mirostat sampling (0=disabled, 1=v1, 2=v2)

### 5. Advanced Features

```bash
# Load LoRA adapter with base model
llama-server --model base.gguf \
  --lora /path/to/lora-adapter.gguf

# Multiple LoRA adapters with scaling
llama-server --model base.gguf \
  --lora-scaled lora1.gguf:0.7,lora2.gguf:0.3

# Override model metadata (e.g., disable BOS token)
llama-server --model model.gguf \
  --override-kv tokenizer.ggml.add_bos_token=bool:false

# List available GPU devices
llama-server --list-devices

# Show models in cache
llama-server --cache-list

# Run with Vulkan backend (AMD GPUs)
llama-server --model model.gguf --device vulkan -ngl auto
```

**Advanced Parameters:**
- `--lora <path>` - Load LoRA adapter
- `--lora-scaled FNAME:SCALE,...` - Scaled LoRA adapters
- `--override-kv KEY=TYPE:VALUE,...` - Override model metadata
- `--device <dev1,dev2,...>` - Specify devices (use `--list-devices`)
- `-mg, --main-gpu INDEX` - Main GPU for split operations

## GPU Configuration Reference

### NVIDIA GPUs
```bash
# Automatic detection and offloading
llama-server --model model.gguf -ngl auto -fa on

# Specific layer count (tune based on VRAM)
llama-server --model model.gguf -ngl 35  # Adjust for your GPU

# Multi-GPU with tensor splitting
llama-server --model model.gguf -sm layer -ts 2,1  # 2:1 ratio
```

### AMD GPUs (Vulkan)
```bash
# Vulkan backend automatically detected
llama-server --model model.gguf -ngl auto -fa on

# List Vulkan devices
llama-server --list-devices

# Force specific device
llama-server --model model.gguf --device vulkan:0 -ngl auto
```

### Apple Silicon (Metal)
```bash
# Metal backend is automatic on macOS
llama-server --model model.gguf -ngl all -fa on

# Check available memory and adjust context
llama-server --model model.gguf -c 8192 -ngl all
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `LLAMA_ARG_THREADS` | CPU threads | `export LLAMA_ARG_THREADS=8` |
| `LLAMA_ARG_CTX_SIZE` | Context size | `export LLAMA_ARG_CTX_SIZE=4096` |
| `HF_TOKEN` | Hugging Face token | `export HF_TOKEN=hf_...` |
| `LLAMA_OFFLINE` | Offline mode (no network) | `export LLAMA_OFFLINE=1` |

## Troubleshooting

### Model not found from Hugging Face
```bash
# Check model exists and quantization tag is correct
llama-server --hf-repo unsloth/phi-4-GGUF:q4_k_m  # Try different quant

# List available files in repo first (manual check)
# Or try without quant tag to see defaults
llama-server --hf-repo unsloth/phi-4-GGUF
```

### Out of memory errors
```bash
# Reduce GPU layers or context size
llama-server --model model.gguf -ngl 20 -c 2048

# Use quantized KV cache
llama-server --model model.gguf -ctk q4_0 -ctv q4_0

# Offload less to GPU, more to CPU
llama-server --model model.gguf -ngl 10 -t 16
```

### Slow generation speeds
```bash
# Enable flash attention
llama-server --model model.gguf -fa on -ngl auto

# Increase batch size
llama-server --model model.gguf -b 4096 -ub 1024

# Ensure GPU offloading is active (check logs)
llama-server --model model.gguf -ngl all -v
```

## Testing Your Setup

```bash
# Quick smoke test with small generation
llama-cli --hf-repo unsloth/phi-4-GGUF:q4_k_m \
  -p "Hello, write a short poem" -n 50

# Verify GPU offloading in server logs
llama-server --model model.gguf -ngl all &
# Check output for "offloaded X/Y layers to GPU"

# Benchmark inference speed
llama-cli --model model.gguf -p "Test prompt" -n 1024 --perf
```

## Common Server Endpoints (when running llama-server)

When `llama-server` is running, it exposes:
- `POST /completion` - Generate completion
- `POST /chat/completions` - Chat completions (OpenAI-compatible)
- `GET /models` - List loaded models
- `GET /health` - Health check

Example chat request:
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "default",
    "messages": [
      {"role": "system", "content": "You are helpful."},
      {"role": "user", "content": "Hello!"}
    ],
    "temperature": 0.7,
    "max_tokens": 256
  }'
```

## Best Practices

1. **Start with `auto` GPU layers**: Let llama.cpp decide optimal offloading
2. **Enable flash attention** when available: Better memory and speed
3. **Use quantized models** (Q4_K_M, Q5_K_M): Good quality/speed balance
4. **Tune context size** for your use case: Chat needs more, Q&A less
5. **Monitor VRAM usage**: Adjust `-ngl` if you hit OOM errors
6. **Use `--offline` mode** when models are cached to prevent network calls
