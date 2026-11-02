# frozen_string_literal: true

require 'net/http'
require 'openssl'
require 'uri'

# HttpClient is the one HTTP client the backend makes its requests with.
#
# Ported from upstream's src/backend/mod.rs, which holds a single lazily
# built `surf::Client` with the redirect middleware installed. Net::HTTP does
# not follow redirects on its own, so the hop limit upstream gets from
# `surf::middleware::Redirect::default()` is spelled out here.
module HttpClient
  MAX_REDIRECTS = 3
  OPEN_TIMEOUT = 15
  READ_TIMEOUT = 30
  USER_AGENT = 'share-preview-rb'

  # Raised when the request never produced a response: no route, refused
  # connection, TLS failure, timeout, too many redirects. Upstream's
  # equivalent is the `surf::Error` that `Error::NetworkError` wraps.
  class NetworkError < StandardError; end

  # A response that made it back, successful or not.
  Response = Struct.new(
    :status,
    :reason,
    :body,
    keyword_init: true,
  ) do
    def success? = status.between?(200, 299)
  end

  class << self
    # Performs a GET, following up to MAX_REDIRECTS redirects, and returns a
    # Response. Raises NetworkError when no response could be obtained.
    def get(url, redirects_left: MAX_REDIRECTS)
      uri = to_uri(url)
      response = request(uri)

      case response
      in {location: String => location} if redirects_left.positive?
        get(URI.join(uri, location), redirects_left: redirects_left - 1)
      in {location: String}
        raise NetworkError, 'Too many redirects'
      else
        response[:response]
      end
    end

    private

      def to_uri(url)
        case url
        when URI::Generic then url
        else URI.parse(url.to_s)
        end
      end

      # Returns either {location:} for a redirect or {response:} for anything
      # else, so #get can decide without a short-circuit return.
      def request(uri)
        unless uri.is_a?(URI::HTTP)
          raise NetworkError, "Unsupported scheme: #{uri.scheme.inspect}"
        end

        http_response = perform(uri)

        case http_response
        when Net::HTTPRedirection
          {location: http_response['location']}
        else
          {response: response_from(http_response)}
        end
      end

      def perform(uri)
        Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl:      uri.scheme == 'https',
          open_timeout: OPEN_TIMEOUT,
          read_timeout: READ_TIMEOUT,
        ) do |http|
          http.request(Net::HTTP::Get.new(uri, 'User-Agent' => USER_AGENT))
        end
      rescue SystemCallError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError, Net::HTTPBadResponse,
             Net::ProtocolError, IOError => e
        raise NetworkError, e.message
      end

      def response_from(http_response)
        Response.new(
          status: http_response.code.to_i,
          reason: http_response.message.to_s,
          body:   http_response.body.to_s,
        )
      end
  end
end
