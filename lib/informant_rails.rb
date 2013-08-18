require 'informant_rails/railtie'

module InformantRails
  autoload :Config,     'informant_rails/config'
  autoload :Client,     'informant_rails/client'
  autoload :Middleware, 'informant_rails/middleware'
  autoload :Model,      'informant_rails/model'
  autoload :Request,    'informant_rails/request'
end
