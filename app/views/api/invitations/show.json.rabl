object @invitation => nil

attributes :id

node(:contact) do |invitation|
  partial 'contacts/show', object: invitation.invitable.contact
end if @invitation.invitable.contact

node(:user) do |invitation|
  {
    id: invitation.invitable.id,
    email: invitation.invitable.email,
    name: invitation.invitable.name
  }
end if @invitation.invitable_type.downcase.to_sym == :user
