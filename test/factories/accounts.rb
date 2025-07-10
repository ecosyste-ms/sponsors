FactoryBot.define do
  factory :account do
    login { "testuser" }
    has_sponsors_listing { true }
    sponsors_count { 5 }
    sponsorships_count { 3 }
    active_sponsorships_count { 2 }
    active_sponsors_count { 4 }
    minimum_sponsorship_amount { 1 }
    data do
      {
        "kind" => "user",
        "repositories_count" => 10,
        "description" => "Test user description",
        "funding_links" => ["https://github.com/sponsors/testuser"]
      }
    end
    sponsor_profile do
      {
        "bio" => "Test bio",
        "featured_works" => [],
        "current_sponsors" => 4,
        "past_sponsors" => 1
      }
    end
    
    trait :organization do
      data do
        {
          "kind" => "organization",
          "repositories_count" => 50,
          "description" => "Test organization description",
          "funding_links" => ["https://github.com/sponsors/testorg"]
        }
      end
    end
    
    trait :without_sponsors_listing do
      has_sponsors_listing { false }
    end
    
    trait :with_many_sponsors do
      sponsors_count { 100 }
      active_sponsors_count { 80 }
    end
  end
end