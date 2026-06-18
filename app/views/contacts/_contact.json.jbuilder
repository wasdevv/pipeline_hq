json.extract! contact, :id, :account_id, :name, :email, :phone, :role, :created_at, :updated_at
json.url contact_url(contact, format: :json)
