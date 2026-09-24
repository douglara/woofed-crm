# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

[:en, :uk].each do |locale|
  ActiveSupport::Inflector.inflections(locale) do |inflect|
    inflect.irregular 'Активність', 'Активності'
    inflect.irregular 'активність', 'активності'
    inflect.irregular 'Угода', 'Угоди'
    inflect.irregular 'угода', 'угоди'
    inflect.irregular 'Контакт', 'Контакти'
    inflect.irregular 'контакт', 'контакти'
    inflect.irregular 'Компанія', 'Компанії'
    inflect.irregular 'компанія', 'компанії'
    inflect.irregular 'Продукт', 'Продукти'
    inflect.irregular 'продукт', 'продукти'
    inflect.irregular 'Подія', 'Події'
    inflect.irregular 'подія', 'події'
    inflect.irregular 'Користувач', 'Користувачі'
    inflect.irregular 'користувач', 'користувачі'
    inflect.irregular 'Пайплайн', 'Пайплайни'
    inflect.irregular 'пайплайн', 'пайплайни'
    inflect.irregular 'Етап', 'Етапи'
    inflect.irregular 'етап', 'етапи'
    inflect.irregular 'Вебхук', 'Вебхуки'
    inflect.irregular 'вебхук', 'вебхуки'
    inflect.irregular 'Вкладення', 'Вкладення'
    inflect.irregular 'вкладення', 'вкладення'
  end
end

