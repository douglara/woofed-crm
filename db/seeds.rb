# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if Rails.env.development? && User.count.zero?

  Installation.create!(
    id: SecureRandom.uuid,
    key1: Faker::Alphanumeric.alphanumeric(number: 10),
    key2: Faker::Alphanumeric.alphanumeric(number: 10),
    status: 'completed',
    token: Faker::Alphanumeric.alphanumeric(number: 20)
  )

  account = Account.create!(
    name: 'Demo Company',
    currency_code: 'BRL',
    segment: 'technology',
    number_of_employees: '11-50'
  )

  users = []
  [
    { full_name: 'Admin', email: 'user1@email.com' },
    { full_name: 'Maria Sales', email: 'maria@email.com' },
    { full_name: 'John Commercial', email: 'john@email.com' }
  ].each do |user_data|
    users << User.create!(
      full_name: user_data[:full_name],
      email: user_data[:email],
      password: '123456',
      password_confirmation: '123456',
      account: account
    )
  end

  # Pipeline and Stages
  pipeline = Pipeline.create!(name: 'Sales', account: account)

  stages_data = [
    { name: 'New Lead', position: 1 },
    { name: 'Qualification', position: 2 },
    { name: 'Proposal Sent', position: 3 },
    { name: 'Negotiation', position: 4 },
    { name: 'Closing', position: 5 }
  ]

  stages = stages_data.map do |stage_data|
    Stage.create!(pipeline: pipeline, name: stage_data[:name], position: stage_data[:position], account: account)
  end

  # Products
  products_data = [
    { name: 'Starter Plan', identifier: 'PLAN-STARTER', amount_in_cents: 9_900, quantity_available: 999,
      description: 'Starter plan for small businesses' },
    { name: 'Professional Plan', identifier: 'PLAN-PRO', amount_in_cents: 29_900, quantity_available: 999,
      description: 'Professional plan with advanced features' },
    { name: 'Enterprise Plan', identifier: 'PLAN-ENT', amount_in_cents: 99_900, quantity_available: 999,
      description: 'Enterprise plan with dedicated support' },
    { name: 'Consulting (hour)', identifier: 'CONSULT-HR', amount_in_cents: 35_000, quantity_available: 500,
      description: 'Specialized consulting hour' },
    { name: 'Basic Implementation', identifier: 'IMPL-BASIC', amount_in_cents: 150_000, quantity_available: 100,
      description: 'Basic implementation service' },
    { name: 'Full Implementation', identifier: 'IMPL-FULL', amount_in_cents: 500_000, quantity_available: 50,
      description: 'Full implementation service with training' },
    { name: 'Online Training', identifier: 'TRAIN-ONLINE', amount_in_cents: 50_000, quantity_available: 200,
      description: 'Online training for teams' },
    { name: 'On-site Training', identifier: 'TRAIN-ONSITE', amount_in_cents: 150_000, quantity_available: 50,
      description: 'On-site training at the company' }
  ]

  products = products_data.map do |product_data|
    Product.create!(
      name: product_data[:name],
      identifier: product_data[:identifier],
      amount_in_cents: product_data[:amount_in_cents],
      quantity_available: product_data[:quantity_available],
      description: product_data[:description],
      account: account
    )
  end

  # Contacts
  contacts_data = [
    { full_name: 'Ana Silva', email: 'ana.silva@techcorp.com', phone: '+5511999001001' },
    { full_name: 'Bruno Costa', email: 'bruno.costa@innovation.com', phone: '+5511999002002' },
    { full_name: 'Carla Oliveira', email: 'carla@startupx.io', phone: '+5511999003003' },
    { full_name: 'Daniel Santos', email: 'daniel.santos@bigcompany.com', phone: '+5511999004004' },
    { full_name: 'Elena Ferreira', email: 'elena@consulting.com', phone: '+5511999005005' },
    { full_name: 'Fernando Lima', email: 'fernando@industry.com', phone: '+5511999006006' },
    { full_name: 'Gabriela Rocha', email: 'gabi@ecommerce.com', phone: '+5511999007007' },
    { full_name: 'Henrique Almeida', email: 'henrique@finance.com', phone: '+5511999008008' },
    { full_name: 'Isabela Martins', email: 'isabela@education.com', phone: '+5511999009009' },
    { full_name: 'John Smith', email: 'john.smith@logistics.com', phone: '+5511999010010' },
    { full_name: 'Karen Dias', email: 'karen@healthcare.com', phone: '+5511999011011' },
    { full_name: 'Lucas Mendes', email: 'lucas@agency.com', phone: '+5511999012012' },
    { full_name: 'Mariana Nunes', email: 'mariana@retail.com', phone: '+5511999013013' },
    { full_name: 'Nicolas Barbosa', email: 'nicolas@tech.io', phone: '+5511999014014' },
    { full_name: 'Olivia Cardoso', email: 'olivia@media.com', phone: '+5511999015015' }
  ]

  contacts = contacts_data.map do |contact_data|
    Contact.create!(
      full_name: contact_data[:full_name],
      email: contact_data[:email],
      phone: contact_data[:phone],
      account: account
    )
  end

  # Deals in different stages and statuses
  deals_data = [
    # Deals in New Lead
    { name: 'CRM Project - TechCorp', stage: stages[0], contact: contacts[0], status: 'open' },
    { name: 'Sales System - Innovation', stage: stages[0], contact: contacts[1], status: 'open' },

    # Deals in Qualification
    { name: 'Marketing Automation - StartupX', stage: stages[1], contact: contacts[2], status: 'open' },
    { name: 'Full ERP - BigCompany', stage: stages[1], contact: contacts[3], status: 'open' },
    { name: 'Digital Consulting - Consulting SA', stage: stages[1], contact: contacts[4], status: 'open' },

    # Deals in Proposal Sent
    { name: 'Cloud Migration - Industry', stage: stages[2], contact: contacts[5], status: 'open' },
    { name: 'B2B E-commerce - Ecommerce', stage: stages[2], contact: contacts[6], status: 'open' },

    # Deals in Negotiation
    { name: 'Financial Platform - Finance', stage: stages[3], contact: contacts[7], status: 'open' },
    { name: 'Corporate LMS - Education', stage: stages[3], contact: contacts[8], status: 'open' },
    { name: 'Logistics System - Logistics', stage: stages[3], contact: contacts[9], status: 'open' },

    # Deals in Closing
    { name: 'Healthcare App - Healthcare', stage: stages[4], contact: contacts[10], status: 'open' },

    # Won Deals
    { name: 'Corporate Website - Agency', stage: stages[4], contact: contacts[11], status: 'won',
      won_at: 5.days.ago },
    { name: 'Integrated POS - Retail', stage: stages[4], contact: contacts[12], status: 'won', won_at: 2.weeks.ago },
    { name: 'API Gateway - Tech.io', stage: stages[3], contact: contacts[13], status: 'won', won_at: 1.month.ago },

    # Lost Deals
    { name: 'Media Portal - Media', stage: stages[2], contact: contacts[14], status: 'lost', lost_at: 1.week.ago,
      lost_reason: 'Budget above expected' }
  ]

  deals = deals_data.map do |deal_data|
    Deal.create!(
      name: deal_data[:name],
      stage: deal_data[:stage],
      pipeline: pipeline,
      contact: deal_data[:contact],
      status: deal_data[:status],
      creator: users.sample,
      won_at: deal_data[:won_at],
      lost_at: deal_data[:lost_at],
      lost_reason: deal_data[:lost_reason] || '',
      account: account
    )
  end

  # Add products to deals
  deals.each do |deal|
    products.sample(rand(1..3)).each do |product|
      quantity = rand(1..5)
      DealProduct.create!(
        deal: deal,
        product: product,
        account: account,
        product_name: product.name,
        product_identifier: product.identifier,
        unit_amount_in_cents: product.amount_in_cents,
        quantity: quantity,
        total_amount_in_cents: product.amount_in_cents * quantity
      )
    end
  end

  deals.each do |deal|
    DealAssignee.create!(deal: deal, user: users.sample, account: account)
  end

  # Create activities and notes
  deals.each do |deal|
    Event.create!(
      deal: deal,
      contact: deal.contact,
      kind: 'note',
      title: 'First contact',
      content: "Customer reached out interested in our services. Showed initial interest in #{products.sample.name}.",
      account: account
    )

    # Scheduled activities (future)
    Event.create!(
      deal: deal,
      contact: deal.contact,
      kind: 'activity',
      title: 'Follow-up',
      scheduled_at: rand(1..14).days.from_now,
      content: 'Make follow-up call to check interest',
      account: account
    )

    # Overdue activities (for some deals)
    if [true, false].sample
      Event.create!(
        deal: deal,
        contact: deal.contact,
        kind: 'activity',
        title: 'Send proposal',
        scheduled_at: rand(1..7).days.ago,
        content: 'Prepare and send commercial proposal',
        account: account
      )
    end

    # Completed activities (for some deals)
    next unless [true, false].sample

    Event.create!(
      deal: deal,
      contact: deal.contact,
      kind: 'activity',
      title: 'Initial meeting',
      scheduled_at: rand(7..30).days.ago,
      done_at: rand(7..30).days.ago,
      content: 'Service presentation meeting',
      account: account
    )
  end

  # Create additional overdue activities
  3.times do |i|
    deal = deals.sample
    Event.create!(
      deal: deal,
      contact: deal.contact,
      kind: 'activity',
      title: "Urgent task #{i + 1}",
      scheduled_at: rand(1..5).days.ago,
      content: 'This activity is overdue and needs attention',
      account: account
    )
  end

  puts 'Created seed data'
end

if Rails.env.test?
  Installation.create!(
    id: SecureRandom.uuid,
    key1: Faker::Alphanumeric.alphanumeric(number: 10),
    key2: Faker::Alphanumeric.alphanumeric(number: 10),
    status: 'completed',
    token: Faker::Alphanumeric.alphanumeric(number: 20)
  )
  puts 'Created seed test data'
end
