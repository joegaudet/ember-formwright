import { readFileSync } from 'node:fs'
import { babel } from '@rollup/plugin-babel'
import { Addon } from '@embroider/addon-dev/rollup'

const addon = new Addon({ srcDir: 'src', destDir: 'dist' })

export default {
  output: addon.output(),
  plugins: [
    addon.publicEntrypoints(['index.js', 'test-support/index.js']),
    addon.dependencies(),
    babel({ extensions: ['.js', '.gjs', '.ts', '.gts'], babelHelpers: 'bundled' }),
    addon.gjs(),
    addon.declarations(
      'declarations',
      'ember-tsc --declaration --emitDeclarationOnly --noEmit false',
    ),
    {
      // Like the core theme: imported by the app, not by a module.
      name: 'formwright-file-upload-theme',
      generateBundle() {
        this.emitFile({
          type: 'asset',
          fileName: 'theme.css',
          source: readFileSync('src/theme.css', 'utf8'),
        })
      },
    },
    addon.clean(),
  ],
}
