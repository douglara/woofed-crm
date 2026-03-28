import { defineConfig } from 'vitest/config'
import path from 'path'

export default defineConfig({
  test: {
    include: ['spec/javascript/**/*.spec.{ts,tsx,js,jsx}'],
    root: '.',
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'app/javascript'),
      '~': path.resolve(__dirname, 'app/javascript'),
    },
  },
})
