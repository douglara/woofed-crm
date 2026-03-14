import { router, useForm } from '@inertiajs/react'
import {
  AlertCircle,
  ArrowLeft,
  Bot,
  Lightbulb,
  Loader2,
  Sparkles,
  Wand2,
} from 'lucide-react'
import { animate } from 'motion'
import { useEffect, useRef, useState } from 'react'

import { cn } from '@/lib/utils'
import PluginShell from './PluginShell'

interface Props {
  current_account: { id: number; name: string }
  errors?: Record<string, string[]>
  values?: { name?: string; description?: string; prompt?: string }
}

const PROMPT_EXAMPLES = [
  'Crie um plugin que automaticamente categorize contatos com base nas interações e crie tags personalizadas para segmentação.',
  'Desenvolva um plugin que gere relatórios de performance de vendas com gráficos e insights de IA semanalmente.',
  'Implemente um plugin que analise o histórico de deals e sugira o melhor momento para entrar em contato com o cliente.',
  'Crie um plugin que integre com WhatsApp para enviar mensagens automáticas de follow-up após reuniões.',
]

export default function PluginsNew({ current_account, errors, values }: Props) {
  const containerRef = useRef<HTMLDivElement>(null)
  const [charCount, setCharCount] = useState(values?.prompt?.length ?? 0)
  const [exampleIndex, setExampleIndex] = useState(0)

  const { data, setData, post, processing } = useForm({
    plugin: {
      name: values?.name ?? '',
      description: values?.description ?? '',
      prompt: values?.prompt ?? '',
    },
  })

  useEffect(() => {
    if (containerRef.current) {
      animate(
        containerRef.current.querySelectorAll('[data-animate]'),
        { opacity: [0, 1], y: [16, 0] },
        { duration: 0.5, delay: (i) => i * 0.08, easing: 'ease-out' },
      )
    }
  }, [])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    post(`/accounts/${current_account.id}/settings/plugins`)
  }

  const hasError = (field: string) => !!errors?.[field]?.length

  const useExample = () => {
    const example = PROMPT_EXAMPLES[exampleIndex % PROMPT_EXAMPLES.length]
    setData('plugin', { ...data.plugin, prompt: example })
    setCharCount(example.length)
    setExampleIndex((i) => i + 1)
  }

  const settingsUrl = `/accounts/${current_account.id}/settings`

  return (
    <PluginShell settingsUrl={settingsUrl}>
      <div className="p-6 md:p-8 h-full overflow-auto">
        <div className="max-w-2xl mx-auto" ref={containerRef}>
          {/* Back */}
          <button
            data-animate
            className="flex items-center gap-2 typography-sub-text-r-lh150 text-dark-gray-palette-p3 hover:text-dark-gray-palette-p1 mb-6 group transition-colors"
            onClick={() =>
              router.visit(`/accounts/${current_account.id}/settings/plugins`)
            }
          >
            <ArrowLeft className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform duration-200" />
            Voltar para Plugins
          </button>

          {/* Header */}
          <div data-animate className="mb-8">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 rounded-xl bg-brand-palette-03 flex items-center justify-center">
                <Wand2 className="w-5 h-5 text-white" />
              </div>
              <div>
                <h1 className="typography-body-s-lh150 text-dark-gray-palette-p1">Novo Plugin</h1>
                <p className="typography-sub-text-r-lh150 text-dark-gray-palette-p3">
                  Descreva o que você quer e a IA vai construir para você
                </p>
              </div>
            </div>
          </div>

          {/* Info banner */}
          <div
            data-animate
            className="flex items-start gap-3 p-4 rounded-md bg-brand-palette-07 border border-brand-palette-06 mb-6"
          >
            <Bot className="w-5 h-5 text-brand-palette-03 mt-0.5 flex-shrink-0" />
            <div className="typography-sub-text-r-lh150 text-brand-palette-02">
              <strong className="font-semibold">Como funciona:</strong> Você descreve o
              plugin que precisa, a IA analisa o prompt e constrói automaticamente o
              código. Acompanhe o progresso em tempo real via chat.
            </div>
          </div>

          <form onSubmit={handleSubmit} className="flex flex-col gap-5">
            {/* Name */}
            <div data-animate className="flex flex-col gap-1">
              <label className="typography-text-m-lh150 text-dark-gray-palette-p1">
                Nome do plugin <span className="text-auxiliary-palette-red">*</span>
              </label>
              <input
                type="text"
                placeholder="ex: Auto-categorização de contatos"
                value={data.plugin.name}
                onChange={(e) =>
                  setData('plugin', { ...data.plugin, name: e.target.value })
                }
                className={cn(
                  'form-input',
                  hasError('name') && 'form-input-error',
                )}
              />
              {hasError('name') && (
                <div className="flex items-center gap-1.5 typography-micro-m-lh150 text-auxiliary-palette-red">
                  <AlertCircle className="w-3.5 h-3.5" />
                  {errors!.name![0]}
                </div>
              )}
            </div>

            {/* Description */}
            <div data-animate className="flex flex-col gap-1">
              <label className="typography-text-m-lh150 text-dark-gray-palette-p1">
                Descrição{' '}
                <span className="typography-sub-text-r-lh150 text-dark-gray-palette-p3 font-normal">(opcional)</span>
              </label>
              <textarea
                placeholder="Uma breve descrição do que este plugin faz..."
                value={data.plugin.description}
                onChange={(e) =>
                  setData('plugin', { ...data.plugin, description: e.target.value })
                }
                rows={3}
                className="form-input resize-none"
              />
            </div>

            {/* Prompt */}
            <div data-animate className="flex flex-col gap-1">
              <div className="flex items-center justify-between">
                <label className="typography-text-m-lh150 text-dark-gray-palette-p1">
                  Prompt para a IA <span className="text-auxiliary-palette-red">*</span>
                </label>
                <button
                  type="button"
                  onClick={useExample}
                  className="flex items-center gap-1.5 typography-micro-m-lh150 text-brand-palette-03 hover:text-brand-palette-02 font-medium transition-colors"
                >
                  <Lightbulb className="w-3.5 h-3.5" />
                  Ver exemplo
                </button>
              </div>
              <div className="relative">
                <textarea
                  placeholder="Descreva detalhadamente o plugin que você quer criar..."
                  value={data.plugin.prompt}
                  onChange={(e) => {
                    setData('plugin', { ...data.plugin, prompt: e.target.value })
                    setCharCount(e.target.value.length)
                  }}
                  rows={7}
                  className={cn(
                    'form-input resize-none w-full pb-8',
                    hasError('prompt') && 'form-input-error',
                  )}
                />
                <div className="absolute bottom-3 right-3 typography-micro-m-lh150 text-dark-gray-palette-p3">
                  {charCount} caracteres
                </div>
              </div>
              {hasError('prompt') && (
                <div className="flex items-center gap-1.5 typography-micro-m-lh150 text-auxiliary-palette-red">
                  <AlertCircle className="w-3.5 h-3.5" />
                  {errors!.prompt![0]}
                </div>
              )}
              <p className="typography-micro-m-lh150 text-dark-gray-palette-p3">
                Dica: quanto mais detalhado o prompt, melhor o resultado.
              </p>
            </div>

            {/* Submit */}
            <div data-animate className="flex items-center gap-3 pt-2">
              <button
                type="submit"
                disabled={processing}
                className="btn-primary flex items-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
              >
                {processing ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Criando plugin...
                  </>
                ) : (
                  <>
                    <Sparkles className="w-4 h-4" />
                    Criar plugin com IA
                  </>
                )}
              </button>
              <button
                type="button"
                className="btn-secondary"
                onClick={() =>
                  router.visit(`/accounts/${current_account.id}/settings/plugins`)
                }
              >
                Cancelar
              </button>
            </div>
          </form>
        </div>
      </div>
    </PluginShell>
  )
}
