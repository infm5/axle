<script setup lang="ts">
import { ref } from 'vue'

interface Step {
  title: string
  code: string
}

interface Tab {
  id: string
  label: string
  icon: string
  steps: Step[]
}

const tabs: Tab[] = [
  {
    id: 'relic',
    label: 'Relic',
    icon: '/relic.png',
    steps: [
      {
        title: 'Add dependencies',
        code: `<span class="tk-param">dependencies</span>:
  <span class="tk-param">axle_relic</span>: <span class="tk-str">^0.2.0</span>
  <span class="tk-param">relic</span>: <span class="tk-str">^2.0.0-rc.2</span>
<span class="tk-param">dev_dependencies</span>:
  <span class="tk-param">axle_cli</span>: <span class="tk-str">^0.2.0</span>`,
      },
      {
        title: 'Create axle.yaml',
        code: `<span class="tk-prompt">$</span> dart run axle_cli:axle init`,
      },
      {
        title: 'Annotate a handler and its DTO',
        code: `<span class="tk-ann">@ApiRoute</span>(
  <span class="tk-param">method</span>: <span class="tk-type">ApiMethod</span>.get,
  <span class="tk-param">path</span>: <span class="tk-str">'/todos/:id'</span>,
  <span class="tk-param">pathParams</span>: [<span class="tk-type">ApiPathParam</span>(<span class="tk-str">'id'</span>, <span class="tk-param">type</span>: <span class="tk-type">int</span>)],
  <span class="tk-param">responses</span>: [<span class="tk-type">ApiResponse</span>.<span class="tk-fn">ok</span>(<span class="tk-type">TodoDto</span>)],
)
<span class="tk-kw">Future</span>&lt;<span class="tk-type">Response</span>&gt; <span class="tk-fn">getTodo</span>(<span class="tk-type">Request</span> request) { ... }`,
      },
      {
        title: 'Generate the artifacts',
        code: `<span class="tk-prompt">$</span> dart run axle_cli:axle gen
<span class="tk-com"># openapi.json + openapi.yaml + assets/swagger-ui + openapi.g.dart</span>`,
      },
      {
        title: 'Mount the docs',
        code: `app.<span class="tk-fn">mountAxleDocs</span>(
  <span class="tk-param">spec</span>: axleOpenApiJson,
  <span class="tk-param">swaggerUiDirectory</span>: <span class="tk-str">'assets/swagger-ui'</span>,
);`,
      },
      {
        title: 'Run and verify',
        code: `<span class="tk-prompt">$</span> dart run bin/server.dart
<span class="tk-com"># → http://localhost:8080/docs</span>
<span class="tk-com"># → http://localhost:8080/openapi.json</span>`,
      },
    ],
  },
  {
    id: 'shelf',
    label: 'Shelf',
    icon: '/shelf.svg',
    steps: [
      {
        title: 'Add dependencies',
        code: `<span class="tk-param">dependencies</span>:
  <span class="tk-param">axle_shelf</span>: <span class="tk-str">^0.2.0</span>
  <span class="tk-param">shelf</span>: <span class="tk-str">^1.4.0</span>
<span class="tk-param">dev_dependencies</span>:
  <span class="tk-param">axle_cli</span>: <span class="tk-str">^0.2.0</span>`,
      },
      {
        title: 'Create axle.yaml',
        code: `<span class="tk-prompt">$</span> dart run axle_cli:axle init`,
      },
      {
        title: 'Annotate a handler and its DTO',
        code: `<span class="tk-ann">@ApiRoute</span>(
  <span class="tk-param">method</span>: <span class="tk-type">ApiMethod</span>.get,
  <span class="tk-param">path</span>: <span class="tk-str">'/notes/:id'</span>,
  <span class="tk-param">pathParams</span>: [<span class="tk-type">ApiPathParam</span>(<span class="tk-str">'id'</span>, <span class="tk-param">type</span>: <span class="tk-type">int</span>)],
  <span class="tk-param">responses</span>: [<span class="tk-type">ApiResponse</span>.<span class="tk-fn">ok</span>(<span class="tk-type">NoteDto</span>)],
)
<span class="tk-kw">Future</span>&lt;<span class="tk-type">Response</span>&gt; <span class="tk-fn">getNote</span>(<span class="tk-type">Request</span> request) { ... }`,
      },
      {
        title: 'Generate the artifacts',
        code: `<span class="tk-prompt">$</span> dart run axle_cli:axle gen
<span class="tk-com"># openapi.json + openapi.yaml + assets/swagger-ui + openapi.g.dart</span>`,
      },
      {
        title: 'Compose the docs handler',
        code: `<span class="tk-kw">final</span> docs = <span class="tk-fn">axleDocsHandler</span>(
  <span class="tk-param">spec</span>: axleOpenApiJson,
  <span class="tk-param">swaggerUiDirectory</span>: <span class="tk-str">'assets/swagger-ui'</span>,
);
<span class="tk-kw">final</span> handler = <span class="tk-kw">const</span> <span class="tk-type">Pipeline</span>()
    .<span class="tk-fn">addHandler</span>(<span class="tk-type">Cascade</span>().<span class="tk-fn">add</span>(router.call).<span class="tk-fn">add</span>(docs).handler);`,
      },
      {
        title: 'Run and verify',
        code: `<span class="tk-prompt">$</span> dart run bin/server.dart
<span class="tk-com"># → http://localhost:8080/docs</span>
<span class="tk-com"># → http://localhost:8080/openapi.json</span>`,
      },
    ],
  },
  {
    id: 'serverpod',
    label: 'Serverpod',
    icon: '/serverpod.svg',
    steps: [
      {
        title: 'Add dependencies',
        code: `<span class="tk-param">dependencies</span>:
  <span class="tk-param">axle_serverpod</span>: <span class="tk-str">^0.2.0</span>
  <span class="tk-param">serverpod</span>: <span class="tk-str">^4.0.0</span>
<span class="tk-param">dev_dependencies</span>:
  <span class="tk-param">axle_cli</span>: <span class="tk-str">^0.2.0</span>`,
      },
      {
        title: 'Create axle.yaml',
        code: `<span class="tk-prompt">$</span> dart run axle_cli:axle init`,
      },
      {
        title: 'Annotate a top-level handler',
        code: `<span class="tk-ann">@ApiRoute</span>(
  <span class="tk-param">method</span>: <span class="tk-type">ApiMethod</span>.get,
  <span class="tk-param">path</span>: <span class="tk-str">'/greeting'</span>,
  <span class="tk-param">responses</span>: [<span class="tk-type">ApiResponse</span>.<span class="tk-fn">ok</span>(<span class="tk-type">Greeting</span>)],
)
<span class="tk-kw">Future</span>&lt;<span class="tk-type">Response</span>&gt; <span class="tk-fn">greeting</span>(<span class="tk-type">Session</span> session, <span class="tk-type">Request</span> request) { ... }

<span class="tk-kw">class</span> <span class="tk-type">GreetingRoute</span> <span class="tk-kw">extends</span> <span class="tk-type">Route</span> {
  <span class="tk-type">GreetingRoute</span>() : <span class="tk-kw">super</span>(methods: {<span class="tk-type">Method</span>.get});
  <span class="tk-ann">@override</span>
  <span class="tk-kw">Future</span>&lt;<span class="tk-type">Result</span>&gt; <span class="tk-fn">handleCall</span>(<span class="tk-type">Session</span> session, <span class="tk-type">Request</span> request) =&gt;
      <span class="tk-fn">greeting</span>(session, request);
}`,
      },
      {
        title: 'Generate the artifacts',
        code: `<span class="tk-prompt">$</span> dart run axle_cli:axle gen
<span class="tk-com"># openapi.json + openapi.yaml + assets/swagger-ui + openapi.g.dart</span>`,
      },
      {
        title: 'Mount on the web server',
        code: `pod.webServer.<span class="tk-fn">mountAxleDocs</span>(
  <span class="tk-param">spec</span>: axleOpenApiJson,
  <span class="tk-param">docsPath</span>: <span class="tk-str">'/swagger'</span>,
  <span class="tk-param">swaggerUiDirectory</span>: <span class="tk-str">'assets/swagger-ui'</span>,
);
<span class="tk-kw">await</span> pod.<span class="tk-fn">start</span>();`,
      },
      {
        title: 'Run and verify',
        code: `<span class="tk-prompt">$</span> serverpod start
<span class="tk-com"># web server (REST + docs) → http://localhost:8082/swagger</span>
<span class="tk-com"># spec → http://localhost:8082/openapi.json</span>
<span class="tk-com"># API/Endpoint server → 8090 (not the docs port)</span>`,
      },
    ],
  },
]

const active = ref('relic')
</script>

<template>
  <div class="ax-setup">
    <div class="ax-eyebrow">Setup</div>
    <h2 class="ax-heading">Same flow, your framework.</h2>
    <div class="ax-tabrow">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        class="ax-tab"
        :class="{ active: active === tab.id }"
        @click="active = tab.id"
      >
        <img :src="tab.icon" :alt="tab.label" width="20" height="20" />
        {{ tab.label }}
      </button>
    </div>
    <div class="ax-panels">
      <div
        v-for="tab in tabs"
        :key="tab.id"
        class="ax-panel"
        :class="{ 'is-hidden': active !== tab.id }"
      >
        <div v-for="(step, i) in tab.steps" :key="i" class="ax-row">
          <div class="ax-n">{{ i + 1 }}</div>
          <div class="ax-body">
            <div class="ax-t">{{ step.title }}</div>
            <pre class="ax-c"><code v-html="step.code"></code></pre>
          </div>
        </div>
      </div>
    </div>
    <a class="ax-adapter-cta" href="/adapters/building-an-adapter">
      <span class="ax-plus">+</span>
      <span>Build an adapter for your framework</span>
      <span class="ax-go">→</span>
    </a>
  </div>
</template>

<style scoped>
.ax-setup {
  width: 100vw;
  margin-left: calc(50% - 50vw);
  background: var(--ax-bg-soft);
  border-top: 1px solid var(--ax-border);
  color: var(--ax-text);
  font-family: var(--ax-body);
  text-align: center;
  padding: 64px 32px 72px;
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
  margin: 0 0 36px;
}
.ax-tabrow {
  display: flex;
  justify-content: center;
  gap: 10px;
  margin-bottom: 28px;
  flex-wrap: wrap;
}
.ax-tab {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  font-family: var(--ax-mono);
  font-size: 13px;
  padding: 7px 20px 7px 12px;
  border-radius: 999px;
  border: 1px solid var(--ax-border);
  background: transparent;
  color: var(--ax-muted);
  cursor: pointer;
  transition: all 0.2s;
}
.ax-tab:hover {
  color: var(--ax-text);
  border-color: var(--ax-accent-dim);
}
.ax-tab.active {
  background: rgba(154, 220, 255, 0.12);
  border-color: var(--ax-accent);
  color: var(--ax-accent);
}
.ax-tab img {
  border-radius: 5px;
  display: block;
  object-fit: contain;
}
.ax-adapter-cta {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  margin-top: 28px;
  font-size: 14.5px;
  font-weight: 600;
  color: var(--ax-text);
  border: 1px dashed var(--ax-accent-dim);
  border-radius: 999px;
  padding: 11px 24px;
  text-decoration: none;
  transition: all 0.2s;
}
.ax-adapter-cta:hover {
  border-color: var(--ax-accent);
  background: rgba(154, 220, 255, 0.08);
}
.ax-plus {
  font-family: var(--ax-mono);
  color: var(--ax-accent);
  font-size: 17px;
  line-height: 1;
}
.ax-go {
  color: var(--ax-accent);
}
.ax-panels {
  max-width: 860px;
  margin: 0 auto;
  display: grid;
}
.ax-panel {
  grid-area: 1 / 1;
  text-align: left;
  border: 1px solid var(--ax-border);
  border-radius: 14px;
  background: var(--ax-card);
  padding: 12px 28px;
}
.ax-panel.is-hidden {
  visibility: hidden;
}
.ax-row {
  display: flex;
  gap: 18px;
  padding: 18px 0;
  border-bottom: 1px solid var(--ax-border);
}
.ax-row:last-child {
  border-bottom: none;
}
.ax-n {
  font-family: var(--ax-display);
  font-weight: 700;
  font-size: 18px;
  color: var(--ax-accent);
  flex-shrink: 0;
  width: 24px;
}
.ax-body {
  flex: 1;
  min-width: 0;
}
.ax-t {
  font-weight: 600;
  font-size: 15px;
  color: #fff;
  margin-bottom: 10px;
}
.ax-c {
  margin: 0;
  padding: 14px 18px;
  background: rgba(0, 0, 0, 0.3);
  border: 1px solid var(--ax-border);
  border-radius: 8px;
  font-family: var(--ax-mono);
  font-size: 13px;
  line-height: 1.75;
  color: #c0caf5;
  white-space: pre;
  overflow-x: auto;
}
</style>
