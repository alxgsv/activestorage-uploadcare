# frozen_string_literal: true

require 'test_helper'
require 'active_support/core_ext/securerandom'
require 'net/http'
require 'byebug'

if SERVICE_CONFIGURATIONS[:uploadcare]
  class ActiveStorage::Service::UploadcareServiceTest < ActiveSupport::TestCase
    setup do
      @service = ActiveStorage::Service.configure(:uploadcare, SERVICE_CONFIGURATIONS)
      @original_verbose = ActiveRecord::Migration.verbose
      ActiveRecord::Migration.verbose = false
      ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Migration.drop_table(table) }
      ActiveRecord::Base.connection.migration_context.migrate
      @connection = ActiveRecord::Base.connection
      @original_options = Rails.configuration.generators.options.deep_dup
    end

    teardown do
      Uploadcare.config.public_key = nil
      Uploadcare.config.secret_key = nil
      Rails.configuration.generators.options = @original_options

      begin
        ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Migration.drop_table(table) }
      rescue ActiveRecord::StatementInvalid
      end

      ActiveRecord::Migration.verbose = @original_verbose
    end

    def generate_key
      SecureRandom.base58(24)
    end

    test 'name' do
      assert_equal :uploadcare, @service.name
    end

    test 'uploading' do
      key = generate_key

      @service.upload(
        key,
        image_file,
        filename: ActiveStorage::Filename.new('avatar.png'), content_type: 'image/png'
      )
      assert_equal image_file.read.force_encoding(Encoding::BINARY), @service.download(key)
    ensure
      @service.delete key
    end

    test 'downloading a nonexistent file' do
      assert_raises(ActiveStorage::FileNotFoundError) do
        @service.download(SecureRandom.base58(24))
      end
    end

    test 'downloading in chunks' do
      key = generate_key
      @service.upload(
        key,
        image_file
      )

      chunks = []

      begin
        @service.download(key) do |chunk|
          chunks << chunk.force_encoding(Encoding::BINARY)
        end
        assert_equal chunks, [image_file.read.force_encoding(Encoding::BINARY)]
      ensure
        @service.delete key
      end
    end

    test 'downloading a nonexistent file in chunks' do
      assert_raises(ActiveStorage::FileNotFoundError) do
        @service.download(SecureRandom.base58(24)) {}
      end
    end

    test 'downloading partially' do
      key = generate_key
      @service.upload(
        key,
        image_file
      )
      original = image_file
      original.seek(5)
      original_bytes = original.read(10).bytes
      assert_equal original_bytes, @service.download_chunk(key, 5...15).bytes
    end

    test 'partially downloading a nonexistent file' do
      assert_raises(ActiveStorage::FileNotFoundError) do
        @service.download_chunk(SecureRandom.base58(24), 19..21)
      end
    end

    test 'deleting' do
      key = generate_key
      @service.upload(
        key,
        image_file
      )
      assert @service.exist?(key)
      @service.delete key
      assert_not @service.exist?(key)
    end

    test 'deleting nonexistent key' do
      assert_nothing_raised do
        @service.delete SecureRandom.base58(24)
      end
    end

    test 'deleting by prefix' do
      key = generate_key

      @service.upload("#{key}/a/a/a", image_file)
      @service.upload("#{key}/a/a/b", image_file)
      @service.upload("#{key}/a/b/a", image_file)

      @service.delete_prefixed("#{key}/a/a/")

      assert_not @service.exist?("#{key}/a/a/a")
      assert_not @service.exist?("#{key}/a/a/b")
      assert @service.exist?("#{key}/a/b/a")
    ensure
      @service.delete("#{key}/a/a/a")
      @service.delete("#{key}/a/a/b")
      @service.delete("#{key}/a/b/a")
    end

    test 'public URL generation' do
      key = generate_key
      @service.upload(
        key,
        image_file
      )
      url = @service.url(
        key,
        filename: ActiveStorage::Filename.new('avatar.png'),
        content_type: 'image/png'
      )
      uuid = ActiveStorage::Uploadcare::KeyUuid.find_by!(key: key).uuid
      assert_match /https:\/\/ucarecdn.com\/#{uuid}/, url
    end

    test 'signed URL generation' do
      private_service = ActiveStorage::Service.configure(
        :uploadcare,
        SERVICE_CONFIGURATIONS.deep_merge(uploadcare: { public: false, cname: "example.com", signing_secret: "secret" })
      )
      key = generate_key
      begin
        private_service.upload(key, image_file)
        uuid = ActiveStorage::Uploadcare::KeyUuid.find_by!(key: key).uuid
        url = private_service.url(key)
        assert_match /https:\/\/example.com\/#{uuid}\/\?token\=exp.*~acl=.*~hmac=.*/, url
      ensure
        private_service.delete(key)
      end
    end
  end
else
  puts 'Skipping Uploadcare Service tests because no Uploadcare configuration was supplied'
end
