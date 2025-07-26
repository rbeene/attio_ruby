require_relative "errors/base"
require_relative "errors/client_errors"
require_relative "errors/server_errors"
require_relative "errors/connection_errors"
require_relative "errors/error_factory"

module Attio
  module Errors
    # Re-export commonly used errors at the module level for convenience
    Base = Errors::Base
    BadRequestError = Errors::BadRequestError
    AuthenticationError = Errors::AuthenticationError
    ForbiddenError = Errors::ForbiddenError
    NotFoundError = Errors::NotFoundError
    ConflictError = Errors::ConflictError
    UnprocessableEntityError = Errors::UnprocessableEntityError
    RateLimitError = Errors::RateLimitError
    ClientError = Errors::ClientError
    ValidationError = Errors::ValidationError
    InvalidRequestError = Errors::InvalidRequestError
    InternalServerError = Errors::InternalServerError
    BadGatewayError = Errors::BadGatewayError
    ServiceUnavailableError = Errors::ServiceUnavailableError
    GatewayTimeoutError = Errors::GatewayTimeoutError
    ServerError = Errors::ServerError
    ConnectionError = Errors::ConnectionError
    TimeoutError = Errors::TimeoutError
    SSLError = Errors::SSLError
    DNSError = Errors::DNSError
    SocketError = Errors::SocketError
  end
end