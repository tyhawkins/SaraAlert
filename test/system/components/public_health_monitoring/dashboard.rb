# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../../lib/system_test_utils'

class PublicHealthMonitoringDashboard < ApplicationSystemTestCase

  @@system_test_utils = SystemTestUtils.new(nil)
  
  PATIENTS = @@system_test_utils.get_patients
  
  def verify_patients_under_tab(tab, patient_ids)
    click_on tab
    PATIENTS.each do |patient_name, patient|
      search_for_and_verify_patient(patient_name, patient_ids.include?(patient['id']))
    end
  end

  def verify_patient_under_tab(tab, patient_name)
    click_on tab
    search_for_and_verify_patient(patient_name, true)
  end

  def search_for_and_verify_patient(patient_name, should_exist)
    search_for_patient(patient_name)    
    if should_exist
      assert_selector 'td', text: @@system_test_utils.get_patient_display_name(patient_name)
      assert_selector 'td', text: PATIENTS[patient_name]['date_of_birth']
    else
      refute_selector 'td', text: @@system_test_utils.get_patient_display_name(patient_name)
      refute_selector 'td', text: PATIENTS[patient_name]['date_of_birth']
    end
  end

  def search_for_and_view_patient(tab, patient_name)
    click_on tab
    search_for_patient(patient_name)
    click_on @@system_test_utils.get_patient_display_name(patient_name)
  end

  def search_for_patient(patient_name)
    fill_in 'Search:', with: PATIENTS[patient_name]['last_name']
  end

end
