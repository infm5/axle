<script setup lang="ts">
import CodeCarousel from './CodeCarousel.vue'
</script>

<template>
  <div class="ax-hero">
    <div class="ax-banner">
      v0.2.0 docs · Relic, Shelf &amp; Serverpod adapters
      <a href="/guide/roadmap">View roadmap →</a>
    </div>
    <div class="ax-grid">
      <div class="ax-left">
        <div class="ax-version">☆ axle v0.2.0 — OpenAPI 3.1 for Dart</div>
        <h1 class="ax-title">
          Document Dart APIs.<br />
          <span>Without the drift.</span>
        </h1>
        <p class="ax-sub">
          Annotate your routes once — get a verified OpenAPI 3.1 spec with
          security schemes, response headers, cookies, media types, constraints,
          and discriminators, plus hosted Swagger UI on every adapter.
        </p>
        <div class="ax-cta">
          <a class="ax-btn-primary" href="/guide/getting-started">Get Started <span>→</span></a>
          <a class="ax-btn-ghost" href="https://github.com/infm5/axle">
            <svg viewBox="0 0 16 16" width="16" height="16" fill="currentColor" aria-hidden="true"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27s1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8Z"/></svg>
            on GitHub
          </a>
        </div>
      </div>
      <div class="ax-right">
        <CodeCarousel />
      </div>
    </div>
  </div>
</template>

<style scoped>
.ax-hero {
  width: 100vw;
  margin-left: calc(50% - 50vw);
  background: var(--ax-bg);
  color: var(--ax-text);
  font-family: var(--ax-body);
}
.ax-banner {
  text-align: center;
  font-family: var(--ax-mono);
  font-size: 13px;
  padding: 10px 16px;
  background: var(--ax-accent);
  color: #0a0e13;
}
.ax-banner a {
  color: #0a0e13;
  font-weight: 600;
  margin-left: 12px;
  text-decoration: underline;
}
.ax-grid {
  display: grid;
  grid-template-columns: 1fr 1.2fr;
  gap: 48px;
  max-width: 1200px;
  margin: 0 auto;
  padding: 72px 32px 56px;
  align-items: center;
}
.ax-version {
  display: inline-block;
  font-family: var(--ax-mono);
  font-size: 12.5px;
  color: var(--ax-accent);
  border: 1px solid var(--ax-accent-dim);
  border-radius: 999px;
  padding: 5px 16px;
  margin-bottom: 28px;
}
.ax-title {
  font-family: var(--ax-display);
  font-size: clamp(40px, 5vw, 60px);
  line-height: 1.08;
  letter-spacing: -0.02em;
  font-weight: 700;
  margin: 0 0 24px;
  color: #fff;
}
.ax-title span {
  color: var(--ax-accent);
}
.ax-sub {
  font-size: 16.5px;
  line-height: 1.75;
  color: #aab4c0;
  margin: 0 0 32px;
  max-width: 34rem;
}
.ax-cta {
  display: flex;
  gap: 14px;
  margin-bottom: 22px;
  flex-wrap: wrap;
}
.ax-btn-primary {
  font-family: var(--ax-body);
  font-weight: 600;
  font-size: 15px;
  background: var(--ax-btn);
  color: #0a0e13;
  border-radius: 10px;
  padding: 12px 26px;
  text-decoration: none;
}
.ax-btn-primary span {
  margin-left: 6px;
}
.ax-btn-primary:hover {
  filter: brightness(1.08);
}
.ax-btn-ghost {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  font-weight: 500;
  color: var(--ax-text);
  border: 1px solid var(--ax-border);
  border-radius: 10px;
  padding: 12px 22px;
  text-decoration: none;
}
.ax-btn-ghost:hover {
  border-color: var(--ax-accent-dim);
}
@media (max-width: 960px) {
  .ax-grid {
    grid-template-columns: 1fr;
    padding-top: 52px;
  }
}
</style>
