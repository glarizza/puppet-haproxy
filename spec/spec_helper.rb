require 'rspec-puppet'

RSpec.configure do |c|
    c.manifest_dir = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures', 'manifests')
    c.config       = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures', 'puppet.conf')
end
