require 'grape-swagger'

module API
  class Root < Grape::API
    prefix "api"

    mount API::V1::Root
    add_swagger_documentation
  end
end