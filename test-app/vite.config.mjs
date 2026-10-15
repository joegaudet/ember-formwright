import { defineConfig } from 'vite'
import { extensions, classicEmberSupport, ember } from '@embroider/vite'
import { babel } from '@rollup/plugin-babel'

export default defineConfig({
  // The demo build is served from joegaudet.com/ember-formwright/demo/.
  base: process.env.FW_DEMO ? '/ember-formwright/demo/' : '/',
  plugins: [classicEmberSupport(), ember(), babel({ babelHelpers: 'runtime', extensions })],
})
