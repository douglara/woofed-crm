// Three bouncing dots shown while the agent is producing its first token.
const AgentThinkingLoader = () => (
  <div className="flex items-center gap-1" aria-label="Agent is thinking">
    {[0, 1, 2].map((i) => (
      <span
        key={i}
        className="size-1.5 animate-bounce rounded-full bg-muted-foreground"
        style={{ animationDelay: `${i * 0.15}s` }}
      />
    ))}
  </div>
)

export default AgentThinkingLoader
