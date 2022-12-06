# The xero-api gem

### Ruby client for the Xero API version 2.
- **Pure JSON-in / JSON-out.** No XML support.
- 4 main methods: **.get, .create, .update, and .delete**.
- No validation rules built into the gem. **Validation comes from the API only**.
- Close to the metal experience.
- First class logging.
- Robust error handling.
- Specs are built using real requests run directly against the Xero Demo Company. Thanks [VCR](https://github.com/vcr/vcr).
- Built leveraging [Faraday](https://github.com/lostisland/faraday).
- Built knowing that OAuth2 might be in the not-to-distant future.

## Sweet, How Can I Get Started Fast?

The fastest method is to start with this [screencast](https://minimul.com/getting-started-with-the-xero-api-gem.html).

## Why another library when there are other more mature, established Ruby Xero libraries?

Both of the current de facto Ruby Xero client gems were built 6+ years ago when the Xero API was XML only, therefore, they are loaded with *XML cruft*.
For example, here are the total code line counts (of `.rb` files):

- Total LOC count of :
  - **minimul/xero-api** => **910!** 🌈
  - waynerobinson/xeroizer => 6019
  - xero-gateway/xero_gateway => 5545

## Ruby >= 2.4.0 required

## Current Limitations

- Accounting API only.
- Only [Custom Connections](https://developer.xero.com/documentation/guides/oauth2/custom-connections) and OAuth2 are supported.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'xero-api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install xero-api


## Initialize

```ruby
  require 'oauth2'
  require 'xero/api'

  client = OAuth2::Client.new(ENV['XERO_OAUTH2_CLIENT_ID'), ENV['XERO_OAUTH2_CLIENT_SECRET'], token_url: 'https://identity.xero.com/connect/token' )
  client_credentials = client.client_credentials.get_token

  api = Xero::Api.new(access_token: client_credentials.token)
```

## .get

### Important
One queries the Xero API [mostly using URL parameters](https://developer.xero.com/documentation/api/requests-and-responses) so `xero-api` doesn't do a lot of "hand holding" and has the `params` argument enabling you to craft your queries as you see fit. Likewise, the `path` argument allows you to forge the URL path you desire. The `params` and `path` arguments are available on `.create`, `.update`, `delete`, and `.upload_attachment` as well.

```ruby
  # Basic get - retrieves first 100 contacts
  resp = api.get(:contacts)
  # Retrieves all contacts - returns Enumerator so you can do cool stuff
  resp = api.get(:contacts, all: true)
  p resp.count #=> 109
  # Retrieves all contacts modified after a certain date
  resp = api.get(:items, all: true, modified_since: Time.utc(2014, 01, 01))
  # Retrieves only customers
  resp = api.get(:contacts, params: { where: 'IsCustomer=true' })
  # Retrieve by id
  resp = api.get(:contacts, id: '323-43fss-4234dfa-3432233')
  # Retrieve with custom path
  resp = api.get(:users, path: '3138017f-8ddc-420e-a159-e7e1cf9e643d/History')
```

See all the arguments for the [`.get` method](https://github.com/minimul/xero-api/blob/447170ff1035103ed251bf203cf95450bda0f377/lib/xero/api/methods.rb#L4).

## .create

```ruby
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
  response = api.create(:invoice, payload: payload)
  inv_num = response.dig("Invoices", 0, "InvoiceNumber")
  p inv_num #=> 'INV-0041'
```

##### bulk .create
```ruby
  payload = { "Contacts": [] }
  60.times do
    payload[:Contacts] << { "Name": Faker::Name.unique.name, "IsCustomer": true }
  end
  resp = api.create(:contacts, payload: payload, params: { summarizeErrors: false })
  p resp.dig("Contacts").size #=> 60
```

See all the arguments for the [`.create` method](https://github.com/minimul/xero-api/blob/447170ff1035103ed251bf203cf95450bda0f377/lib/xero/api/methods.rb#L14).

## .update

```ruby
  payload = {
    "InvoiceNumber": 'INV-0038',
    "Status": 'VOIDED'
  }
  response = api.update(:invoices, id: 'INV-0038', payload: payload)
  p response.dig("Invoices", 0, "Status") #=> VOIDED
```

See all the arguments for the [`.update` method](https://github.com/minimul/xero-api/blob/447170ff1035103ed251bf203cf95450bda0f377/lib/xero/api/methods.rb#L19).

## .delete

```ruby
  api.delete(:items, id: "e1d100f5-a602-4f0e-94b7-dc12e97b9bc2")
```
See all the arguments for the [`.delete` method](https://github.com/minimul/xero-api/blob/447170ff1035103ed251bf203cf95450bda0f377/lib/xero/api/methods.rb#L25).

## Configuration options
```
- Logging:
```ruby
Xero::Api.log = true
```
- To change logging target from `$stdout` e.g.
```ruby
Xero::Api.logger = Rails.logger
```

## Other stuff

### .upload_attachment
```ruby
  file_name = 'connect_xero_button_blue_2x.png'
  resp = api.upload_attachment(:invoices, id: '9eb7b996-4ac6-4cf8-8ee8-eb30d6e572e3',
                               file_name: file_name, content_type: 'image/png',
                               attachment: "#{__dir__}/../../../example/public/#{file_name}")
```

### Respond to an error
```ruby
  customer = { Name: 'Already Exists', EmailAddress: 'newone@already.com' }
  begin
    response = api.create(:contacts, payload: customer)
  rescue Xero::Api::BadRequest => e
    if e.message =~ /already exists/
      # Query for Id using Name
      resp = api.get(:contacts, params: { where: "Name='Already Exists'" })
      # Do an update instead
      up_resp = api.update(:contacts, id: resp["Id"], payload: payload)
    end
  end
```

### Spin up an example

1. Follow and do all in Step 1 from the [Getting Started Guide](https://developer.xero.com/documentation/getting-started/getting-started-guide).
1. `git clone git://github.com/minimul/xero-api && cd xero-api`
1. `bundle`
1. Create a `.env` file
  1. `cp .env.example_app.oauth1 .env`
  1. Edit the `.env` file values with `consumer_key` and `consumer_secret`.
1. Start up the example app => `ruby example/oauth.rb`
1. In browser go to `http://localhost:9393`.
1. Use the `Connect to Xero` button to connect to your Xero account.
1. After successfully connecting click on the displayed link => `View All Customers`
1. Checkout [`example/oauth.rb`](https://github.com/minimul/xero-api/blob/master/example/oauth.rb)
  to see what is going on under the hood.
  - **Important:** In the [`/auth/xero/callback`](https://github.com/minimul/xero-api/blob/master/example/oauth.rb) route there is code there that will automatically update your `.env` file.

### Protip: Once your .env file is completely filled out you can use the console to play around
```
bin/console test
>> @xero_api.get :contacts, id: '5345-as543-4-afgafadsafsad-45334'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/minimul/xero-api.

#### Running the specs
- `git clone git://github.com/minimul/xero-api && cd xero-api`
- `bundle`
- Create a `.env` file
  - `cp .env.example_app.oauth1 .env`
- `bundle exec rake`

#### Creating new specs or modifying existing spec that have been recorded using the VCR gem.
- All specs that require interaction with the API must be recorded against the Xero Demo Company.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
