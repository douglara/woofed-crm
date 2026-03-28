import react from '@vitejs/plugin-react'
import path  from 'path'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import pluginBuildResolver from './lib/plugins/vite_plugin_build_resolver'

export default defineConfig({
  plugins: [
    pluginBuildResolver(),
    react(),
    RubyPlugin(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'app/javascript'),
      '~': path.resolve(__dirname, 'app/javascript'),
    },
  },
})
