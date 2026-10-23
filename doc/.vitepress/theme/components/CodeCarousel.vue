<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'

interface Slide {
  chip: string
  file: string
  html: string
}

const slides: Slide[] = [
  {
    chip: '@ApiRoute',
    file: 'api.dart · route',
    html: `<span class="tk-ann">@ApiRoute</span>(
  <span class="tk-param">method</span>: <span class="tk-type">ApiMethod</span>.get,
  <span class="tk-param">path</span>: <span class="tk-str">'/todos/:id'</span>,
  <span class="tk-param">summary</span>: <span class="tk-str">'Get a todo'</span>,
  <span class="tk-param">pathParams</span>: [<span class="tk-type">ApiPathParam</span>(<span class="tk-str">'id'</span>, <span class="tk-param">type</span>: <span class="tk-type">int</span>)],
  <span class="tk-param">responses</span>: [
    <span class="tk-type">ApiResponse</span>.<span class="tk-fn">ok</span>(<span class="tk-type">TodoDto</span>),
    <span class="tk-type">ApiResponse</span>.<span class="tk-fn">notFound</span>(),
  ],
)
<span class="tk-kw">Future</span>&lt;<span class="tk-type">Response</span>&gt; <span class="tk-fn">getTodo</span>(<span class="tk-type">Request</span> request) { ... }`,
  },
  {
    chip: '@ApiSchema',
    file: 'todo.dart · schema',
    html: `<span class="tk-ann">@ApiSchema</span>(<span class="tk-param">description</span>: <span class="tk-str">'A todo item.'</span>)
<span class="tk-kw">class</span> <span class="tk-type">TodoDto</span> {
  <span class="tk-kw">final</span> <span class="tk-type">int</span> id;
  <span class="tk-kw">final</span> <span class="tk-type">String</span> title;
  <span class="tk-kw">final</span> <span class="tk-type">bool</span> completed;
  <span class="tk-kw">const</span> <span class="tk-fn">TodoDto</span>({<span class="tk-kw">required</span> <span class="tk-kw">this</span>.id, ...});
}`,
  },
  {
    chip: 'axle.yaml',
    file: 'axle.yaml · config',
    html: `<span class="tk-param">openapi</span>: <span class="tk-str">3.1.0</span>
<span class="tk-param">info</span>:
  <span class="tk-param">title</span>: <span class="tk-str">Todo API</span>
  <span class="tk-param">version</span>: <span class="tk-str">0.1.0</span>
<span class="tk-param">generate</span>:
  <span class="tk-param">scan</span>: [<span class="tk-str">lib</span>]
  <span class="tk-param">output</span>:
    <span class="tk-param">json</span>: <span class="tk-str">openapi.json</span>
    <span class="tk-param">dart</span>: <span class="tk-str">lib/src/generated/openapi.g.dart</span>`,
  },
  {
    chip: 'mountAxleDocs',
    file: 'server.dart · mount',
    html: `app.<span class="tk-fn">mountAxleDocs</span>(
  <span class="tk-param">spec</span>: axleOpenApiJson,
  <span class="tk-param">swaggerUiDirectory</span>: <span class="tk-str">'assets/swagger-ui'</span>,
);
<span class="tk-com">// GET /openapi.json -&gt; spec</span>
<span class="tk-com">// GET /docs         -&gt; Swagger UI</span>`,
  },
]

const index = ref(0)
let timer: ReturnType<typeof setInterval> | null = null

function select(i: number) {
  index.value = i
  restart()
}

function step(dir: number) {
  index.value = (index.value + dir + slides.length) % slides.length
  restart()
}

function restart() {
  if (timer) clearInterval(timer)
  timer = setInterval(() => {
    index.value = (index.value + 1) % slides.length
  }, 5000)
}

function pause() {
  if (timer) clearInterval(timer)
}

onMounted(restart)
onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>

<template>
  <div class="ax-codecard" @mouseenter="pause" @mouseleave="restart">
    <div class="ax-tabs">
      <button
        v-for="(slide, i) in slides"
        :key="slide.chip"
        class="ax-chip"
        :class="{ active: i === index }"
        @click="select(i)"
      >
        {{ slide.chip }}
      </button>
      <span class="ax-file">{{ slides[index].file }}</span>
      <span class="ax-nav">
        <button class="ax-arrow" @click="step(-1)" aria-label="Previous slide">‹</button>
        <span class="ax-count">{{ index + 1 }}/{{ slides.length }}</span>
        <button class="ax-arrow" @click="step(1)" aria-label="Next slide">›</button>
      </span>
    </div>
    <div class="ax-slides">
      <pre
        v-for="(slide, i) in slides"
        :key="slide.chip"
        class="ax-code"
        :class="{ 'is-active': i === index }"
      ><code v-html="slide.html"></code></pre>
    </div>
    <div class="ax-term">
      <div class="ax-term-line"><span class="ax-prompt">~/todo $</span> curl localhost:8080/openapi.json</div>
      <div class="ax-term-line ax-dim">{"openapi":"3.1.0","info":{"title":"Todo API","version":"0.1.0"}, …}</div>
    </div>
  </div>
</template>

<style scoped>
.ax-codecard {
  background: var(--ax-card);
  border: 1px solid var(--ax-border);
  border-radius: 12px;
  overflow: hidden;
  font-family: var(--ax-mono);
}
.ax-tabs {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  border-bottom: 1px solid var(--ax-border);
  flex-wrap: wrap;
}
.ax-chip {
  font-family: var(--ax-mono);
  font-size: 12px;
  padding: 4px 12px;
  border-radius: 999px;
  border: 1px solid var(--ax-border);
  background: transparent;
  color: var(--ax-muted);
  cursor: pointer;
  transition: all 0.2s;
}
.ax-chip:hover {
  color: var(--ax-text);
  border-color: var(--ax-accent-dim);
}
.ax-chip.active {
  background: rgba(154, 220, 255, 0.12);
  border-color: var(--ax-accent);
  color: var(--ax-accent);
}
.ax-file {
  font-size: 12px;
  color: var(--ax-muted);
  margin-left: 4px;
}
.ax-nav {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 6px;
}
.ax-arrow {
  background: transparent;
  border: 1px solid var(--ax-border);
  border-radius: 6px;
  color: var(--ax-muted);
  width: 24px;
  height: 24px;
  line-height: 1;
  cursor: pointer;
  font-size: 15px;
}
.ax-arrow:hover {
  color: var(--ax-accent);
  border-color: var(--ax-accent-dim);
}
.ax-count {
  font-size: 11px;
  color: var(--ax-muted);
}
.ax-slides {
  display: grid;
}
.ax-code {
  grid-area: 1 / 1;
  visibility: hidden;
  opacity: 0;
  transition: opacity 0.25s ease, visibility 0.25s;
  margin: 0;
  padding: 18px 20px;
  font-size: 13.5px;
  line-height: 1.75;
  color: #c0caf5;
  white-space: pre;
  overflow-x: auto;
}
.ax-code.is-active {
  visibility: visible;
  opacity: 1;
}
.ax-term {
  border-top: 1px solid var(--ax-border);
  background: rgba(154, 220, 255, 0.04);
  padding: 14px 20px;
  font-size: 13px;
  line-height: 1.8;
}
.ax-term-line {
  color: var(--ax-text);
  white-space: pre-wrap;
  word-break: break-all;
}
.ax-prompt {
  color: var(--ax-accent);
}
.ax-dim {
  color: var(--ax-accent);
  opacity: 0.85;
}
</style>

<style>
.ax-code .tk-kw { color: #bb9af7; }
.ax-code .tk-str { color: #9ece6a; }
.ax-code .tk-type { color: #7aa2f7; }
.ax-code .tk-fn { color: #e0af68; }
.ax-code .tk-ann { color: #2ac3de; }
.ax-code .tk-param { color: #c0caf5; }
.ax-code .tk-com { color: #565f89; font-style: italic; }
.ax-c .tk-kw { color: #bb9af7; }
.ax-c .tk-str { color: #9ece6a; }
.ax-c .tk-type { color: #7aa2f7; }
.ax-c .tk-fn { color: #e0af68; }
.ax-c .tk-ann { color: #2ac3de; }
.ax-c .tk-param { color: #c0caf5; }
.ax-c .tk-com { color: #565f89; font-style: italic; }
.ax-c .tk-prompt { color: #9adcff; }
</style>
