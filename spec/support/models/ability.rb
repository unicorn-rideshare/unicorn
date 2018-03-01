def expect_to_be_able_to(action)
  it { should be_able_to(action, resource) }

  it "authorizes #{action} on the resource" do
    expect(resource.class.accessible_by(ability, action)).to include(resource)
  end
end

def expect_to_not_be_able_to(action)
  it { should_not be_able_to(action, resource) }

  it "does not authorize #{action} on the resource" do
    expect(resource.class.accessible_by(ability, action)).to_not include(resource)
  end
end

shared_examples 'ability' do |*actions|
  tested_actions = [:create, :read, :update, :destroy]

  subject(:ability) { Ability.new(ability_user) }

  actions.each do |action|
    if tested_actions.include?(action)
      expect_to_be_able_to(action)
    else
      expect_to_not_be_able_to(action)
    end
  end

  context 'another user' do
    let(:ability_user) { FactoryGirl.create(:user) }

    tested_actions.each do |action|
      expect_to_not_be_able_to(action)
    end
  end
end
