import { useMemo } from 'react'

interface DateTimeProps {
  value: string
  type?: 'short' | 'distance' | 'compact' | 'default'
  className?: string
  locale?: string
}

function getRelativeTimeString(date: Date, locale: string = 'en'): string {
  const now = new Date()
  const diffMs = date.getTime() - now.getTime()
  const diffSecs = Math.round(diffMs / 1000)
  const diffMins = Math.round(diffSecs / 60)
  const diffHours = Math.round(diffMins / 60)
  const diffDays = Math.round(diffHours / 24)
  const diffMonths = Math.round(diffDays / 30)
  const diffYears = Math.round(diffDays / 365)

  const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' })

  if (Math.abs(diffSecs) < 60) {
    return rtf.format(diffSecs, 'second')
  } else if (Math.abs(diffMins) < 60) {
    return rtf.format(diffMins, 'minute')
  } else if (Math.abs(diffHours) < 24) {
    return rtf.format(diffHours, 'hour')
  } else if (Math.abs(diffDays) < 30) {
    return rtf.format(diffDays, 'day')
  } else if (Math.abs(diffMonths) < 12) {
    return rtf.format(diffMonths, 'month')
  } else {
    return rtf.format(diffYears, 'year')
  }
}

export function DateTime({ value, type = 'default', className = '', locale = 'en' }: DateTimeProps) {
  const formattedValue = useMemo(() => {
    const date = new Date(value)
    const normalizedLocale = locale.toLowerCase().replace('_', '-')

    switch (type) {
      case 'short':
        return date.toLocaleString(normalizedLocale, {
          day: '2-digit',
          month: '2-digit',
          year: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
        })
      case 'distance':
        return getRelativeTimeString(date, normalizedLocale).replace(/^in |ago$/gi, '').trim()
      case 'compact':
        return date.toLocaleString(normalizedLocale, {
          day: '2-digit',
          month: 'short',
          hour: '2-digit',
          minute: '2-digit',
        })
      default:
        return date.toLocaleString(normalizedLocale, {
          dateStyle: 'long',
          timeStyle: 'short',
        })
    }
  }, [value, type, locale])

  return <span className={className}>{formattedValue}</span>
}
