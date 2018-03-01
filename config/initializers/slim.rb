Slim::Engine.set_options(pretty: true, sort_attrs: false) if Rails.env.development?
Slim::Engine.set_options attr_list_delims: { '[' => ']', '(' => ')' }, format: :html
