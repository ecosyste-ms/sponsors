class AccountWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'default', lock: :until_executed, lock_expiration: 1.hours.to_i

  def perform(account_id)
    Account.find_by_id(account_id).try(:sync_all)
  end
end