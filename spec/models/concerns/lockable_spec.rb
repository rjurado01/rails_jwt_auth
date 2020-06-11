require 'rails_helper'

describe RailsJwtAuth::Lockable do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:each) { initialize_orm(orm) }

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

      describe '#lock_access' do
        context 'when unlock strategy is by time' do
          before do
            RailsJwtAuth.unlock_strategy = :time
          end

          it 'locks the user' do
            user.lock_access
            expect(user.locked_at).not_to be_nil
          end
        end

        %i[email both].each do |unlock_strategy|
          context "when unlock strategy is #{unlock_strategy}" do
            before do
              RailsJwtAuth.unlock_strategy = unlock_strategy
            end

            it 'locks the user' do
              user.lock_access
              expect(user.locked_at).not_to be_nil
            end

            it 'sends unlock instructions' do
              expect(RailsJwtAuth).to receive(:send_email).with(:unlock_instructions, user)
              user.lock_access
            end
          end
        end
      end

      describe '#access_locked?' do
        it 'returns if user is locked' do
          expect(user.access_locked?).to be_falsey
          user.lock_access
          expect(user.access_locked?).to be_truthy
        end
      end

      describe '#unlock_access' do
        it 'unlocks the user and reset attempts' do
          expect(locked_user.failed_attempts).to be > 0
          expect(locked_user.access_locked?).to be_truthy

          locked_user.unlock_access
          expect(locked_user.locked_at).to be_nil
          expect(locked_user.failed_attempts).to eq 0
          expect(locked_user.first_failed_attempt_at).to be_nil
          expect(locked_user.unlock_token).to be_nil
        end
      end

      describe '#failed_attempt' do
        context 'when is first time' do
          it 'increase failed attempts and set first_failed_attempt_at' do
            travel_to Time.now do
              user.failed_attempt
              expect(user.failed_attempts).to eq 1
              expect(user.first_failed_attempt_at).to eq(Time.current)
              expect(user.access_locked?).to be_falsey
            end
          end
        end

        context 'when is penultimate opportunity' do
          it 'increase failed attempts' do
            user.first_failed_attempt_at = Time.current
            user.failed_attempts = RailsJwtAuth.maximum_attempts - 2

            first_failed_attempt_at = user.first_failed_attempt_at

            travel_to Time.current + 5.seconds do
              user.failed_attempt
              expect(user.failed_attempts).to eq RailsJwtAuth.maximum_attempts - 1
              expect(user.first_failed_attempt_at).to eq(first_failed_attempt_at)
              expect(user.access_locked?).to be_falsey
            end
          end
        end

        context 'when is last oportunity' do
          it 'increase failed attempts and lock account' do
            user.first_failed_attempt_at = Time.current
            user.failed_attempts = RailsJwtAuth.maximum_attempts - 1

            travel_to Time.current + 5.seconds do
              user.failed_attempt
              expect(user.failed_attempts).to eq RailsJwtAuth.maximum_attempts
              expect(user.access_locked?).to be_truthy
            end
          end
        end

        context 'when attempts are expired' do
          it 'reset attempts' do
            travel_to Time.current - RailsJwtAuth.unlock_in - 5.seconds do
              user.failed_attempt
            end

            expect(user.failed_attempts).to eq 1
            user.failed_attempt
            expect(user.failed_attempts).to eq 1
          end
        end

        context 'whe user is locked' do
          it 'does nothing' do
            user.lock_access
            user.failed_attempt
            expect(user.failed_attempts).to eq nil
          end
        end
      end
    end
  end
end
