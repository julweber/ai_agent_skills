/**
 * Model Config Extension
 *
 * Allows configuring model sampling parameters: temperature, top_p, top_k,
 * min_p, and repeat_penalty. Settings are applied to every LLM request via
 * the before_provider_request event.
 *
 * Configuration is loaded from JSON files (merged, project overrides global):
 * - ~/.pi/agent/model-config.json  (global)
 * - <cwd>/.pi/model-config.json    (project-local)
 *
 * Example model-config.json:
 * ```json
 * {
 *   "temperature": 0.7,
 *   "top_p": 0.9,
 *   "top_k": 40,
 *   "min_p": 0.05,
 *   "repeat_penalty": 1.1
 * }
 * ```
 *
 * All fields are optional. Only specified fields are injected into the
 * provider request payload. Unset fields use the provider's defaults.
 *
 * Usage:
 * - `/model-config`              — open interactive settings editor
 * - `/model-config show`         — display current configuration
 * - `/model-config reset`        — reset all values to defaults (unset)
 * - `/model-config <key> <val>`  — set a single parameter, e.g. `/model-config temperature 0.5`
 *
 * The current configuration is displayed as a status widget and persists
 * across session reloads via session entries.
 */

import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { getSettingsListTheme } from "@mariozechner/pi-coding-agent";
import { Container, type SettingItem, SettingsList, Text } from "@mariozechner/pi-tui";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ModelConfig {
  temperature?: number;
  top_p?: number;
  top_k?: number;
  min_p?: number;
  repeat_penalty?: number;
}

/** Parameter metadata for validation and UI. */
interface ParamMeta {
  label: string;
  min: number;
  max: number;
  step: number;
  decimals: number;
  description: string;
}

const PARAM_META: Record<keyof ModelConfig, ParamMeta> = {
  temperature: {
    label: "Temperature",
    min: 0,
    max: 2,
    step: 0.1,
    decimals: 2,
    description: "Controls randomness. 0 = deterministic, higher = more creative.",
  },
  top_p: {
    label: "Top P",
    min: 0,
    max: 1,
    step: 0.05,
    decimals: 2,
    description: "Nucleus sampling. Considers tokens with cumulative probability ≤ top_p.",
  },
  top_k: {
    label: "Top K",
    min: 0,
    max: 500,
    step: 5,
    decimals: 0,
    description: "Limits token selection to the top K most probable tokens.",
  },
  min_p: {
    label: "Min P",
    min: 0,
    max: 1,
    step: 0.01,
    decimals: 2,
    description: "Minimum probability threshold relative to the top token.",
  },
  repeat_penalty: {
    label: "Repeat Penalty",
    min: 0,
    max: 2,
    step: 0.05,
    decimals: 2,
    description: "Penalizes repeated tokens. 1.0 = no penalty, higher = less repetition.",
  },
};

const PARAM_KEYS = Object.keys(PARAM_META) as (keyof ModelConfig)[];
const UNSET = "(default)";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function loadConfigFile(path: string): ModelConfig {
  if (!existsSync(path)) return {};
  try {
    const raw = JSON.parse(readFileSync(path, "utf-8"));
    const config: ModelConfig = {};
    for (const key of PARAM_KEYS) {
      if (typeof raw[key] === "number") {
        config[key] = raw[key];
      }
    }
    return config;
  } catch (err) {
    console.error(`model-config: failed to load ${path}: ${err}`);
    return {};
  }
}

function loadConfigFromFiles(cwd: string): ModelConfig {
  const globalPath = join(homedir(), ".pi", "agent", "model-config.json");
  const projectPath = join(cwd, ".pi", "model-config.json");
  return { ...loadConfigFile(globalPath), ...loadConfigFile(projectPath) };
}

function formatValue(key: keyof ModelConfig, value: number | undefined): string {
  if (value === undefined) return UNSET;
  return value.toFixed(PARAM_META[key].decimals);
}

function configSummary(config: ModelConfig): string {
  const parts: string[] = [];
  for (const key of PARAM_KEYS) {
    if (config[key] !== undefined) {
      parts.push(`${key}=${formatValue(key, config[key])}`);
    }
  }
  return parts.length > 0 ? parts.join(" ") : "all defaults";
}

function parseValue(key: keyof ModelConfig, raw: string): number | undefined {
  if (raw === UNSET || raw.toLowerCase() === "default" || raw === "") return undefined;
  const n = Number(raw);
  if (Number.isNaN(n)) return undefined;
  const meta = PARAM_META[key];
  return Math.round(Math.min(meta.max, Math.max(meta.min, n)) * 10 ** meta.decimals) / 10 ** meta.decimals;
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function modelConfigExtension(pi: ExtensionAPI) {
  let config: ModelConfig = {};

  // ------- Persistence -------

  function persistState() {
    pi.appendEntry<ModelConfig>("model-config-state", { ...config });
  }

  function restoreFromBranch(ctx: ExtensionContext) {
    const branch = ctx.sessionManager.getBranch();
    let saved: ModelConfig | undefined;
    for (const entry of branch) {
      if (entry.type === "custom" && entry.customType === "model-config-state") {
        saved = entry.data as ModelConfig | undefined;
      }
    }
    if (saved) {
      config = {};
      for (const key of PARAM_KEYS) {
        if (typeof (saved as Record<string, unknown>)[key] === "number") {
          config[key] = (saved as Record<string, unknown>)[key] as number;
        }
      }
    }
  }

  // ------- Status -------

  function updateStatus(ctx: ExtensionContext) {
    const summary = configSummary(config);
    if (summary === "all defaults") {
      ctx.ui.setStatus("model-config", undefined);
    } else {
      ctx.ui.setStatus("model-config", ctx.ui.theme.fg("dim", `⚙ ${summary}`));
    }
  }

  // ------- Provider payload injection -------

  pi.on("before_provider_request", (event) => {
    const payload = event.payload as Record<string, unknown> | undefined;
    if (!payload) return;

    const patch: Record<string, unknown> = {};

    if (config.temperature !== undefined) patch.temperature = config.temperature;
    if (config.top_p !== undefined) patch.top_p = config.top_p;
    if (config.top_k !== undefined) patch.top_k = config.top_k;
    if (config.min_p !== undefined) patch.min_p = config.min_p;

    // repeat_penalty is named differently across providers:
    //   OpenAI-compatible: frequency_penalty
    //   Anthropic: not directly supported (ignored gracefully)
    //   Ollama / llama.cpp: repeat_penalty or repetition_penalty
    if (config.repeat_penalty !== undefined) {
      patch.frequency_penalty = config.repeat_penalty;
      patch.repeat_penalty = config.repeat_penalty;
      patch.repetition_penalty = config.repeat_penalty;
    }

    if (Object.keys(patch).length === 0) return;

    return { ...payload, ...patch };
  });

  // ------- Interactive settings editor -------

  async function showEditor(ctx: ExtensionContext): Promise<void> {
    await ctx.ui.custom((tui, theme, _kb, done) => {
      function buildItems(): SettingItem[] {
        return PARAM_KEYS.map((key) => {
          const meta = PARAM_META[key];
          const values = [UNSET];
          // Build a range of values for cycling
          for (let v = meta.min; v <= meta.max + meta.step / 2; v += meta.step) {
            const rounded = Math.round(v * 10 ** meta.decimals) / 10 ** meta.decimals;
            values.push(rounded.toFixed(meta.decimals));
          }
          return {
            id: key,
            label: `${meta.label}  ${theme.fg("dim", meta.description)}`,
            currentValue: formatValue(key, config[key]),
            values,
          };
        });
      }

      const container = new Container();

      container.addChild(
        new (class {
          render(_width: number) {
            return [
              theme.fg("accent", theme.bold("Model Configuration")),
              theme.fg("dim", `Current: ${configSummary(config)}`),
              "",
            ];
          }
          invalidate() {}
        })(),
      );

      const settingsList = new SettingsList(
        buildItems(),
        PARAM_KEYS.length + 2,
        getSettingsListTheme(),
        (id, newValue) => {
          const key = id as keyof ModelConfig;
          const parsed = parseValue(key, newValue);
          if (parsed === undefined) {
            delete config[key];
          } else {
            config[key] = parsed;
          }
          persistState();
          updateStatus(ctx);
        },
        () => done(undefined),
      );

      container.addChild(settingsList);

      container.addChild(
        new (class {
          render(_width: number) {
            return [
              "",
              theme.fg("dim", "← → change value • ↑ ↓ navigate • esc close"),
            ];
          }
          invalidate() {}
        })(),
      );

      return {
        render(width: number) {
          return container.render(width);
        },
        invalidate() {
          container.invalidate();
        },
        handleInput(data: string) {
          settingsList.handleInput?.(data);
          tui.requestRender();
        },
      };
    });
  }

  // ------- Command -------

  pi.registerCommand("model-config", {
    description: "Configure model sampling parameters (temperature, top_p, top_k, min_p, repeat_penalty)",
    handler: async (args, ctx) => {
      const trimmed = args?.trim() ?? "";

      // /model-config show
      if (trimmed === "show") {
        const lines: string[] = ["Model Configuration:"];
        for (const key of PARAM_KEYS) {
          const meta = PARAM_META[key];
          const val = formatValue(key, config[key]);
          lines.push(`  ${meta.label}: ${val}`);
        }
        ctx.ui.notify(lines.join("\n"), "info");
        return;
      }

      // /model-config reset
      if (trimmed === "reset") {
        config = {};
        persistState();
        updateStatus(ctx);
        ctx.ui.notify("Model config reset to defaults", "info");
        return;
      }

      // /model-config <key> <value>
      const parts = trimmed.split(/\s+/);
      if (parts.length === 2) {
        const key = parts[0] as keyof ModelConfig;
        if (PARAM_KEYS.includes(key)) {
          const parsed = parseValue(key, parts[1]);
          if (parsed === undefined && parts[1].toLowerCase() !== "default") {
            ctx.ui.notify(`Invalid value for ${key}: ${parts[1]}`, "error");
            return;
          }
          if (parsed === undefined) {
            delete config[key];
          } else {
            config[key] = parsed;
          }
          persistState();
          updateStatus(ctx);
          ctx.ui.notify(`${PARAM_META[key].label} set to ${formatValue(key, parsed)}`, "info");
          return;
        }
      }

      // No arguments or unrecognised — open interactive editor
      await showEditor(ctx);
    },
  });

  // ------- Lifecycle -------

  pi.on("session_start", async (_event, ctx) => {
    // Load from config files first
    config = loadConfigFromFiles(ctx.cwd);

    // Override with session-persisted state (branch-aware)
    restoreFromBranch(ctx);

    updateStatus(ctx);
  });

  pi.on("session_tree", async (_event, ctx) => {
    restoreFromBranch(ctx);
    updateStatus(ctx);
  });

  pi.on("session_fork", async (_event, ctx) => {
    restoreFromBranch(ctx);
    updateStatus(ctx);
  });
}
