# Model Config Extension

Configure model sampling parameters for the pi coding agent: **temperature**, **top_p**, **top_k**, **min_p**, and **repeat_penalty**.

## Installation

Copy or symlink the `model-config` directory into one of pi's extension discovery locations:

```bash
# Global
cp -r model-config ~/.pi/agent/extensions/model-config

# Project-local
cp -r model-config .pi/extensions/model-config
```

Or add it to your `settings.json`:

```json
{
  "extensions": ["/path/to/model-config"]
}
```

## Configuration

Create a JSON config file at one (or both) of these paths:

| Path | Scope |
|------|-------|
| `~/.pi/agent/model-config.json` | Global (all projects) |
| `<project>/.pi/model-config.json` | Project-local (overrides global) |

### Example `model-config.json`

```json
{
  "temperature": 0.7,
  "top_p": 0.9,
  "top_k": 40,
  "min_p": 0.05,
  "repeat_penalty": 1.1
}
```

All fields are **optional**. Only specified fields are injected into the provider request. Unset fields use the provider's own defaults.

## Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `temperature` | 0 – 2 | Provider default | Controls randomness. 0 = deterministic, higher = more creative. |
| `top_p` | 0 – 1 | Provider default | Nucleus sampling. Considers tokens with cumulative probability ≤ top_p. |
| `top_k` | 0 – 500 | Provider default | Limits token selection to the top K most probable tokens. |
| `min_p` | 0 – 1 | Provider default | Minimum probability threshold relative to the top token. |
| `repeat_penalty` | 0 – 2 | Provider default | Penalizes repeated tokens. 1.0 = no penalty, higher = less repetition. |

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `/model-config` | Open interactive settings editor |
| `/model-config show` | Display current configuration |
| `/model-config reset` | Reset all values to provider defaults |
| `/model-config <key> <value>` | Set a single parameter |

### Examples

```
/model-config temperature 0.5
/model-config top_p 0.95
/model-config top_k default
/model-config show
/model-config reset
```

### Interactive Editor

Running `/model-config` without arguments opens a settings UI where you can cycle through values with arrow keys:

- **← →** Change value
- **↑ ↓** Navigate parameters
- **Esc** Close editor

## Status Display

When any parameter is set to a non-default value, a status indicator appears in the footer:

```
⚙ temperature=0.70 top_p=0.90
```

The indicator disappears when all parameters are at their defaults.

## Persistence

Configuration changes made via `/model-config` are persisted in the session and survive restarts. They are also branch-aware — navigating the session tree or forking restores the configuration from that branch point.

Config files (`model-config.json`) are loaded on session start and serve as the base. Session-persisted values override file values.

## Provider Compatibility

The extension injects parameters directly into the provider request payload. Different providers support different subsets:

| Parameter | OpenAI | Anthropic | Ollama / llama.cpp | Google |
|-----------|--------|-----------|-------------------|--------|
| `temperature` | ✅ | ✅ | ✅ | ✅ |
| `top_p` | ✅ | ✅ | ✅ | ✅ |
| `top_k` | ❌ | ✅ | ✅ | ✅ |
| `min_p` | ❌ | ❌ | ✅ | ❌ |
| `repeat_penalty` | ✅ (`frequency_penalty`) | ❌ | ✅ | ❌ |

Unsupported parameters are typically ignored gracefully by the provider.

For `repeat_penalty`, the extension sets all common field names (`frequency_penalty`, `repeat_penalty`, `repetition_penalty`) so it works across different API formats.
