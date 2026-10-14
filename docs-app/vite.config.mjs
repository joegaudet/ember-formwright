import { defineConfig } from 'vite'
import { extensions, classicEmberSupport, ember } from '@embroider/vite'
import { babel } from '@rollup/plugin-babel'
import { kolay } from 'kolay/vite'

export default defineConfig({
  // The guide is served from joegaudet.com/formwright/guide/.
  base: process.env.FW_GUIDE ? '/formwright/guide/' : '/',
  plugins: [
    classicEmberSupport(),
    ember(),
    kolay({
      // TypeDoc renders <APIDocs> from these packages' type declarations.
      packages: ['@formwright/ember'],
    }),
    babel({ babelHelpers: 'runtime', extensions }),
  ],
  build: {
    // TypeDoc's browser renderer (behind <APIDocs>) looks reflections up by class name.
    rolldownOptions: { output: { keepNames: true } },
  },
  optimizeDeps: {
    // Kolay injects its virtual modules at runtime.
    exclude: ['kolay'],
  },
})
