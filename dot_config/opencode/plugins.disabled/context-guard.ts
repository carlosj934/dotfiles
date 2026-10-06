import type { Plugin } from "@opencode-ai/plugin"

// Thresholds as a fraction of the model's context window.
const WARN_AT = 0.7 // heads-up: suggest compressing soon
const ALERT_AT = 0.85 // strong nudge: compress now or start a new session

type Providers = Awaited<ReturnType<typeof loadProviders>>

async function loadProviders(client: any) {
  const { providers } = await client.config.providers()
  const byId: Record<string, any> = {}
  for (const p of providers) byId[p.id] = p
  return byId
}

// Tracks which thresholds have already fired per session, so we only alert once per level.
const firedThresholds = new Map<string, Set<number>>()

export const ContextGuardPlugin: Plugin = async ({ client }) => {
  let providers: Providers | undefined

  return {
    event: async ({ event }) => {
      if (event.type === "session.compacted") {
        // Usage dropped after compaction; allow thresholds to fire again.
        firedThresholds.delete(event.properties.sessionID)
        return
      }

      if (event.type !== "message.updated") return
      const info = event.properties.info
      if (info.role !== "assistant") return
      if (!info.tokens || !info.time?.completed) return

      // Tokens actually sent to the model this turn: new input + everything read/written to cache.
      const used = info.tokens.input + info.tokens.cache.read + info.tokens.cache.write
      if (!used) return

      if (!providers) providers = await loadProviders(client)
      const model = providers[info.providerID]?.models?.[info.modelID]
      const contextLimit = model?.limit?.context
      if (!contextLimit) return

      const pct = used / contextLimit
      const seen = firedThresholds.get(info.sessionID) ?? new Set<number>()
      firedThresholds.set(info.sessionID, seen)

      const notify = async (threshold: number, variant: "warning" | "error", message: string) => {
        if (seen.has(threshold)) return
        seen.add(threshold)

        await client.tui.showToast({
          body: { title: "Context window", message, variant },
        })

        // Add a no-reply transcript note so the agent offers to compress on its next turn.
        await client.session.prompt({
          path: { id: info.sessionID },
          body: {
            noReply: true,
            parts: [
              {
                type: "text",
                text: `<system-reminder>${message} On your next turn, proactively offer to run \`compress\` on stale messages, or suggest starting a new session if the current task is wrapping up.</system-reminder>`,
              },
            ],
          },
        })
      }

      if (pct >= ALERT_AT) {
        await notify(
          ALERT_AT,
          "error",
          `Context ~${Math.round(pct * 100)}% full (${used.toLocaleString()}/${contextLimit.toLocaleString()} tokens).`,
        )
      } else if (pct >= WARN_AT) {
        await notify(
          WARN_AT,
          "warning",
          `Context ~${Math.round(pct * 100)}% full (${used.toLocaleString()}/${contextLimit.toLocaleString()} tokens).`,
        )
      }
    },
  }
}
