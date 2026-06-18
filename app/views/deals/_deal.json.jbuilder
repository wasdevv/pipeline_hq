json.extract! deal, :id, :title, :account_id, :contact_id, :stage_id, :amount_cents, :currency, :expected_close_on, :status, :created_at, :updated_at
json.url deal_url(deal, format: :json)
