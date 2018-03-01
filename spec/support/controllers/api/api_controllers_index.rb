shared_examples 'api_controllers#index' do
  let(:collection)      { resource.class.accessible_by(Ability.new(user), :index) }
  let(:collection_name) { resource_name.to_s.pluralize.to_sym }

  describe 'GET index' do
    context 'user is signed in' do
      before do
        allow_any_instance_of(Ability).to receive(:resource) { resource.class }
        collection
        sign_in user
        get :index, (resource_params rescue {})
      end

      it 'assigns all resource collection' do
        expect(assigns(collection_name)).to eq(collection.to_a)
      end

      it { should respond_with(:ok) }
      it { should render_template('index') }

      context 'when the request includes :page and :rpp parameters' do
        let(:params)        { { page: 3, rpp: 10 } }
        let(:relation)      { "#{resource.class.name}::ActiveRecord_Relation".constantize }
        let(:relation_mock) { double(relation, to_hash: {}).as_null_object }
        
        it 'should calculate the total number of results based on the query for pagination' do
          expect_any_instance_of(relation).to receive(:count).at_least(:once)
          get :index, (resource_params.merge(params) rescue params)
        end

        it 'should set a limit of 10 on the collection query' do
          expect_any_instance_of(relation).to receive(:limit).with(10) { relation_mock }
          get :index, (resource_params.merge(params) rescue params)
        end

        it 'should set a offset of 20 on the collection query' do
          expect_any_instance_of(relation).to receive(:offset).with(20) { relation_mock }
          get :index, (resource_params.merge(params) rescue params)
        end
      end
    end
  end
end
