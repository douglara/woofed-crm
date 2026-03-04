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
    { full_name: 'Maria Sales', email: 'user2@email.com' },
    { full_name: 'John Commercial', email: 'user3@email.com' }
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

  # Products - random values between R$10,000 and R$50,000
  products_data = [
    { name: 'Starter Plan', identifier: 'PLAN-STARTER', quantity_available: 999,
      description: 'Starter plan for small businesses' },
    { name: 'Professional Plan', identifier: 'PLAN-PRO', quantity_available: 999,
      description: 'Professional plan with advanced features' },
    { name: 'Enterprise Plan', identifier: 'PLAN-ENT', quantity_available: 999,
      description: 'Enterprise plan with dedicated support' },
    { name: 'Consulting (hour)', identifier: 'CONSULT-HR', quantity_available: 500,
      description: 'Specialized consulting hour' },
    { name: 'Basic Implementation', identifier: 'IMPL-BASIC', quantity_available: 100,
      description: 'Basic implementation service' },
    { name: 'Full Implementation', identifier: 'IMPL-FULL', quantity_available: 50,
      description: 'Full implementation service with training' },
    { name: 'Online Training', identifier: 'TRAIN-ONLINE', quantity_available: 200,
      description: 'Online training for teams' },
    { name: 'On-site Training', identifier: 'TRAIN-ONSITE', quantity_available: 50,
      description: 'On-site training at the company' }
  ]

  products = products_data.map do |product_data|
    Product.create!(
      name: product_data[:name],
      identifier: product_data[:identifier],
      amount_in_cents: rand(1_000..5_000_000),
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

  # Deals - 1000 per stage per status (5 stages x 3 statuses x 1000 = 15,000 deals)
  statuses = %w[open won lost]
  contact_ids = contacts.map(&:id)
  user_ids = users.map(&:id)
  now = Time.current

  deal_records = []
  deal_products_data = []

  stages.each do |stage|
    stage_position = 0

    statuses.each do |status|
      status_label = status.capitalize

      1000.times do |i|
        stage_position += 1
        seq = i + 1

        won_at = status == 'won' ? rand(1..90).days.ago : nil
        lost_at = status == 'lost' ? rand(1..90).days.ago : nil
        lost_reason = status == 'lost' ? 'Budget constraints' : ''

        product = products.sample
        quantity = rand(1..20)
        deal_amount = product.amount_in_cents * quantity

        deal_records << {
          name: "[#{stage.name}] #{status_label} ##{seq} (pos #{stage_position})",
          stage_id: stage.id,
          pipeline_id: pipeline.id,
          contact_id: contact_ids.sample,
          status: status,
          position: stage_position,
          won_at: won_at,
          lost_at: lost_at,
          lost_reason: lost_reason,
          total_deal_products_amount_in_cents: deal_amount,
          created_by_id: user_ids.sample,
          created_at: now,
          updated_at: now
        }

        deal_products_data << {
          product_id: product.id,
          product_name: product.name,
          product_identifier: product.identifier,
          unit_amount_in_cents: product.amount_in_cents,
          quantity: quantity,
          total_amount_in_cents: deal_amount,
          created_at: now,
          updated_at: now
        }
      end
    end
  end

  # Bulk insert deals and deal_products together per batch to guarantee ID pairing
  deal_records.each_slice(500).with_index do |deal_batch, batch_idx|
    result = Deal.insert_all(deal_batch, returning: [:id])
    deal_ids = result.rows.flatten

    dp_batch = deal_products_data.slice(batch_idx * 500, deal_batch.size)

    dp_records = deal_ids.zip(dp_batch).map do |deal_id, dp|
      dp.merge(deal_id: deal_id)
    end

    DealProduct.insert_all(dp_records)
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
