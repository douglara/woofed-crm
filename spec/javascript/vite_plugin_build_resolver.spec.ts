import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import fs from 'fs'
import path from 'path'
import os from 'os'
import pluginBuildResolver from '../../lib/plugins/vite_plugin_build_resolver'

describe('pluginBuildResolver', () => {
  let tmpDir: string
  let originalCwd: string

  beforeEach(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'vite-plugin-test-'))
    originalCwd = process.cwd()
    process.chdir(tmpDir)
  })

  afterEach(() => {
    process.chdir(originalCwd)
    fs.rmSync(tmpDir, { recursive: true, force: true })
  })

  function createFile(relativePath: string, content: string) {
    const fullPath = path.join(tmpDir, relativePath)
    fs.mkdirSync(path.dirname(fullPath), { recursive: true })
    fs.writeFileSync(fullPath, content)
    return fullPath
  }

  it('returns a Vite plugin object with name and resolveId', () => {
    const plugin = pluginBuildResolver()

    expect(plugin.name).toBe('plugin-build-resolver')
    expect(plugin.enforce).toBe('pre')
    expect(typeof plugin.resolveId).toBe('function')
  })

  describe('resolveId', () => {
    it('returns null for non-aliased imports', () => {
      const plugin = pluginBuildResolver()
      const result = plugin.resolveId('./local-file', '/some/importer.js')

      expect(result).toBeNull()
    })

    it('returns null when no build file exists', () => {
      const plugin = pluginBuildResolver()
      const result = plugin.resolveId('@/components/Avatar', '/some/importer.js')

      expect(result).toBeNull()
    })

    it('resolves @/ alias to storage/build/ when build file exists', () => {
      const buildFile = createFile(
        'storage/build/app/javascript/components/Avatar.jsx',
        'export default function Avatar() { return <div /> }'
      )

      const plugin = pluginBuildResolver()
      const result = plugin.resolveId('@/components/Avatar.jsx', '/some/importer.js')

      expect(result).toBe(buildFile)
    })

    it('resolves ~/ alias to storage/build/ when build file exists', () => {
      const buildFile = createFile(
        'storage/build/app/javascript/components/Avatar.jsx',
        'export default function Avatar() { return <div /> }'
      )

      const plugin = pluginBuildResolver()
      const result = plugin.resolveId('~/components/Avatar.jsx', '/some/importer.js')

      expect(result).toBe(buildFile)
    })

    it('resolves imports without extension by trying common extensions', () => {
      const buildFile = createFile(
        'storage/build/app/javascript/components/Avatar.jsx',
        'export default function Avatar() { return <div /> }'
      )

      const plugin = pluginBuildResolver()
      const result = plugin.resolveId('@/components/Avatar', '/some/importer.js')

      expect(result).toBe(buildFile)
    })

    it('resolves index files in directories', () => {
      const indexFile = createFile(
        'storage/build/app/javascript/components/Avatar/index.tsx',
        'export default function Avatar() { return <div /> }'
      )

      const plugin = pluginBuildResolver()
      const result = plugin.resolveId('@/components/Avatar', '/some/importer.js')

      expect(result).toBe(indexFile)
    })

    it('returns null when no importer is provided', () => {
      createFile(
        'storage/build/app/javascript/components/Avatar.jsx',
        'export default function Avatar() { return <div /> }'
      )

      const plugin = pluginBuildResolver()
      const result = plugin.resolveId('@/components/Avatar.jsx', undefined)

      expect(result).toBeNull()
    })

    it('prefers build file over app file', () => {
      createFile(
        'app/javascript/components/Avatar.jsx',
        'original'
      )
      const buildFile = createFile(
        'storage/build/app/javascript/components/Avatar.jsx',
        'patched'
      )

      const plugin = pluginBuildResolver()
      const result = plugin.resolveId('@/components/Avatar.jsx', '/some/importer.js')

      expect(result).toBe(buildFile)
    })

    it('falls back to null (lets Vite handle) when only app file exists', () => {
      createFile(
        'app/javascript/components/Avatar.jsx',
        'original'
      )

      const plugin = pluginBuildResolver()
      const result = plugin.resolveId('@/components/Avatar.jsx', '/some/importer.js')

      // Returns null to let Vite's default alias handle it
      expect(result).toBeNull()
    })
  })
})
