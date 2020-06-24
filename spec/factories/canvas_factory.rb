# -*- encoding : utf-8 -*-
# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :canvas, :class => Api::Canvas do
    sequence(:name) { |n| "My awesome canvas no #{n}" }
    association :user, :factory => :user
    association :client_application,
      :factory => :client_application
  end
end
