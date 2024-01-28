# frozen_string_literal: true

require 'uploadcare'
require 'net/http'

module ActiveStorage
  class Service
    class UploadcareService < Service
      attr_reader :settings, :container

      def initialize(public_key:, secret_key:, **options)
        super()

        ::Uploadcare.config.public_key = public_key
        ::Uploadcare.config.secret_key = secret_key
        @cname = options[:cname]
        @signing_secret = options[:signing_secret]
      end

      def upload(key, io, checksum: nil, disposition: nil, content_type: nil, filename: nil, **)
        instrument :upload, key: key, checksum: checksum do
          uploadcare_file = ::Uploadcare::Uploader.upload(io, store: true)

          ActiveStorage::Uploadcare::KeyUuid.create!(key: key, uuid: uploadcare_file.uuid)
        end
      end

      def download(key, &block)
        uuid = find_uuid_by_key!(key)

        uri = URI(::Uploadcare::File.file(uuid)['original_file_url'])
        if block_given?
          instrument :streaming_download, key: key do
            Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new uri
              http.request request do |response|
                response.read_body(&block)
              end
            end
          end
        else
          instrument :download, key: key do
            res = Net::HTTP.get_response(uri)
            res.body.force_encoding(Encoding::BINARY)
          end
        end
      end

      def download_chunk(key, range)
        instrument :download_chunk, key: key, range: range do
          uuid = find_uuid_by_key!(key)

          uri = URI(::Uploadcare::File.file(uuid)['original_file_url'])
          http = Net::HTTP.new(uri.host, uri.port)
          req = Net::HTTP::Get.new(uri.request_uri)

          http.use_ssl = true if uri.port == 443

          req.range = range

          chunk = http.start { |client| client.request(req).body }
          chunk.force_encoding(Encoding::BINARY)
        end
      end

      def delete(key)
        instrument :delete, key: key do
          uuid = find_uuid_by_key(key)
          return if uuid.blank?

          ::Uploadcare::File.file(uuid).delete
        end
      end

      def delete_prefixed(prefix)
        keys = ActiveStorage::Uploadcare::KeyUuid.where("key LIKE ?", "#{prefix}%").pluck(:key)
        keys.each { |key| delete(key) }
      end

      def exist?(key)
        instrument :exist, key: key do |_payload|
          uuid = find_uuid_by_key(key)
          return false if uuid.blank?

          ::Uploadcare::File.file(uuid)['original_file_url'].present?
        end
      end

      def url(key, **options)
        uuid = find_uuid_by_key!(key)

        if @signing_secret.present?
          private_url(uuid, **options)
        else
          public_url(uuid, **options)
        end
      end

      def url_for_direct_upload(key, **)
        instrument :url, key: key do |_payload|
          raise NotImplementedError
        end
      end

      def headers_for_direct_upload(_key, **)
        {}
      end

      private

      def private_url(uuid, **options)
        expires_in = options[:expires_in] || 5.minutes

        generator = ::Uploadcare::SignedUrlGenerators::AmakaiGenerator.new(cdn_host: @cname, secret_key: @signing_secret, ttl: expires_in)
        generator.generate_url(uuid)
      end

      def public_url(uuid, **options)
        "https://#{options[:cname] || 'ucarecdn.com'}/#{uuid}/"
      end

      def find_uuid_by_key(key)
        ActiveStorage::Uploadcare::KeyUuid.find_by(key: key)&.uuid
      end

      def find_uuid_by_key!(key)
        uuid = find_uuid_by_key(key)
        raise ActiveStorage::FileNotFoundError if defined?(ActiveStorage::FileNotFoundError) && uuid.blank?

        uuid
      end
    end
  end
end
