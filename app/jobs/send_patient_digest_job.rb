# frozen_string_literal: true

# SendPatientDigestJob: sends assessment reminder to patients
class SendPatientDigestJob < ApplicationJob
  queue_as :mailers

  def perform(*_args)
    # Loop over jurisdictions
    Jurisdiction.where(send_digest: true) do |jur|
      # Grab patients who reported symtomatic in the last hour
      patients = jur.all_patients.recently_symptomatic

      # Execute query, figure out how many meet requirements (if none skip email)
      next unless patients.size.positive?

      # Grab users who need an email
      users = User.where(jurisdiction_id: jur.id, role: %w[super_user public_health public_health_enroller])
      users.each do |user|
        # Send email to this user
        UserMailer.send_patient_digest_job_email(patients, user).deliver_later
      end
    end
  end
end
