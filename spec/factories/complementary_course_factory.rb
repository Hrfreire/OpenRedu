# -*- encoding : utf-8 -*-
FactoryBot.define do
  factory :complementary_course do |c|
    c.sequence(:course) { |n| "Course #{n}" }
    c.institution "Institution"
    c.year Date.today - 1.year
    c.workload 80
    c.description "Lorem ipsum dolor sit amet, consectetur magna aliqua."
  end
end
