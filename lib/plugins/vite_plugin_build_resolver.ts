import fs from 'fs'
import path from 'path'

/**
 * Vite plugin that resolves imports from storage/build/app/javascript/ first,
 * falling back to app/javascript/. This mirrors the Rails-side resolution
 * so that patched JS/JSX/TS/TSX files in storage/build/ take precedence.
 */
export default function pluginBuildResolver() {
  const rootDir = process.cwd()
  const buildJsDir = path.join(rootDir, 'storage', 'build', 'app', 'javascript')
  const appJsDir = path.join(rootDir, 'app', 'javascript')

  return {
    name: 'plugin-build-resolver',
    enforce: 'pre' as const,

    resolveId(source: string, importer: string | undefined) {
      if (!importer) return null

      // Only handle aliased imports (@ or ~) that we can map
      let relativePath: string | null = null

      if (source.startsWith('@/') || source.startsWith('~/')) {
        relativePath = source.slice(2)
      } else {
        return null
      }

      // Try storage/build first
      const buildPath = tryResolve(path.join(buildJsDir, relativePath))
      if (buildPath) return buildPath

      // Fall back to app/javascript (Vite's default alias handles this,
      // so return null to let it proceed normally)
      return null
    },
  }
}

const EXTENSIONS = ['', '.js', '.jsx', '.ts', '.tsx', '/index.js', '/index.jsx', '/index.ts', '/index.tsx']

function tryResolve(basePath: string): string | null {
  for (const ext of EXTENSIONS) {
    const candidate = basePath + ext
    try {
      const stat = fs.statSync(candidate)
      if (stat.isFile()) {
        return candidate
      }
    } catch {
      // file doesn't exist, try next
    }
  }
  return null
}
