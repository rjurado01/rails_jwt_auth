require 'rails_helper'

describe RailsJwtAuth::Lockable do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:each) { RailsJwtAuth.model_name = "#{orm}User" }
      let(:user) { FactoryBot.create("#{orm.underscore}_user") }
      let(:locked_user) {
        FactoryBot.create(
          "#{orm.underscore}_user",
          locked_at: 2.minutes.ago,
          failed_attempts: 3,
          first_failed_attempt_at: 3.minutes.ago,
          unlock_token: SecureRandom.base58(24)
        )
      }

      describe '#attributes' do
        it { expect(user).to have_attributes(failed_attempts: nil) }
        it { expect(user).to have_attributes(unlock_token: nil) }
        it { expect(user).to have_attributes(first_failed_attempt_at: nil) }
        it { expect(user).to have_attributes(locked_at: nil) }
      end

      describe '#lock_access!' do
        context 'when unlock strategy is by time' do
          before do
            RailsJwtAuth.unlock_strategy = :time
          end

          it 'locks the user' do
            user.lock_access!
            expect(user.locked_at).not_to be_nil
          end
        end

        %i[email both].each do |unlock_strategy|
          context "when unlock strategy is #{unlock_strategy}" do
            before do
              RailsJwtAuth.unlock_strategy = unlock_strategy
            end

            it 'locks the user' do
              user.lock_access!
              expect(user.locked_at).not_to be_nil
            end

            it 'sends unlock instructions' do
              expect { user.lock_access! }.to change { ActionMailer::Base.deliveries.count }.by(1)
            end
          end
        end
      end

      describe '#unlock_access!' do
        it 'unlocks the user' do
          locked_user.unlock_access!
          expect(locked_user.locked_at).to be_nil
          expect(locked_user.failed_attempts).to eq 0
          expect(locked_user.first_failed_attempt_at).to be_nil
          expect(locked_user.unlock_token).to be_nil
        end
      end

      describe '#reset_attempts!' do
        before do
          user.update(failed_attempts: 1, first_failed_attempt_at: 3.minutes.ago)
        end

        it 'resets attempts' do
          user.reset_attempts!
          expect(user.failed_attempts).to eq 0
          expect(user.first_failed_attempt_at).to be_nil
        end
      end

      describe '#authentication?' do
        context 'when user is not locked' do
          context 'when password is correct' do
            it 'returns true' do
              expect(user.authentication?('12345678')).to be_truthy
            end
          end

          context 'when password is invalid' do
            it 'returns false' do
              expect(user.authentication?('invalid')).to be_falsey
              expect(user.failed_attempts).to eq 1
            end
          end

          context 'when attempts are exceeded' do
            it 'locks access' do
              RailsJwtAuth.maximum_attempts.times do
                expect(user.authentication?('invalid')).to be_falsey
              end

              expect(user.failed_attempts).to eq RailsJwtAuth.maximum_attempts
              expect(user.authentication?('12345678')).to be_falsey
            end
          end

          context 'when attempts are reseted' do
            it 'does not lock access' do
              (RailsJwtAuth.maximum_attempts - 1).times do
                expect(user.authentication?('invalid')).to be_falsey
              end

              Timecop.travel(4.hours.from_now) do
                expect(user.authentication?('invalid')).to be_falsey
                expect(user.authentication?('12345678')).to be_truthy
              end
            end
          end
        end

        context 'when user is locked' do
          %i[time both].each do |unlock_strategy|
            context "when unlock_strategy is #{unlock_strategy}" do
              before do
                RailsJwtAuth.unlock_strategy = unlock_strategy
              end

              context 'when lock has expired' do
                it 'returns true' do
                  locked_user
                  Timecop.travel(4.hours.from_now) do
                    expect(locked_user.authentication?('12345678')).to be_truthy
                  end
                end
              end
            end
          end

          context 'when unlock strategy is by email' do
            before do
              RailsJwtAuth.unlock_strategy = :email
            end

            it 'lock does not expires' do
              locked_user
              Timecop.travel(4.hours.from_now) do
                expect(locked_user.authentication?('12345678')).to be_falsey
              end
            end
          end

          context 'when lock has not expired' do
            it 'returns false' do
              expect(locked_user.authentication?('12345678')).to be_falsey
            end
          end
        end
      end

      describe '#unauthenticated_error' do
        context 'when access is locked' do
          it 'returns locked error' do
            expect(locked_user.unauthenticated_error).to eq(error: :locked)
          end
        end

        context 'when access is not locked' do
          it 'returns invalid_session error and remaining_attempts' do
            user.authentication?('invalid')
            expect(user.unauthenticated_error).to eq(
              error: :invalid_session,
              remaining_attempts: RailsJwtAuth.maximum_attempts - 1
            )
          end
        end
      end
    end
  end
end
