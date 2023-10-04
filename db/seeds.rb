# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


if User.all.count == 0
  account_1 = Account.create(name: 'Company 1')


  user_1 = User.create(full_name: 'User 1', email: 'user1@email.com', password: '123456', password_confirmation: '123456', account: account_1)
  user_2 = User.create(full_name: 'User 2', email: 'user2@email.com', password: '123456', password_confirmation: '123456', account: account_1)
  user_3 = User.create(full_name: 'User 3', email: 'user3@email.com', password: '123456', password_confirmation: '123456', account: account_1)

  pipeline = Pipeline.create(name: 'Sales' , account: account_1)
  stage_1 = Stage.create(pipeline: pipeline, name: 'New', position: 1, account: account_1)
  stage_2 = Stage.create(pipeline: pipeline, name: 'Qualifying', position: 2, account: account_1)
  stage_3 = Stage.create(pipeline: pipeline, name: 'Proposal', position: 3, account: account_1)
  stage_4 = Stage.create(pipeline: pipeline, name: 'Follow Up', position: 4, account: account_1)

  contacts = []
  20.times do | time |
    contacts.append(Contact.create(full_name: "Contact #{time}", email: "contact#{time}@email.com", phone: '41998910151', account: account_1))
  end

  deal_1 = Deal.create(name: 'Deal 1', stage: stage_1, status: 'open', contact: contacts[0], account: account_1, position: 1)
  deal_2 = Deal.create(name: 'Deal 2', stage: stage_2, status: 'open', contact: contacts[1], account: account_1, position: 2)
  deal_3 = Deal.create(name: 'Deal 3', stage: stage_3, status: 'open', contact: contacts[2], account: account_1, position: 3)
  # deal_1 = Deal.create(name: 'Deal 1', stage: stage_1, status: 'open', contacts: [ contacts[0] ], account: account_1)
  # deal_2 = Deal.create(name: 'Deal 2', stage: stage_2, status: 'open', contacts: [ contacts[1] ], account: account_1)
  # deal_3 = Deal.create(name: 'Deal 3', stage: stage_3, status: 'open', contacts: [ contacts[2] ], account: account_1)

  #event_kind_1 = EventKind.create(name: 'Call', key: 'call', icon_key: 'fas fa-phone', enabled: true)
  #event_kind_2 = EventKind.create(name: 'Email', key: 'email', icon_key: 'far fa-envelope', enabled: true)
  #event_kind_3 = EventKind.create(name: 'Note', key: 'note', icon_key: 'far fa-sticky-note', enabled: true)
  #event_kind_4 = EventKind.create(name: 'Whatsapp', key: 'whatsapp', icon_key: 'fab fa-whatsapp', enabled: true, settings: {'secretkey': 'THISISMYSECURETOKEN', 'endpoint_url': 'https://wppconnect-server-open-crm.herokuapp.com', 'enabled': false, 'session': '', 'token': ''})
  
  event_1 = Event.create(account: account_1, contact: deal_1.contact, deal: deal_1, kind: 'note', from_me: true )
  event_2 = Event.create(account: account_1, contact: deal_2.contact, deal: deal_2, kind: 'note', from_me: true )
  event_3 = Event.create(account: account_1, contact: deal_3.contact, deal: deal_3, kind: 'note', from_me: true )
  
  puts('Created seed data')  
end
