import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'axle',
  description: 'OpenAPI 3.1 docs for Dart servers — annotate, generate, serve.',
  base: '/',
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/logo.svg' }],
    ['link', { rel: 'preconnect', href: 'https://fonts.googleapis.com' }],
    ['link', { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' }],
    [
      'link',
      {
        rel: 'stylesheet',
        href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&family=Space+Grotesk:wght@500;600;700&display=swap',
      },
    ],
  ],
  themeConfig: {
    logo: '/logo.svg',
    nav: [
      { text: 'Guide', link: '/guide/introduction' },
      { text: 'Packages', link: '/packages/' },
      { text: 'Adapters', link: '/adapters/building-an-adapter' },
      { text: 'Skills', link: '/skills/' },
      { text: 'Reference', link: '/reference/axle-yaml' },
    ],
    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Introduction', link: '/guide/introduction' },
          { text: 'Getting Started', link: '/guide/getting-started' },
          { text: 'How It Works', link: '/guide/how-it-works' },
          { text: 'Design Decisions', link: '/guide/design-decisions' },
          { text: 'Examples', link: '/guide/examples' },
          { text: 'Troubleshooting', link: '/guide/troubleshooting' },
          { text: 'Roadmap and Status', link: '/guide/roadmap' },
          { text: 'Development', link: '/guide/development' },
        ],
      },
      {
        text: 'Packages',
        items: [
          { text: 'Overview', link: '/packages/' },
          { text: 'axle_core', link: '/packages/core' },
          { text: 'axle_cli', link: '/packages/cli' },
          { text: 'axle_relic', link: '/packages/relic' },
          { text: 'axle_shelf', link: '/packages/shelf' },
          { text: 'axle_serverpod', link: '/packages/serverpod' },
        ],
      },
      {
        text: 'Adapters',
        items: [
          { text: 'Building an Adapter', link: '/adapters/building-an-adapter' },
        ],
      },
      {
        text: 'Skills',
        items: [
          { text: 'Overview', link: '/skills/' },
          { text: 'axle-openapi-setup', link: '/skills/axle-openapi-setup' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'axle.yaml', link: '/reference/axle-yaml' },
          { text: 'Annotations and DTO Mapping', link: '/reference/annotations' },
        ],
      },
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/infm5/axle' },
    ],
    editLink: {
      pattern: 'https://github.com/infm5/axle/edit/master/doc/:path',
      text: 'Edit this page on GitHub',
    },
    lastUpdated: {
      text: 'Updated',
    },
    search: {
      provider: 'local',
    },
    outline: 'deep',
    footer: {
      message: 'MIT licensed. OpenAPI 3.1 for Dart servers.',
      copyright: 'Copyright © 2026 axle contributors',
    },
  },
})
