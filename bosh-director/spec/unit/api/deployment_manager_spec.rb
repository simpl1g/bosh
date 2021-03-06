require 'spec_helper'

describe Bosh::Director::Api::DeploymentManager do
  let(:deployment) { double('Deployment', name: 'DEPLOYMENT_NAME') }
  let(:task) { double('Task', id: 42) }
  let(:user) { 'FAKE_USER' }

  before do
    Resque.stub(:enqueue)
    BD::JobQueue.any_instance.stub(create_task: task)
  end

  describe '#create_deployment' do

    before do
      subject.stub(:write_file)
    end

    context 'when sufficient disk space is available' do
      before do
        subject.stub(check_available_disk_space: true)
      end

      it 'enqueues a resque job' do
        SecureRandom.stub(uuid: 'FAKE_UUID')
        Dir.stub(tmpdir: 'FAKE_TMPDIR')
        expected_manifest_path = File.join('FAKE_TMPDIR', 'deployment-FAKE_UUID')

        Resque.should_receive(:enqueue).with(BD::Jobs::UpdateDeployment, task.id, expected_manifest_path, {})

        subject.create_deployment(user, 'FAKE_DEPLOYMENT_MANIFEST')
      end

      it 'returns the task created by JobQueue' do
        expect(subject.create_deployment(user, 'FAKE_DEPLOYMENT_MANIFEST')).to eq(task)
      end
    end
  end

  describe '#delete_deployment' do
    it 'enqueues a resque job' do
      Resque.should_receive(:enqueue).with(BD::Jobs::DeleteDeployment, task.id, 'DEPLOYMENT_NAME', {})

      subject.delete_deployment(user, deployment)
    end

    it 'returns the task created by JobQueue' do
      expect(subject.delete_deployment(user, deployment)).to eq(task)
    end
  end

  describe '#find_by_name' do
    let(:deployment_lookup) { instance_double('Bosh::Director::Api::DeploymentLookup') }

    before do
      Bosh::Director::Api::DeploymentLookup.stub(new: deployment_lookup)
    end

    it 'delegates to DeploymentLookup' do
      deployment_lookup.should_receive(:by_name).with(deployment.name).and_return(deployment)
      expect(subject.find_by_name(deployment.name)).to eq deployment
    end
  end
end