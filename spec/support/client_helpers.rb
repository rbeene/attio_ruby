# frozen_string_literal: true

module ClientHelpers
  def stub_client_request(method, path, response_body, status: 200)
    client = instance_double(Attio::Client)
    allow(Attio).to receive(:client).and_return(client)

    allow(client).to receive(method).with(path, anything) do |_, params|
      if response_body.is_a?(Proc)
        response_body.call(params)
      else
        response_body
      end
    end

    client
  end

  def stub_api_request(method, path, response_body, status: 200)
    stub_request(method, "https://api.attio.com/v2#{path}")
      .to_return(
        status: status,
        body: response_body.to_json,
        headers: {"Content-Type" => "application/json"}
      )
  end
end

RSpec.configure do |config|
  config.include ClientHelpers
end
