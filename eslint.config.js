import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import ember from 'eslint-plugin-ember/recommended'
import prettier from 'eslint-config-prettier'
import globals from 'globals'

export default tseslint.config(
  {
    ignores: [
      '**/dist/**',
      '**/declarations/**',
      '**/*.d.ts',
      '.claude/**',
      'docs/**',
      'test-app/config/**',
      '**/*.cjs',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ember.configs.base,
  ember.configs.gts,
  {
    files: ['**/*.{ts,gts}'],
    languageOptions: { parser: ember.parser, globals: globals.browser },
    rules: {
      '@typescript-eslint/consistent-type-imports': 'error',
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
    },
  },
  {
    files: ['**/*.mjs', 'eslint.config.js', 'scripts/**'],
    languageOptions: { globals: globals.node },
  },
  prettier,
)
