# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


if User.all.count == 0

  user_1 = User.create(full_name: 'User 1', email: 'user1@email.com', password: '123456', password_confirmation: '123456')
  user_2 = User.create(full_name: 'User 2', email: 'user2@email.com', password: '123456', password_confirmation: '123456')
  user_3 = User.create(full_name: 'User 3', email: 'user3@email.com', password: '123456', password_confirmation: '123456')

  pipeline = Pipeline.create(name: 'Sales')
  stage_1 = Stage.create(pipeline: pipeline, name: 'New', order: 1)
  stage_2 = Stage.create(pipeline: pipeline, name: 'Qualifying', order: 2)
  stage_3 = Stage.create(pipeline: pipeline, name: 'Proposal', order: 3)
  stage_4 = Stage.create(pipeline: pipeline, name: 'Follow Up', order: 4)

  contacts = []
  20.times do | time |
    contacts.append(Contact.create(full_name: "Contact #{time}", email: "contact#{time}@email.com", phone: '41998910151'))
  end

  deal_1 = Deal.create(name: 'Deal 1', stage: stage_1, status: 'open', contact: contacts.sample)
  deal_2 = Deal.create(name: 'Deal 2', stage: stage_2, status: 'open', contact: contacts.sample)
  deal_3 = Deal.create(name: 'Deal 3', stage: stage_3, status: 'open', contact: contacts.sample)

  activity_kind_1 = ActivityKind.create(name: 'Call', key: 'call', icon_key: 'fas fa-phone', is_custom: false)
  activity_kind_2 = ActivityKind.create(name: 'Email', key: 'email', icon_key: 'far fa-envelope', is_custom: false)
  activity_kind_3 = ActivityKind.create(name: 'Whatsapp', key: 'whatsapp', icon_key: 'fab fa-whatsapp', is_custom: false, settings: {'secretkey': '', 'endpoint_url': '', 'enabled': false, 'session': '', 'token': ''})
  puts('Created seed data')  
end
