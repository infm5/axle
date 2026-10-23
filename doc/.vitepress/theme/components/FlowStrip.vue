<template>
  <div class="ax-flow">
    <div class="ax-flow-inner">
      <div class="ax-steps">
        <div class="ax-step"><span>1</span><code>dart run axle_cli:axle init</code></div>
        <div class="ax-step"><span>2</span><code>dart run axle_cli:axle gen</code></div>
        <div class="ax-step"><span>3</span><code>dart run axle_cli:axle gen --check</code><em>in CI</em></div>
      </div>
      <div class="ax-links">
        <a href="/guide/how-it-works">How It Works →</a>
        <a href="/packages/">Packages →</a>
        <a href="/adapters/building-an-adapter">Build an Adapter →</a>
        <a href="/reference/axle-yaml">axle.yaml Reference →</a>
      </div>
    </div>
  </div>
</template>

<style scoped>
.ax-flow {
  width: 100vw;
  margin-left: calc(50% - 50vw);
  background: var(--ax-bg-soft);
  border-top: 1px solid var(--ax-border);
  font-family: var(--ax-body);
  padding: 48px 32px;
}
.ax-flow-inner {
  max-width: 1200px;
  margin: 0 auto;
}
.ax-steps {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 28px;
}
.ax-step {
  display: flex;
  align-items: center;
  gap: 12px;
  border: 1px solid var(--ax-border);
  background: var(--ax-card);
  border-radius: 10px;
  padding: 14px 18px;
}
.ax-step span {
  font-family: var(--ax-display);
  font-weight: 700;
  color: var(--ax-accent);
  font-size: 18px;
}
.ax-step code {
  font-family: var(--ax-mono);
  font-size: 13px;
  color: var(--ax-text);
  background: none;
  padding: 0;
}
.ax-step em {
  font-size: 12px;
  color: var(--ax-muted);
  font-style: normal;
  margin-left: auto;
}
.ax-links {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
}
.ax-links a {
  font-size: 14.5px;
  font-weight: 600;
  color: var(--ax-accent);
  text-decoration: none;
}
.ax-links a:hover {
  text-decoration: underline;
}
@media (max-width: 960px) {
  .ax-steps {
    grid-template-columns: 1fr;
  }
}
</style>
