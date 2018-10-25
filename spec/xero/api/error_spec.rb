require 'spec_helper'

describe "Xero::Api Error handling" do

  let(:api){ Xero::Api.new(creds.to_h) }

  it 'handles a 401 error' do
    api = Xero::Api.new(creds.to_h.merge(token: 12345))
    use_cassette("error/oauth1/401", record: :none) do
      expect {
        api.get :journals
      }.to raise_error Xero::Api::Unauthorized, /oauth_problem=token_rejected/
    end
  end

  it 'handles a 404 error' do
    use_cassette("error/oauth1/404", record: :none) do
      expect {
        response = api.update :bank_statements, id: '34323-343434dsaf-3431', payload: {}
      }.to raise_error Xero::Api::NotFound, /cannot be found/
    end
  end

  it 'handles a validation error' do
    customer = { Name: 'Bayside Club' }
    use_cassette("error/oauth1/validation", record: :none) do
      begin
        response = api.create :contacts, payload: customer
      rescue Xero::Api::BadRequest => e
        expect(e.fault["Message"]).to match 'A validation exception occurred'
      end
    end
  end


end
