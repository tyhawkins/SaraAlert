# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../system_test_utils'

class PublicHealthMonitoringImportVerifier < ApplicationSystemTestCase
  include ImportExportHelper
  @@system_test_utils = SystemTestUtils.new(nil)
    
  def verify_epi_x_field_validation(file_name)
    sheet = get_xslx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_index|
      # check validation
    end
  end
  
  def verify_sara_alert_format_field_validation(file_name)
    sheet = get_xslx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_index|
      # check validation
    end
  end
  
  def verify_epi_x_import_page(jurisdiction_id, file_name)
    sheet = get_xslx(file_name).sheet(0)
    page.all('div.card-body').each_with_index do |card, index|
      row = sheet.row(index + 2)
      verify_existence(card, 'State/Local ID', row[0], index)
      verify_existence(card, 'CDC ID', row[4], index)
      verify_existence(card, 'First Name', row[11], index)
      verify_existence(card, 'Last Name', row[10], index)
      verify_existence(card, 'DOB', row[12], index)
      verify_existence(card, 'Language', row[7], index)
      verify_existence(card, 'Flight or Vessel Number', row[1], index)
      verify_existence(card, 'Home Address Line 1', row[16], index)
      verify_existence(card, 'Home Town/City', row[17], index)
      verify_existence(card, 'Home State', normalize_state_field(row[18]), index)
      verify_existence(card, 'Home Zip', row[19], index)
      verify_existence(card, 'Monitored Address Line 1', row[20], index)
      verify_existence(card, 'Monitored Town/City', row[21], index)
      verify_existence(card, 'Monitored State', normalize_state_field(row[22]), index)
      verify_existence(card, 'Monitored Zip', row[23], index)
      verify_existence(card, 'Phone Number 1', row[28] ? Phonelib.parse(row[28], 'US').full_e164 : nil, index)
      verify_existence(card, 'Phone Number 2', row[29] ? Phonelib.parse(row[29], 'US').full_e164 : nil, index)
      verify_existence(card, 'Email', row[30], index)
      verify_existence(card, 'Exposure Location', row[35], index)
      verify_existence(card, 'Date of Departure', row[36], index)
      verify_existence(card, 'Close Contact w/ Known Case', !row[41].blank?.to_s, index)
      verify_existence(card, 'Was in HC Fac. w/ Known Cases', !row[42].blank?.to_s, index)
      if Jurisdiction.find(jurisdiction_id).all_patients.where(first_name: row[11], last_name: row[10]).length > 1
        assert card.has_content?('Warning: This monitoree already appears to exist in the system!')
      end
    end
  end

  def verify_sara_alert_format_import_page(jurisdiction_id, file_name)
    sheet = get_xslx(file_name).sheet(0)
    page.all('div.card-body').each_with_index do |card, index|
      row = sheet.row(index + 2)
      verify_existence(card, 'State/Local ID', row[15], index)
      verify_existence(card, 'CDC ID', row[16], index)
      verify_existence(card, 'First Name', row[0], index)
      verify_existence(card, 'Last Name', row[2], index)
      verify_existence(card, 'DOB', row[3], index)
      verify_existence(card, 'Language', row[11], index)
      verify_existence(card, 'Flight or Vessel Number', row[53], index)
      verify_existence(card, 'Home Address Line 1', row[18], index)
      verify_existence(card, 'Home Town/City', row[19], index)
      verify_existence(card, 'Home State', normalize_state_field(row[20]), index)
      verify_existence(card, 'Home Zip', row[22], index)
      verify_existence(card, 'Monitored Address Line 1', row[31], index)
      verify_existence(card, 'Monitored Town/City', row[32], index)
      verify_existence(card, 'Monitored State', normalize_state_field(row[33]), index)
      verify_existence(card, 'Monitored Zip', row[35], index)
      verify_existence(card, 'Phone Number 1', row[28] ? Phonelib.parse(row[44], 'US').full_e164 : nil, index)
      verify_existence(card, 'Phone Number 2', row[29] ? Phonelib.parse(row[46], 'US').full_e164 : nil, index)
      verify_existence(card, 'Email', row[49], index)
      verify_existence(card, 'Exposure Location', row[67], index)
      verify_existence(card, 'Date of Departure', row[51], index)
      verify_existence(card, 'Close Contact w/ Known Case', row[69] ? row[69].to_s.downcase : nil, index)
      verify_existence(card, 'Was in HC Fac. w/ Known Cases', row[72] ? row[72].to_s.downcase : nil, index)
      if Jurisdiction.find(jurisdiction_id).all_patients.where(first_name: row[0], middle_name: row[1], last_name: row[2]).length > 1
        assert card.has_content?('Warning: This monitoree already appears to exist in the system!')
      end
    end
  end

  def verify_epi_x_import_data(jurisdiction_id, workflow, file_name, rejects, accept_duplicates)
    sheet = get_xslx(file_name).sheet(0)
    @@system_test_utils.wait_for_db_write_delay
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_index|
      row = sheet.row(row_index)
      patients = Jurisdiction.find(jurisdiction_id).all_patients.where(first_name: row[11], last_name: row[10], date_of_birth: row[12])
      patient = patients.where('created_at > ?', 1.minute.ago)[0]
      duplicate = patients.where('created_at < ?', 1.minute.ago).exists?
      if rejects.include?(row_index - 2) || (duplicate && !accept_duplicates)
        assert_nil(patient, "Patient should not be found in db: #{row[11]} #{row[10]} in row #{row_index}")
      else
        assert_not_nil(patient, "Patient not found in db: #{row[11]} #{row[10]} in row #{row_index}")
        EPI_X_FIELDS.each_with_index do |field, index|
          if index == 28 || index == 29 # phone number fields
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif index == 13 # sex
            assert_equal(row[index] == 'M' ? 'Male' : 'Female', patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif index == 18 || (index == 22 && !row[22].nil?) # state fields
            assert_equal(normalize_state_field(row[index].to_s), patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif index == 22 && row[22].nil? # copy over monitored address state if state is nil
            assert_equal(normalize_state_field(row[index - 4].to_s), patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif [20, 21, 23].include?(index) && row[index].nil? # copy over address fields if address is nil
            assert_equal(row[index - 4].to_s, patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif index == 34 # copy over potential exposure country to location
            assert_equal(row[35].to_s, patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif index == 41 || index == 42 # contact of known case and was in healthcare facilities
            assert_equal(!row[index].blank?, patient[field], "#{field} mismatch in row #{row_index}")
          elsif !field.nil?
            assert_equal(row[index].to_s, patient[field].to_s, "#{field} mismatch in row #{row_index}")
          end
        end
        assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_index}")
      end
    end
  end

  def verify_sara_alert_format_import_data(jurisdiction_id, workflow, file_name, rejects, accept_duplicates)
    sheet = get_xslx(file_name).sheet(0)
    @@system_test_utils.wait_for_db_write_delay
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_index|
      row = sheet.row(row_index)
      patients = Jurisdiction.find(jurisdiction_id).all_patients.where(first_name: row[0], middle_name: row[1], last_name: row[2], date_of_birth: row[3])
      patient = patients.where('created_at > ?', 1.minute.ago)[0]
      duplicate = patients.where('created_at < ?', 1.minute.ago).exists?
      if rejects.include?(row_index - 2) || (duplicate && !accept_duplicates)
        assert_nil(patient, "Patient should not be found in db: #{row[0]} #{row[1]} #{row[2]} in row #{row_index}")
      else
        assert_not_nil(patient, "Patient not found in db: #{row[0]} #{row[1]} #{row[2]} in row #{row_index}")
        COMPREHENSIVE_FIELDS.each_with_index do |field, index|
          if index == 44 || index == 46 # phone number fields
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif [5, 6, 7, 8, 9, 13, 69, 71, 72, 74, 76, 78, 79].include?(index) # bool fields
            assert_equal(normalize_bool_field(row[index]).to_s, patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif [20, 39, 60].include?(index) || (index == 33 && !row[33].nil?) # state fields
            assert_equal(normalize_state_field(row[index].to_s).to_s, patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif index == 33 && row[33].nil? # copy over monitored address state if state is nil
            assert_equal(normalize_state_field(row[index - 13].to_s), patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif [31, 32, 33, 34, 35].include?(index) & row[index].nil? # copy over address fields if address is nil
            assert_equal(row[index - 13].to_s, patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif index == 85 || index == 86 # isolation workflow specific fields
            assert_equal(workflow == :isolation ? row[index].to_s : '', patient[field].to_s, "#{field} mismatch in row #{row_index}")
          elsif !field.nil?
            assert_equal(row[index].to_s, patient[field].to_s, "#{field} mismatch in row #{row_index}")
          end
        end
        verify_laboratory(patient, row[87..90])
        verify_laboratory(patient, row[91..94])
        assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_index}")
      end
    end
  end

  def verify_laboratory(patient, data)
    if !data[0].blank? || !data[1].blank? || !data[2].blank? || !data[3].blank?
      count = Laboratory.where(
        patient_id: patient.id,
        lab_type: data[0].to_s,
        specimen_collection: data[1],
        report: data[2],
        result: data[3].to_s
      ).count
      assert_equal(1, count, "Lab result for patient: #{patient.first_name} #{patient.last_name} not found")
    end
  end

  def verify_existence(element, label, value, index)
    assert element.has_content?("#{label}:#{value && value != '' ? ' ' + value.to_s : ''}"), "#{label} should be #{value} in row #{index + 2}"
  end

  def normalize_state_field(value)
    value ? VALID_STATES.include?(value) ? value : STATE_ABBREVIATIONS[value.upcase] : nil
  end

  def normalize_bool_field(value)
    %w[true false].include?(value.to_s.downcase) ? (value.to_s.downcase == 'true') : nil
  end

  def get_xslx(file_name)
    Roo::Spreadsheet.open(file_fixture(file_name).to_s)
  end
end
