// Three blinking dots shown while the agent prepares its first token.
const AgentThinkingLoader = () => (
  <div className="flex items-center gap-1 py-1" aria-label="Woofed AI is thinking">
    {[0, 1, 2].map((i) => (
      <span
        key={i}
        className="size-[7px] rounded-full color-bg-fill-highlight"
        style={{ animation: `wfBlink 1.2s ${i * 0.18}s infinite ease-in-out` }}
      />
    ))}
  </div>
)

export default AgentThinkingLoader
