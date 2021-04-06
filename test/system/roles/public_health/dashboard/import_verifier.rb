# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../../../lib/system_test_utils'

class PublicHealthMonitoringImportVerifier < ApplicationSystemTestCase
  include ImportExport
  @@system_test_utils = SystemTestUtils.new(nil)

  TELEPHONE_FIELDS = %i[primary_telephone secondary_telephone].freeze
  BOOL_FIELDS = %i[white black_or_african_american american_indian_or_alaska_native asian native_hawaiian_or_other_pacific_islander race_other race_unknown
                   race_refused_to_answer interpretation_required contact_of_known_case travel_to_affected_country_or_area
                   was_in_health_care_facility_with_known_cases laboratory_personnel healthcare_personnel crew_on_passenger_or_cargo_flight
                   member_of_a_common_exposure_cohort].freeze
  STATE_FIELDS = %i[address_state foreign_monitored_address_state additional_planned_travel_destination_state].freeze
  MONITORED_ADDRESS_FIELDS = %i[monitored_address_line_1 monitored_address_city monitored_address_state monitored_address_line_2 monitored_address_zip].freeze
  # TODO: when workflow specific case status validation re-enabled: take out 'case_status'
  ISOLATION_FIELDS = %i[symptom_onset extended_isolation case_status].freeze
  ENUM_FIELDS = %i[ethnicity preferred_contact_method primary_telephone_type secondary_telephone_type preferred_contact_time additional_planned_travel_type
                   exposure_risk_assessment monitoring_plan case_status].freeze
  RISK_FACTOR_FIELDS = %i[contact_of_known_case was_in_health_care_facility_with_known_cases].freeze
  # TODO: when workflow specific case status validation re-enabled: uncomment
  # WORKFLOW_SPECIFIC_FIELDS = %i[case_status].freeze
  NON_IMPORTED_PATIENT_FIELDS = %i[full_status lab_1_type lab_1_specimen_collection lab_1_report lab_1_result lab_2_type lab_2_specimen_collection lab_2_report
                                   lab_2_result].freeze

  def verify_epi_x_field_validation(jurisdiction, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      row.each_with_index do |value, index|
        verify_validation(jurisdiction, workflow, EPI_X_FIELDS[index], RISK_FACTOR_FIELDS.include?(EPI_X_FIELDS[index]) ? !value.blank? : value)
      end
    end
  end

  def verify_sara_alert_format_field_validation(jurisdiction, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      row.each_with_index do |value, index|
        verify_validation(jurisdiction, workflow, SARA_ALERT_FORMAT_FIELDS[index], value)
      end
    end
  end

  def verify_epi_x_import_page(jurisdiction, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    find('.modal-body').all('div.card-body').each_with_index do |card, index|
      row = sheet.row(index + 2)
      verify_existence(card, 'CDC ID', epi_x_val(row, :user_defined_id_cdc), index)
      verify_existence(card, 'First Name', epi_x_val(row, :first_name), index)
      verify_existence(card, 'Last Name', epi_x_val(row, :last_name), index)
      verify_existence(card, 'DOB', epi_x_val(row, :date_of_birth), index)
      verify_existence(card, 'Flight or Vessel Number', epi_x_val(row, :flight_or_vessel_number), index)
      verify_existence(card, 'Home Address Line 1', epi_x_val(row, :address_line_1), index)
      verify_existence(card, 'Home Town/City', epi_x_val(row, :address_city), index)
      verify_existence(card, 'Home State', normalize_state_field(epi_x_val(row, :address_state)), index)
      verify_existence(card, 'Home Zip', epi_x_val(row, :address_zip), index)
      # verify_existence(card, 'Monitored Address Line 1', row[20], index)
      # verify_existence(card, 'Monitored Town/City', row[21], index)
      # verify_existence(card, 'Monitored State', normalize_state_field(row[22]), index)
      # verify_existence(card, 'Monitored Zip', row[23], index)
      verify_existence(card, 'Phone Number 1', Phonelib.parse(epi_x_val(row, :primary_telephone), 'US').full_e164, index)
      verify_existence(card, 'Phone Number 2', Phonelib.parse(epi_x_val(row, :secondary_telephone), 'US').full_e164, index)
      verify_existence(card, 'Email', epi_x_val(row, :email), index)
      verify_existence(card, 'Date of Departure', epi_x_val(row, :date_of_departure), index)
      if jurisdiction.all_patients_excluding_purged.where(first_name: epi_x_val(row, :first_name), last_name: epi_x_val(row, :last_name)).length > 1
        assert card.has_content?("Warning: This #{workflow == :exposure ? 'monitoree' : 'case'} already appears to exist in the system!")
      end
    end
  end

  def verify_sara_alert_format_import_page(jurisdiction, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    find('.modal-body').all('div.card-body').each_with_index do |card, index|
      row = sheet.row(index + 2)
      verify_existence(card, 'State/Local ID', saf_val(row, :user_defined_id_statelocal), index)
      verify_existence(card, 'CDC ID', saf_val(row, :user_defined_id_cdc), index)
      verify_existence(card, 'First Name', saf_val(row, :first_name), index)
      verify_existence(card, 'Last Name', saf_val(row, :last_name), index)
      verify_existence(card, 'DOB', saf_val(row, :date_of_birth), index)
      verify_existence(card, 'Language', saf_val(row, :primary_language), index)
      verify_existence(card, 'Flight or Vessel Number', saf_val(row, :flight_or_vessel_number), index)
      verify_existence(card, 'Home Address Line 1', saf_val(row, :address_line_1), index)
      verify_existence(card, 'Home Town/City', saf_val(row, :address_city), index)
      verify_existence(card, 'Home State', normalize_state_field(saf_val(row, :address_state)), index)
      verify_existence(card, 'Home Zip', saf_val(row, :address_zip), index)
      verify_existence(card, 'Monitored Address Line 1', saf_val(row, :monitored_address_line_1), index)
      verify_existence(card, 'Monitored Town/City', saf_val(row, :monitored_address_city), index)
      verify_existence(card, 'Monitored State', normalize_state_field(saf_val(row, :monitored_address_state)), index)
      verify_existence(card, 'Monitored Zip', saf_val(row, :monitored_address_zip), index)
      verify_existence(card, 'Phone Number 1', Phonelib.parse(saf_val(row, :primary_telephone), 'US').full_e164, index)
      verify_existence(card, 'Phone Number 2', Phonelib.parse(saf_val(row, :secondary_telephone), 'US').full_e164, index)
      verify_existence(card, 'Email', saf_val(row, :email), index)
      verify_existence(card, 'Exposure Location', saf_val(row, :potential_exposure_location), index)
      verify_existence(card, 'Date of Departure', saf_val(row, :date_of_departure), index)
      verify_existence(card, 'Close Contact w/ Known Case', saf_val(row, :contact_of_known_case)&.to_s&.downcase, index)
      verify_existence(card, 'Was in HC Fac. w/ Known Cases', saf_val(row, :was_in_health_care_facility_with_known_cases)&.to_s&.downcase, index)
      if jurisdiction.all_patients_excluding_purged
                     .where(first_name: saf_val(row, :first_name), middle_name: saf_val(row, :middle_name), last_name: :last_name).length > 1
        assert card.has_content?("Warning: This #{workflow == :exposure ? 'monitoree' : 'case'} already appears to exist in the system!")
      end
      if saf_val(row, :jurisdiction_path)
        assert card.has_content?("This #{workflow == :exposure ? 'monitoree' : 'case'} will be imported into '#{saf_val(row, :jurisdiction_path)}'")
      end
      if saf_val(row, :assigned_user)
        assert card.has_content?("This #{workflow == :exposure ? 'monitoree' : 'case'} will be assigned to user '#{saf_val(row, :assigned_user)}'")
      end
    end
  end

  def verify_epi_x_import_data(jurisdiction, workflow, file_name, rejects, accept_duplicates)
    sheet = get_xlsx(file_name).sheet(0)
    sleep(2) # wait for db write
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      patients = jurisdiction.all_patients_excluding_purged.where(first_name: epi_x_val(row, :first_name))
                             .where(last_name: epi_x_val(row, :last_name)).where(date_of_birth: epi_x_val(row, :date_of_birth))
      patient = patients.where('created_at > ?', 1.minute.ago)[0]
      duplicate = patients.where('created_at < ?', 1.minute.ago).exists?
      if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)
        assert_nil(patient, "Patient should not be found in db: #{epi_x_val(row, :first_name)} #{epi_x_val(row, :last_name)} in row #{row_num}")
      else
        assert_not_nil(patient, "Patient not found in db: #{epi_x_val(row, :first_name)} #{epi_x_val(row, :last_name)} in row #{row_num}")
        EPI_X_FIELDS.each_with_index do |field, index|
          if TELEPHONE_FIELDS.include?(field)
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :sex && !row[index].blank?
            assert_equal(SEX_ABBREVIATIONS[row[index].to_sym], patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :address_state || (field == :monitored_address_state && !row[index].nil?)
            assert_equal(normalize_state_field(row[index].to_s), patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :monitored_address_state && row[index].nil? # copy over monitored address state if state is nil
            assert_equal(normalize_state_field(row[index - 4].to_s), patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif MONITORED_ADDRESS_FIELDS.include?(field) && row[index].nil? # copy over address fields if address is nil
            assert_equal(row[index - 4].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif !field.nil?
            assert_equal(row[index].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          end
        end
        assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_num}")
      end
    end
  end

  def verify_sara_alert_format_import_data(jurisdiction, workflow, file_name, rejects, accept_duplicates)
    sheet = get_xlsx(file_name).sheet(0)
    sleep(2) # wait for db write
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      patients = jurisdiction.all_patients_excluding_purged.where(first_name: saf_val(row, :first_name)).where(middle_name: saf_val(row, :middle_name))
                             .where(last_name: saf_val(row, :last_name), date_of_birth: saf_val(row, :date_of_birth))
      patient = patients.where('created_at > ?', 1.minute.ago)[0]
      duplicate = patients.where('created_at < ?', 1.minute.ago).exists?
      if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)
        assert_nil(patient, "Patient should not be found in db: #{saf_val(row, :first_name)} #{saf_val(row, :middle_name)} #{saf_val(row, :last_name)}"\
                            " in row #{row_num}")
      else
        assert_not_nil(patient, "Patient not found in db: #{saf_val(row, :first_name)} #{saf_val(row, :middle_name)} #{saf_val(row, :last_name)}"\
                                " in row #{row_num}")
        SARA_ALERT_FORMAT_FIELDS.each_with_index do |field, index|
          if TELEPHONE_FIELDS.include?(field)
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif BOOL_FIELDS.include?(field)
            assert_equal(normalize_bool_field(row[index]).to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif STATE_FIELDS.include?(field) || (field == :monitored_address_state && !row[index].nil?)
            assert_equal(normalize_state_field(row[index].to_s).to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :monitored_address_state && row[index].nil? # copy over monitored address state if state is nil
            assert_equal(normalize_state_field(row[index - 13].to_s), patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif MONITORED_ADDRESS_FIELDS.include?(field) & row[index].nil? # copy over address fields if address is nil
            assert_equal(row[index - 13].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :symptom_onset # isolation workflow specific field
            assert_equal(workflow == :isolation ? row[index].to_s : '', patient[field].to_s, "#{field} mismatch in row #{row_num}")
          # TODO: when workflow specific case status validation re-enabled: remove the next 3 lines
          elsif field == :case_status # isolation workflow specific enum field
            normalized_cell_value = NORMALIZED_ENUMS[field][normalize_enum_field_value(row[index])].to_s
            assert_equal(workflow == :isolation ? normalized_cell_value : '', patient[field].to_s, "#{field} mismatch in row #{row_num}")
          # TODO: when workflow specific case status validation re-enabled: uncomment
          # elsif field == :case_status
          #   normalized_cell_value = if workflow == :isolation
          #                             NORMALIZED_ISOLATION_ENUMS[field][normalize_enum_field_value(row[index])].to_s
          #                           else
          #                             NORMALIZED_EXPOSURE_ENUMS[field][normalize_enum_field_value(row[index])].to_s
          #                           end
          #   assert_equal(normalized_cell_value, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :jurisdiction_path
            assert_equal(row[index] ? row[index].to_s : jurisdiction[:path].to_s, patient.jurisdiction[:path].to_s, "#{field} mismatch in row #{row_num}")
          elsif ENUM_FIELDS.include?(field)
            assert_equal(NORMALIZED_ENUMS[field][normalize_enum_field_value(row[index])].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif !NON_IMPORTED_PATIENT_FIELDS.include?(field)
            assert_equal(row[index].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          end
        end
        verify_laboratory(patient, row[87..90])
        verify_laboratory(patient, row[91..94])
        assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_num}")
      end
    end
  end

  def verify_validation(jurisdiction, workflow, field, value)
    return if workflow != :isolation && ISOLATION_FIELDS.include?(field)

    if VALIDATION[field]
      checks = VALIDATION[field][:checks]
      # TODO: Un-comment when required fields are to be checked upon import
      # if checks.include?(:required) && (!value || value.blank?)
      #   assert page.has_content?("Required field '#{VALIDATION[field][:label]}' is missing"), "Error message for #{field}"
      # end
      if value && !value.blank? && checks.include?(:enum) && !NORMALIZED_ENUMS[field].keys.include?(normalize_enum_field_value(value))
        assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not an acceptable value"), "Error message for #{field} missing"
      end
      # TODO: when workflow specific case status validation re-enabled: uncomment
      # if value && !value.blank? && WORKFLOW_SPECIFIC_FIELDS.include?(field)
      #   if workflow == :exposure && !NORMALIZED_EXPOSURE_ENUMS[field].keys.include?(normalize_enum_field_value(value))
      #     assert page.has_content?('for monitorees imported into the Exposure workflow'), "Error message for #{field} incorrect"
      #   elsif workflow == :isolation && !NORMALIZED_ISOLATION_ENUMS[field].keys.include?(normalize_enum_field_value(value))
      #     assert page.has_content?('for cases imported into the Isolation workflow'), "Error message for #{field} incorrect"
      #   end
      # end
      if value && !value.blank? && checks.include?(:bool) && !%w[true false].include?(value.to_s.downcase)
        assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not an acceptable value"), "Error message for #{field} missing"
      end
      if value && !value.blank? && checks.include?(:date) && !value.instance_of?(Date) && value.match(/\d{4}-\d{2}-\d{2}/)
        begin
          Date.parse(value)
        rescue ArgumentError
          assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not a valid date"), "Error message for #{field} missing"
        end
      end
      if value && !value.blank? && checks.include?(:date) && !value.instance_of?(Date) && !value.match(/\d{4}-\d{2}-\d{2}/)
        generic_msg = "Value '#{value}' for '#{VALIDATION[field][:label]}' is not a valid date"
        if value.match(%r{\d{2}/\d{2}/\d{4}})
          specific_msg = "#{generic_msg} due to ambiguity between 'MM/DD/YYYY' and 'DD/MM/YYYY', please use the 'YYYY-MM-DD' format instead"
          assert page.has_content?(specific_msg), "Error message for #{field} missing"
        else
          assert page.has_content?("#{generic_msg}, please use the 'YYYY-MM-DD' format"), "Error message for #{field} missing"
        end
      end
      if value && !value.blank? && checks.include?(:phone) && Phonelib.parse(value, 'US').full_e164.nil?
        assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not a valid phone number"), "Error message for #{field} missing"
      end
      if value && !value.blank? && checks.include?(:state) && !VALID_STATES.include?(value) && STATE_ABBREVIATIONS[value.to_s.upcase.to_sym].nil?
        assert page.has_content?("'#{value}' is not a valid state for '#{VALIDATION[field][:label]}'"), "Error message for #{field} missing"
      end
      if value && !value.blank? && checks.include?(:sex) && !%(Male Female Unknown M F).include?(value.to_s.capitalize)
        assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not an acceptable value"),
               "Error message for #{field} missing"
      end
      if value && !value.blank? && checks.include?(:email) && !ValidEmail2::Address.new(value).valid?
        assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not a valid Email Address"), "Error message for #{field} missing"
      end
    elsif field == :jurisdiction_path
      return unless value && !value.blank?

      jurisdiction = Jurisdiction.where(path: value).first
      if jurisdiction.nil?
        if Jurisdiction.where(name: value).empty?
          assert page.has_content?("'#{value}' is not valid for 'Full Assigned Jurisdiction Path'"), "Error message for #{field} missing"
        else
          msg = "'#{value}' is not valid for 'Full Assigned Jurisdiction Path', please provide the full path instead of just the name"
          assert page.has_content?(msg), "Error message for #{field} missing"
        end
      else
        unless jurisdiction.subtree_ids.include?(jurisdiction[:id])
          msg = "'#{value}' is not valid for 'Full Assigned Jurisdiction Path' because you do not have permission to import into it"
          assert page.has_content?(msg), "Error message for #{field} missing"
        end
      end
    elsif field == :assigned_user
      return unless value && !value.blank? && !value.to_i.between?(1, 999_999)

      msg = "Value '#{value}' for 'Assigned User' is not valid, acceptable values are numbers between 1-999999"
      assert page.has_content?(msg), "Error message for #{field} missing"
    end
  end

  def verify_laboratory(patient, data)
    return unless !data[0].blank? || !data[1].blank? || !data[2].blank? || !data[3].blank?

    count = Laboratory.where(
      patient_id: patient.id,
      lab_type: data[0].to_s,
      specimen_collection: data[1],
      report: data[2],
      result: data[3].to_s
    ).count
    assert_equal(1, count, "Lab result for patient: #{patient.first_name} #{patient.last_name} not found")
  end

  def verify_existence(element, label, value, index)
    assert element.has_content?("#{label}:#{value && value != '' ? ' ' + value.to_s : ''}"), "#{label} should be #{value} in row #{index + 2}"
  end

  def epi_x_val(row, field)
    row[ImportExportConstants::EPI_X_FIELDS.index(field)]
  end

  def saf_val(row, field)
    row[ImportExportConstants::SARA_ALERT_FORMAT_FIELDS.index(field)]
  end

  def normalize_state_field(value)
    value ? VALID_STATES.include?(value) ? value : STATE_ABBREVIATIONS[value.upcase.to_sym] : nil
  end

  def normalize_bool_field(value)
    %w[true false].include?(value.to_s.downcase) ? (value.to_s.downcase == 'true') : nil
  end

  def get_xlsx(file_name)
    Roo::Spreadsheet.open(file_fixture(file_name).to_s)
  end
end
