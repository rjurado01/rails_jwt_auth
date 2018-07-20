require 'rails_helper'

describe RailsJwtAuth::Invitable do
  %w[ActiveRecord Mongoid].each do |orm|
    context "Using #{orm}" do
      before(:all) { RailsJwtAuth.model_name = "#{orm}User" }
      before(:each) { ActionMailer::Base.deliveries.clear }

      let(:invited_user) { "#{orm}User".constantize.invite! email: 'valid@example.com' }

      describe '#attributes' do
        subject { invited_user }
        it { is_expected.to have_attributes(invitation_token: invited_user.invitation_token) }
        it { is_expected.to have_attributes(invitation_accepted_at: nil) }
        it do
          is_expected.to have_attributes(invitation_created_at: invited_user.invitation_created_at)
        end

        it 'has a random password' do
          expect(subject).to_not have_attributes(password_digest: nil)
        end
      end

      describe '.invite!' do # Class method
        context 'when auth field config is invalid' do
          it 'throws InvalidAuthField an exception' do
            allow(RailsJwtAuth).to receive(:auth_field_name).and_return(:invalid)

            expect {
              RailsJwtAuth.model.invite! email: 'user@example.com'
            }.to raise_error(RailsJwtAuth::InvalidAuthField)
          end
        end

        context 'without existing user' do
          subject { RailsJwtAuth.model.invite! email: 'another@example.com' }

          it 'creates a record' do
            expect { subject }.to change { "#{orm}User".constantize.count }.by 1
          end

          it 'sends the invitation mail' do
            subject
            expect(ActionMailer::Base.deliveries.count).to eq(1)
          end

          context 'with more fields than only email' do
            subject do
              RailsJwtAuth.model.invite!(email: 'valid@example.com', username: 'TestName')
            end

            it 'has extra attributes assigned' do
              expect(subject.username).to eq('TestName')
            end
          end
        end

        context 'without auth_field' do
          it 'raises exception' do
            expect { "#{orm}User".constantize.invite! }.to raise_error(ArgumentError)
          end
        end

        context 'with existing user' do
          context 'with pending invitation' do
            let(:user) { "#{orm}User".constantize.invite! email: 'valid@example.com' }

            before do
              "#{orm}User".constantize.invite! email: 'valid@example.com'
              ActionMailer::Base.deliveries.clear
            end

            it 'doesn\'t change the users password' do
              expect(user.password_digest).to eq(user.reload.password_digest)
            end

            it 'resets invitation_sent_at' do
              Timecop.freeze(Time.current)
              user = "#{orm}User".constantize.invite! email: 'test@example.com'

              Timecop.freeze(Time.current + 30.days) do
                "#{orm}User".constantize.invite! email: user.email
                expect(user.reload.invitation_sent_at.to_datetime.to_i)
                  .to eq(Time.current.to_datetime.to_i)
              end

              expect(user.reload.invitation_sent_at.to_datetime.to_i)
                .to_not eq(Time.current.to_datetime.to_i)
              expect(user.reload.invitation_sent_at.to_datetime.to_i)
                .to eq((Time.current.to_datetime + 30.days).to_datetime.to_i)
              Timecop.return
            end

            it 'sends the invitation mail' do
              "#{orm}User".constantize.invite! email: 'test@example.com'
              expect(ActionMailer::Base.deliveries.count).to eq(1)
            end
          end

          context 'when completely registered' do
            let(:user) { FactoryBot.create "#{orm.underscore}_user", email: 'valid@example.com' }

            subject { "#{orm}User".constantize.invite! email: user.email }

            it 'has taken error on auth_field_name' do
              field = RailsJwtAuth.auth_field_name.to_sym
              expect(subject.errors).to_not be_empty
              error = subject.errors.details[field].first.values.first
              expect(error).to eq(:taken)
            end
          end

          context 'when invitation already accepted' do
            let(:email) { 'valid@example.com' }

            before do
              # invite and accept
              user = "#{orm}User".constantize.invite! email: email
              user.accept_invitation!
              user.save
            end

            it 'has taken error on auth_field_name' do
              field = RailsJwtAuth.auth_field_name.to_sym
              user2 = "#{orm}User".constantize.invite! email: email
              expect(user2.errors).to_not be_empty
              error = user2.errors.details[field].first.values.first
              expect(error).to eq(:taken)
            end
          end
        end
      end

      describe '#accept_invitation!' do
        context 'with invited user' do
          before do
            Timecop.freeze
            invited_user.accept_invitation!
          end

          after do
            Timecop.return
          end

          it 'clears invitation_token' do
            expect(invited_user.invitation_token).to be_nil
          end

          it 'sets invitation_accepted_at' do
            expect(invited_user.invitation_accepted_at).to eq(Time.current)
          end
        end

        context 'with non-invited user' do
          let(:user) { FactoryBot.create "#{orm.underscore}_user" }
          before do
            user.accept_invitation!
          end

          it 'doesn\'t set invitation_accepted_at' do
            expect(user.reload.invitation_accepted_at).to be_nil
          end
        end

        context 'with already confirmed user' do
          before do
            @invited_user = "#{orm}User".constantize.invite! email: 'valid@example.com'
            @invited_user.confirm!
            @invited_user.accept_invitation!
            @invited_user.save
          end

          it 'doesn\'t include already_confirmed in errors' do
            expect(@invited_user.errors).to be_empty
          end
        end
      end

      describe '#invite!' do
        let(:user) { FactoryBot.build "#{orm.underscore}_user" }

        context 'when email field config is invalid' do
          it 'throws InvalidEmailField exception' do
            allow(RailsJwtAuth).to receive(:email_field_name).and_return(:invalid)
            expect { user.invite! }.to raise_error(RailsJwtAuth::InvalidEmailField)
          end
        end

        context 'without invitation token' do
          it 'generates invitation_token' do
            user.invite!
            expect(user.invitation_token).to_not be_nil
          end
        end

        context 'with token' do
          before do
            user.invitation_token = 'abcde'
            user.invite!
          end

          it 'doesn\'t change actual token' do
            expect(user.invitation_token).to eq('abcde')
          end
        end

        it 'delivers invitation' do
          expect(user).to receive(:send_invitation_mail)
          user.invite!
        end
      end
    end
  end
end
