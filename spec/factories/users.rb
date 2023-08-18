FactoryBot.define do
  factory :user do
    account
    full_name { 'Belchior' }
    email { 'belchior@show.com.br' }
    password { 'Password1!' }
  end
end
