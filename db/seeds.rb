# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Pipeline.all.count == 0
  pipeline = Pipeline.create(name: 'Sales')
  stage_1 = Stage.create(pipeline: pipeline, name: 'New', order: 1)
  stage_2 = Stage.create(pipeline: pipeline, name: 'Qualifying', order: 2)
  stage_3 = Stage.create(pipeline: pipeline, name: 'Proposal', order: 3)
  stage_4 = Stage.create(pipeline: pipeline, name: 'Follow Up', order: 4)
end

if User.all.count == 0
  user_1 = User.create(full_name: 'User 1', email: 'user1@email.com', password: '123456', password_confirmation: '123456')
  user_2 = User.create(full_name: 'User 2', email: 'user2@email.com', password: '123456', password_confirmation: '123456')
  user_3 = User.create(full_name: 'User 3', email: 'user3@email.com', password: '123456', password_confirmation: '123456')
end


if Deal.all.count == 0
  deal_1 = Deal.create(name: 'Deal 1', stage: stage_1, status: 'open')
  deal_2 = Deal.create(name: 'Deal 2', stage: stage_2, status: 'open')
  deal_3 = Deal.create(name: 'Deal 3', stage: stage_3, status: 'open')
end

