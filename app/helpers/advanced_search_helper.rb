module AdvancedSearchHelper
  def search_types
    [
      { key: :contacts, type: :contact, value: 'contact', icon: 'contact',
        label: t('activerecord.models.contact.other') },
      { key: :deals, type: :deal, value: 'deal', icon: 'clipboard-list', label: t('activerecord.models.deal.other') },
      { key: :products, type: :product, value: 'product', icon: 'box', label: t('activerecord.models.product.other') },
      { key: :pipelines, type: :pipeline, value: 'pipeline', icon: 'funnel',
        label: t('activerecord.models.pipeline.other') },
      { key: :activities, type: :activity, value: 'activity', icon: 'calendar-check-2',
        label: Event.human_enum_name(:kind, :activity).pluralize }
    ]
  end
end
