FactoryBot.define do
  factory :sponsorship do
    association :funder, factory: :account
    association :maintainer, factory: :account
    status { "active" }
    
    trait :inactive do
      status { "inactive" }
    end
  end
end