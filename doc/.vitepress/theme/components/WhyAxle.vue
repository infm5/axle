<template>
  <div class="ax-why">
    <div class="ax-eyebrow">Why axle</div>
    <h2 class="ax-heading">One contract. Every framework.</h2>
    <div class="ax-cards">
      <div class="ax-card">
        <div class="ax-card-t">Framework-Agnostic Core</div>
        <div class="ax-card-d">Annotations, the OpenAPI 3.1 document model, and AxleDocs. Zero framework imports.</div>
      </div>
      <div class="ax-card">
        <div class="ax-card-t">Static Generation</div>
        <div class="ax-card-d">The CLI resolves @ApiRoute via package:analyzer and emits JSON, YAML, UI assets, and a const String. Deterministic, AOT-safe.</div>
      </div>
      <div class="ax-card">
        <div class="ax-card-t">Thin Adapters</div>
        <div class="ax-card-d">Adapters map AxleDocs to framework responses. Security schemes, headers, cookies, and media types pass through unchanged.</div>
      </div>
      <div class="ax-card">
        <div class="ax-card-t">Self-Hosted Docs</div>
        <div class="ax-card-d">gen vendors Swagger UI 5.34.0 into your project. Serve it locally, or fall back to the pinned CDN with SRI.</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.ax-why {
  width: 100vw;
  margin-left: calc(50% - 50vw);
  background: var(--ax-bg);
  color: var(--ax-text);
  font-family: var(--ax-body);
  text-align: center;
  padding: 24px 32px 72px;
}
.ax-eyebrow {
  font-family: var(--ax-mono);
  font-size: 12px;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--ax-accent);
  margin-bottom: 16px;
}
.ax-heading {
  font-family: var(--ax-display);
  font-size: clamp(28px, 3.4vw, 40px);
  font-weight: 700;
  letter-spacing: -0.02em;
  color: #fff;
  margin: 0 0 44px;
}
.ax-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  max-width: 1200px;
  margin: 0 auto;
  text-align: left;
}
.ax-card {
  border: 1px solid var(--ax-border);
  border-radius: 12px;
  background: var(--ax-card);
  padding: 22px;
}
.ax-card-t {
  font-family: var(--ax-display);
  font-weight: 600;
  font-size: 16px;
  color: #fff;
  margin-bottom: 10px;
}
.ax-card-d {
  font-size: 14px;
  line-height: 1.7;
  color: var(--ax-muted);
}
@media (max-width: 960px) {
  .ax-cards {
    grid-template-columns: 1fr 1fr;
  }
}
@media (max-width: 640px) {
  .ax-cards {
    grid-template-columns: 1fr;
  }
}
</style>
