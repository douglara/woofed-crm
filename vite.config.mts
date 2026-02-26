import react from '@vitejs/plugin-react'
import path  from 'path'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
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
