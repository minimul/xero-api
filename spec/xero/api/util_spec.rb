require 'spec_helper'

describe Xero::Api::Util do
  let(:api){ Xero::Api.new(creds.to_h) }

  describe ".add_params" do

    it 'properly adds params when other url params are set' do
      base_url = "#{api.endpoint_url}#{api.entity_handler(:invoice_reminders)}"
      url = api.add_params(route: base_url, params: { summarizeErrors: false } )
      expect(url).to match /\?summarizeErrors=false/
      url = api.add_params(route: url, params: { page: 7 } )
      expect(url).to match /&page=7$/
    end
  end

  it '.standard_date returns properly formatted date' do
    expect(api.standard_date(Time.utc(2017, 05, 10, 12, 0, 0))).to eq "2017-05-10T12:00:00"
  end

  it '.json_date returns properly formatted date' do
    expect(api.json_date(Time.utc(2017, 05, 10))).to eq "/Date(1494374400000)/"
  end

  it '.parse_json_date converts into a Ruby Time object' do
    expect(api.parse_json_date("/Date(1494374400000)/")).to be_a(Time)
  end

end
