interface CurrencyProps {
  value: number
  currency?: string
  className?: string
}

export function Currency({ value, currency = 'USD', className = '' }: CurrencyProps) {
  const formattedValue = new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value / 100)

  return <span className={className}>{formattedValue}</span>
}
