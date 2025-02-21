# frozen_string_literal: true

# PatientMailer: mailers for monitorees
class PatientMailer < ApplicationMailer
  default from: 'notifications@saraalert.org'

  def enrollment_email(patient)
    # Should not be sending enrollment email if no valid email
    return if patient&.email.blank?

    # Gather patients and jurisdictions
    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    @patients = patient.active_dependents.uniq.collect do |dependent|
      { patient: dependent, jurisdiction_unique_id: Jurisdiction.find_by_id(dependent.jurisdiction_id).unique_identifier }
    end
    @lang = patient.select_language
    mail(to: patient.email&.strip, subject: I18n.t('assessments.email.enrollment.subject', locale: @lang)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    History.welcome_message_sent(patient: patient)
  end

  def enrollment_sms_weblink(patient)
    enrollment_sms_text_based(patient)
  end

  def enrollment_sms_text_based(patient)
    # Should not be sending enrollment sms if no valid number
    return if patient&.primary_telephone.blank?

    if patient.blocked_sms
      add_fail_history_sms_blocked(patient)
      return
    end

    lang = patient.select_language
    contents = "#{I18n.t('assessments.sms.prompt.intro1', locale: lang)} #{patient&.initials_age('-')} #{I18n.t('assessments.sms.prompt.intro2', locale: lang)}"

    success = TwilioSender.send_sms(patient, contents)
    add_success_history(patient, patient) if success
    add_fail_history_sms(patient) unless success

    # Always update the last contact time so the system does not try and send sms again.
    patient.update(last_assessment_reminder_sent: DateTime.now)
  end

  # Right now the wording of this message is the same as for enrollment
  def assessment_sms_weblink(patient)
    if patient&.primary_telephone.blank?
      add_fail_history_blank_field(patient, 'primary phone number')
      return
    end
    if patient.blocked_sms
      add_fail_history_sms_blocked(patient)
      return
    end

    # Cover potential race condition where multiple messages are sent for the same monitoree.
    return unless patient.last_assessment_reminder_sent_eligible?

    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    patient.active_dependents.uniq.each do |dependent|
      lang = dependent.select_language
      url = new_patient_assessment_jurisdiction_lang_initials_url(dependent.submission_token,
                                                                  dependent.jurisdiction.unique_identifier,
                                                                  lang&.to_s || 'en',
                                                                  dependent&.initials_age)
      contents = "#{I18n.t('assessments.sms.weblink.intro', locale: lang)} #{dependent&.initials_age('-')}: #{url}"

      patient.update(last_assessment_reminder_sent: DateTime.now) # Update last send attempt timestamp before Twilio call
      if TwilioSender.send_sms(patient, contents)
        add_success_history(dependent, patient)
      else
        add_fail_history_sms(dependent)
        patient.update(last_assessment_reminder_sent: nil) # Reset send attempt timestamp on failure
      end
    end
  end

  def assessment_sms(patient)
    if patient&.primary_telephone.blank?
      add_fail_history_blank_field(patient, 'primary phone number')
      return
    end
    if patient.blocked_sms
      add_fail_history_sms_blocked(patient)
      return
    end

    # Cover potential race condition where multiple messages are sent for the same monitoree.
    return unless patient.last_assessment_reminder_sent_eligible?

    lang = patient.select_language
    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    patient_names = patient.active_dependents.uniq.collect { |dependent| dependent&.initials_age('-') }
    contents = I18n.t('assessments.sms.prompt.daily1', locale: lang) + patient_names.join(', ') + '.'

    # Prepare text asking about anyone in the group
    contents += if patient.active_dependents.uniq.count > 1
                  I18n.t('assessments.sms.prompt.daily2-p', locale: lang)
                else
                  I18n.t('assessments.sms.prompt.daily2-s', locale: lang)
                end

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    contents += I18n.t('assessments.sms.prompt.daily3', locale: lang) + patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang) + '.'
    contents += I18n.t('assessments.sms.prompt.daily4', locale: lang)
    threshold_hash = patient.jurisdiction.jurisdiction_path_threshold_hash
    # The medium parameter will either be SMS or VOICE
    params = { prompt: contents, patient_submission_token: patient.submission_token,
               threshold_hash: threshold_hash, medium: 'SMS', language: lang.to_s.split('-').first.upcase,
               try_again: I18n.t('assessments.sms.prompt.try-again', locale: lang),
               max_retries_message: I18n.t('assessments.sms.prompt.max_retries_message', locale: lang),
               thanks: I18n.t('assessments.sms.prompt.thanks', locale: lang) }

    patient.update(last_assessment_reminder_sent: DateTime.now) # Update last send attempt timestamp before Twilio call
    if TwilioSender.start_studio_flow(patient, params)
      add_success_history(patient, patient)
    else
      add_fail_history_sms(patient)
      patient.update(last_assessment_reminder_sent: nil) # Reset send attempt timestamp on failure
    end
  end

  def assessment_voice(patient)
    if patient&.primary_telephone.blank?
      add_fail_history_blank_field(patient, 'primary phone number')
      return
    end

    # Cover potential race condition where multiple messages are sent for the same monitoree.
    return unless patient.last_assessment_reminder_sent_eligible?

    lang = patient.select_language
    lang = :en if %i[so].include?(lang) # Some languages are not supported via voice
    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    patient_names = patient.active_dependents.uniq.collect do |dependent|
      "#{dependent&.first_name&.first || ''}, #{dependent&.last_name&.first || ''}, "\
        "#{I18n.t('assessments.phone.age', locale: lang)} #{dependent&.calc_current_age || '0'},"
    end
    contents = I18n.t('assessments.phone.daily1', locale: lang) + patient_names.join(', ')

    # Prepare text asking about anyone in the group
    contents += if patient.active_dependents.uniq.count > 1
                  I18n.t('assessments.phone.daily2-p', locale: lang)
                else
                  I18n.t('assessments.phone.daily2-s', locale: lang)
                end

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    contents += I18n.t('assessments.phone.daily3', locale: lang) + patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang) + '?'
    contents += I18n.t('assessments.phone.daily4', locale: lang)

    threshold_hash = patient.jurisdiction.jurisdiction_path_threshold_hash
    # The medium parameter will either be SMS or VOICE
    params = { prompt: contents, patient_submission_token: patient.submission_token,
               threshold_hash: threshold_hash, medium: 'VOICE', language: lang.to_s.split('-').first.upcase,
               intro: I18n.t('assessments.phone.intro', locale: lang),
               try_again: I18n.t('assessments.phone.try-again', locale: lang),
               max_retries_message: I18n.t('assessments.phone.max_retries_message', locale: lang),
               thanks: I18n.t('assessments.phone.thanks', locale: lang) }

    patient.update(last_assessment_reminder_sent: DateTime.now) # Update last send attempt timestamp before Twilio call
    if TwilioSender.start_studio_flow(patient, params)
      add_success_history(patient, patient)
    else
      add_fail_history_voice(patient)
      patient.update(last_assessment_reminder_sent: nil) # Reset send attempt timestamp on failure
    end
  end

  def assessment_email(patient)
    if patient&.email.blank?
      add_fail_history_blank_field(patient, 'email')
      return
    end

    # Cover potential race condition where multiple messages are sent for the same monitoree.
    return unless patient.last_assessment_reminder_sent_eligible?

    @lang = patient.select_language
    # Gather patients and jurisdictions
    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    @patients = patient.active_dependents.uniq.collect do |dependent|
      { patient: dependent, jurisdiction_unique_id: Jurisdiction.find_by_id(dependent.jurisdiction_id).unique_identifier }
    end

    patient.update(last_assessment_reminder_sent: DateTime.now) # Update last send attempt timestamp before SMTP call
    mail(to: patient.email&.strip, subject: I18n.t('assessments.email.reminder.subject', locale: @lang || :en)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    add_success_history(patient, patient)
  rescue StandardError => e
    patient.update(last_assessment_reminder_sent: nil) # Reset send attempt timestamp on failure
    raise "Failed to send email for patient id: #{patient.id}; #{e.message}"
  end

  def closed_email(patient)
    return if patient&.email.blank?

    @patient = patient
    @lang = patient.select_language
    mail(to: patient.email&.strip, subject: I18n.t('assessments.email.closed.subject', locale: @lang || :en)) do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  private

  def add_success_history(patient, parent)
    comment = if patient == parent
                "Sara Alert sent a report reminder to this monitoree via #{parent.preferred_contact_method}."
              else
                "Sara Alert sent a report reminder to this monitoree's HoH via #{parent.preferred_contact_method}."
              end
    History.report_reminder(patient: patient, comment: comment)
  end

  def add_fail_history_sms(patient)
    comment = "Sara Alert attempted to send an SMS to #{patient.primary_telephone}, but the message could not be delivered."
    History.report_reminder(patient: patient, comment: comment)
  end

  def add_fail_history_voice(patient)
    comment = "Sara Alert attempted to call monitoree at #{patient.primary_telephone}, but the call could not be completed."
    History.report_reminder(patient: patient, comment: comment)
  end

  def add_fail_history_blank_field(patient, type)
    History.report_reminder(patient: patient,
                            comment: "Sara Alert could not send a report reminder to this monitoree via \
                                     #{patient.preferred_contact_method}, because the monitoree #{type} was blank.")
  end

  def add_fail_history_sms_blocked(patient)
    comment = "The system was unable to send an SMS to this monitoree #{patient.primary_telephone}, because monitoree blocked Sara Alert."
    History.contact_attempt(patient: patient, comment: comment)
    return if patient.dependents_exclude_self.blank?

    create_contact_attempt_history_for_dependents(patient.dependents_exclude_self, "The system was unable to send an SMS to this monitoree's
       HoH #{patient.primary_telephone}, because the monitoree's head of household blocked Sara Alert.")
  end

  # Use the import method here to generate less SQL statements for a bulk insert of
  # dependent histories instead of 1 statement per dependent.
  def create_contact_attempt_history_for_dependents(dependents, comment)
    histories = []
    dependents.each do |dependent|
      histories << History.new(patient: dependent,
                               created_by: 'Sara Alert System',
                               comment: comment,
                               history_type: 'Contact Attempt')
    end
    History.import! histories
  end
end
