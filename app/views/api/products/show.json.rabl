object @product => nil

attributes :id,
           :gtin,
           :barcode_uri,
           :data,
           :product_id,
           :tier

node(:variants) do |product|
  partial 'products/index', object: product.variants.includes(:attachments)
end if (locals[:include_variants] || @include_variants)
