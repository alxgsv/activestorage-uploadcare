

# ActiveStorage::Uploadcare

## Installation and usage

1. Install ActiveStorage
```bash
rails active_storage:install
rails db:migrate
```

2. Add this line to your application's Gemfile:
```ruby
gem 'activestorage-uploadcare', git: 'https://github.com/uploadcare/activestorage-uploadcare.git'
```

3. And then execute these commands to install the gem and create the migration:
```bash
bundle
rails generate migration CreateActiveStorageKeysUploadcareUuids key:string:uniq:index uuid:string:uniq:index
rails db:migrate
```

4. Configure your Uploadcare project in `config/storage.yml`:
```yaml

uploadcare_public_project:
  service: uploadcare
  public_key: <%= ENV['UPLOADCARE_PUBLIC_KEY'] %>
  secret_key: <%= ENV['UPLOADCARE_SECRET_KEY'] %>
  public: true

uploadcare_private_project:
  public: false
  cname: example.com
  signing_secret: YOUR_SIGNING_SECRET
```

5. Set the service in `config/environments/<environment>.rb`:
```ruby
config.active_storage.service = :uploadcare_public
```

6. Now you can use ActiveStorage as usual:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar
end

user = User.create
user.avatar.attach(io: File.open('/path/to/file')
puts user.avatar.url
# will print something like:
# https://ucarecdn.com/0e8b1b1e-5b3e-4e4e-9b1b-1e5b3e4e4e9b/
```

## Limitations and specifics
1. ActiveStorage::Uploadcare doesn't support direct uploads. You need to upload files via your server.
2. ActiveStorage has file variants feature. But Uploadcare has its own image transformations. For example, images are transformed on the fly, and automatically cached on the CDN. You don't need to worry about storing and processing variants. So, with ActiveStorage::Uploadcare service variant become redundant.

## Testing
```bash
bundle
cp test/configurations.example.yml test/configurations.yml
UPLOADCARE_PUBLIC_KEY=YOUR_PK UPLOADCARE_SECRET_KEY=YOUR_SK bin/test
```
