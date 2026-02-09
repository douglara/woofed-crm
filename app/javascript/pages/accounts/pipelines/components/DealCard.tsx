import { useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { Currency } from '../../../../components/formatters/Currency'
import { DateTime } from '../../../../components/formatters/DateTime'
import type { Deal } from '../../../../types/kanban'

interface DealCardProps {
  deal: Deal
  accountId: number
  currency: string
  locale: string
  isDragging?: boolean
}

export function DealCard({ deal, accountId, currency, locale, isDragging }: DealCardProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
  } = useSortable({ id: deal.id })

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  }

  const dealUrl = `/accounts/${accountId}/deals/${deal.id}`
  const contactUrl = `/accounts/${accountId}/contacts/${deal.contact.id}`

  const usersToShow = deal.users.slice(0, 2)
  const remainingUsers = (deal as Deal & { users_count?: number }).users_count
    ? (deal as Deal & { users_count?: number }).users_count! - 2
    : deal.users.length - 2

  return (
    <li
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      data-id={deal.id}
      data-account-id={accountId}
      data-position={deal.position}
      className="hover:shadow-sm select-none cursor-pointer"
    >
      <div className="rounded border-2 color-border-default color-bg-fill-default">
        <a href={dealUrl} className="flex flex-col gap-2 pt-2 px-4">
          {!deal.status || deal.status !== 'open' ? (
            <div className="w-full flex">
              <div className={`inline-flex gap-1 items-center border rounded p-1 h-4 ${
                deal.status === 'lost'
                  ? 'color-border-feedback-danger-hard color-fg-feedback-danger color-bg-feedback-danger-default'
                  : 'color-border-feedback-success-harder color-fg-feedback-success color-bg-feedback-success-default'
              }`}>
                <span className="typography-body-800">
                  {deal.status === 'won' ? 'Won' : 'Lost'}
                </span>
              </div>
            </div>
          ) : null}
          <p className="typography-body-900 color-fg-default">
            {deal.name}
          </p>
          <div className="w-full border-[0.5px] color-border-default"></div>
        </a>

        <div className="flex items-center">
          <a href={contactUrl} className="cursor-pointer peer">
            <div className="flex items-start py-2 pl-4 gap-1">
              <svg className="w-4 h-4 color-fg-default mt-px shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clipRule="evenodd"></path>
              </svg>
              <p className="typography-body-900 color-fg-soft hover:color-fg-default break-all">
                {deal.contact.full_name}
              </p>
            </div>
          </a>
          <a href={dealUrl} className="flex-1 py-2">&nbsp;</a>
        </div>

        <div className="flex">
          <div className="flex grow">
            {deal.users.length > 0 && (
              <div className="flex flex-col">
                <div className="flex">
                  <a href={dealUrl} className="w-4 h-5">&nbsp;</a>
                  <div className="flex -space-x-2 rtl:space-x-reverse">
                    {usersToShow.map((user) => (
                      <div key={user.id} className="w-5 h-5">
                        <a href={`/accounts/${accountId}/users/${user.id}/edit`} className="cursor-pointer peer">
                          {user.avatar_url ? (
                            <img
                              className="w-5 h-5 rounded-full object-cover hover:shadow-md"
                              src={user.avatar_url}
                              alt={user.full_name}
                            />
                          ) : (
                            <div className="w-5 h-5 flex items-center justify-center bg-gray-300 rounded-full hover:shadow-md">
                              <svg className="w-3 h-3 color-fg-default" fill="currentColor" viewBox="0 0 20 20">
                                <path fillRule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clipRule="evenodd"></path>
                              </svg>
                            </div>
                          )}
                        </a>
                      </div>
                    ))}
                    {remainingUsers > 0 && (
                      <div className="flex items-center justify-center w-5 h-5 text-xs typography-body-800 text-[10px] color-fg-soft bg-gray-400 rounded-full">
                        {remainingUsers > 99 ? '99+' : `${remainingUsers}+`}
                      </div>
                    )}
                  </div>
                </div>
                <a href={dealUrl} className="h-2">&nbsp;</a>
              </div>
            )}
            {(deal.total_amount_in_cents !== 0 || deal.next_event_planned || deal.users.length > 0) && (
              <a href={dealUrl} className="flex-1">&nbsp;</a>
            )}
          </div>

          {(deal.total_amount_in_cents !== 0 || deal.next_event_planned) && (
            <a href={dealUrl}>
              <div className="flex items-center flex-wrap justify-end gap-1.5 pr-4 pb-2">
                {deal.total_amount_in_cents !== 0 && (
                  <div className="inline-flex gap-1 items-center color-fg-feedback-neutral h-5">
                    <div className="w-4 h-4">
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <path d="M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8"/>
                        <path d="M12 18V6"/>
                      </svg>
                    </div>
                    <Currency
                      value={deal.total_amount_in_cents}
                      currency={currency}
                      className="typography-body-800"
                    />
                  </div>
                )}

                {deal.next_event_planned && (
                  <div className={`inline-flex gap-1 items-center h-5 ${
                    deal.next_event_planned.overdue
                      ? 'color-fg-feedback-danger'
                      : 'color-fg-feedback-success'
                  }`}>
                    <div className="w-4 h-4">
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <polyline points="12 6 12 12 16 14"/>
                      </svg>
                    </div>
                    <DateTime
                      value={deal.next_event_planned.primary_date}
                      type="distance"
                      locale={locale}
                      className="typography-body-800"
                    />
                  </div>
                )}
              </div>
            </a>
          )}
        </div>
      </div>
    </li>
  )
}
