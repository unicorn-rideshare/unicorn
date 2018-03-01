shared_examples 'versionable' do
  it { should respond_to(:versions) }

  it 'should have a paper_trail version class' do
    expect(subject.version_class_name.constantize).to eq(PaperTrail::Version)
  end
end
