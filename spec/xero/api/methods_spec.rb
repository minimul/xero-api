require 'spec_helper'

describe Xero::Api::Methods do

  let(:api) { Xero::Api.new(creds.to_h) }

  describe ".get" do

    it 'perform a basic get' do
      use_cassette("get/contacts", record: :none) do
        resp = api.get(:contacts)
        expect(resp.size).to eq 49
      end
    end

    it 'all contacts' do
      use_cassette("get/contacts_all", record: :none) do
        resp = api.get(:contacts, all: true)
        expect(resp.count).to eq 109
      end
    end

    it 'all items' do
      use_cassette("get/items_all", record: :none) do
        resp = api.get(:items, all: true, modified_since: Time.utc(2014, 01, 01))
        items = resp.collect { |item| item }
        expect(items.size).to eq 11
      end
    end
  end

  describe ".create" do

    it 'an invoice' do
      payload = {
          "Type": "ACCREC",
          "Contact": { 
            "ContactID": "f477ad8d-44f2-4bb7-a99b-04f28681e849" 
          },
          "DateString": api.standard_date(Time.utc(2009, 05, 27)),
          "DueDateString": api.standard_date(Time.utc(2009, 06, 06)),
          "LineAmountTypes": "Exclusive",
          "LineItems": [
            {
              "Description": "Consulting services as agreed (20% off standard rate)",
              "Quantity": "10",
              "UnitAmount": "100.00",
              "AccountCode": "200",
              "DiscountRate": "20"
            }
          ]
      }
      use_cassette("create/invoice", record: :none) do
        response = api.create(:invoice, payload: payload)
        inv_num = response.dig("Invoices", 0, "InvoiceNumber")
        expect(inv_num).to eq 'INV-0041'
      end
    end

    it '60 customers in a bulk upload' do
      payload = { "Contacts": [] }
      60.times do
        payload[:Contacts] << { "Name": Faker::Name.unique.name, "IsCustomer": true }
      end
      use_cassette("get/contacts_bulk", record: :none) do
        resp = api.create(:contacts, payload: payload, params: { summarizeErrors: false })
        expect(resp.dig("Contacts").size).to eq 60
      end
    end
  end

  describe '.update' do

    it 'an invoice and return the response back raw' do
      # Take Invoice Number from Demo Company - Invoice awaiting payment
      status = "VOIDED"
      inv_num = 'INV-0038' 
      payload = {
        "InvoiceNumber": inv_num,
        "Status": status 
      }
      use_cassette("update/invoice", record: :none) do
        response = api.update(:invoices, id: inv_num, payload: payload)
        expect(response.dig("Invoices", 0, "Status")).to eq status
      end
    end
  end #= end '.update

  describe '.delete' do

    it 'an item' do
      use_cassette("delete/item", record: :none) do
        expect { api.delete(:items, id: "e1d100f5-a602-4f0e-94b7-dc12e97b9bc2") }.to_not raise_error
      end
    end
  end

  describe ".build_resource" do
    
    Xero::Api.send(:public, :build_resource)
    
    it 'handles different params scenarios' do
      route = api.build_resource('Contacts')
      expect(route).to eq 'Contacts'
      route = api.build_resource(:contacts, params: { 'Statuses': 'DELETED,VOIDED' })
      expect(route).to eq "Contacts?Statuses=DELETED%2CVOIDED"
      route = api.build_resource(:linked_transactions, params: { 'Statuses': 'DELETED,VOIDED' })
      expect(route).to eq "LinkedTransactions?Statuses=DELETED%2CVOIDED"
      route = api.build_resource(:invoices, params: { 'ContactIDs' => '3138017f-8ddc-420e-a159-e7e1cf9e643d,4b2df4a1-7aa5-4ce3-9e9c-3c55794c5283', 'Statuses': 'Authorized' })
      expect(route).to eq "Invoices?ContactIDs=3138017f-8ddc-420e-a159-e7e1cf9e643d%2C4b2df4a1-7aa5-4ce3-9e9c-3c55794c5283&Statuses=Authorized"
      route = api.build_resource(:employees, params: { 'where' => 'Type=="BANK"' })
      expect(route).to eq "Employees?where=Type%3D%3D%22BANK%22"
    end

    it 'with an id' do
      expect(api.build_resource(:users, id: '3138017f-8ddc-420e-a159-e7e1cf9e643d')).to eq "Users/3138017f-8ddc-420e-a159-e7e1cf9e643d"
    end

    it 'using a path' do
      expect(api.build_resource(:users, path: '3138017f-8ddc-420e-a159-e7e1cf9e643d/History')).to eq "Users/3138017f-8ddc-420e-a159-e7e1cf9e643d/History"
    end

  end

  describe ".handle_headers" do

    it "works with just modified_since argument and not a headers argument" do
      headers = api.send(:handle_headers, nil, Time.utc(2017, 05, 19))
      expect(headers).to eq ({ "If-Modified-Since" => "2017-05-19T00:00:00" })
    end

    it "works with both supplied arguments" do
      hash = { "Pragma" => "no-cache" }
      headers = api.send(:handle_headers, hash, Time.utc(2017, 05, 19))
      expect(headers).to eq ({ "If-Modified-Since" => "2017-05-19T00:00:00" }.merge(hash))
    end

    it "works with no supplied arguments" do
      headers = api.send(:handle_headers, nil, nil)
      expect(headers).to be {}
    end

    it "throw error if modified_since argument is supplied but not a Time object" do
      expect { api.send(:handle_headers, nil, '2017-05-19') }.to raise_error Xero::Api::Error
    end
  end
end
