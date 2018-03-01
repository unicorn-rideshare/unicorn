object @token => nil

attributes :id,
           :token,
           :uuid

node(@token.authenticable_type.downcase) do |token|
  partial "#{@token.authenticable_type.downcase.pluralize}/show", object: token.authenticable
end
