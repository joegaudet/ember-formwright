import { babel } from '@rollup/plugin-babel'
import { Addon } from '@embroider/addon-dev/rollup'

const addon = new Addon({ srcDir: 'src', destDir: 'dist' })

export default {
  output: addon.output(),
  plugins: [
    addon.publicEntrypoints(['index.js']),
    addon.dependencies(),
    babel({ extensions: ['.js', '.gjs', '.ts', '.gts'], babelHelpers: 'bundled' }),
    addon.gjs(),
    addon.declarations(
      'declarations',
      'ember-tsc --declaration --emitDeclarationOnly --noEmit false',
    ),
    addon.clean(),
  ],
}
