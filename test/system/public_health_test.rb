# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'components/public_health_monitoring/actions'
require_relative 'components/public_health_monitoring/dashboard'
require_relative 'components/public_health_monitoring/history'
require_relative 'components/public_health_monitoring/reports'
require_relative 'lib/system_test_utils'

class PublicHealthTest < ApplicationSystemTestCase
  @@public_health_monitoring_actions = PublicHealthMonitoringActions.new(nil)
  @@public_health_monitoring_dashboard = PublicHealthMonitoringDashboard.new(nil)
  @@public_health_monitoring_history = PublicHealthMonitoringHistory.new(nil)
  @@public_health_monitoring_reports = PublicHealthMonitoringReports.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  ASSESSMENTS = @@system_test_utils.get_assessments

  test 'epis can only view and search for patients under their jurisdiction' do
    search_for_and_verify_patients_under_jurisdiction('state1_epi', [3], [1, 2], [4], [6, 7, 8], [5])
    search_for_and_verify_patients_under_jurisdiction('locals1c1_epi', [], [], [4], [], [])
    search_for_and_verify_patients_under_jurisdiction('locals1c2_epi', [], [], [], [6], [])
    search_for_and_verify_patients_under_jurisdiction('state2_epi', [], [], [], [9, 10, 11], [])
    search_for_and_verify_patients_under_jurisdiction('locals2c3_epi', [], [], [], [11], [])
    search_for_and_verify_patients_under_jurisdiction('locals2c4_epi', [], [], [], [10], [])
    search_for_and_verify_patients_under_jurisdiction('state1_epi_enroller', [3], [1, 2], [4], [6, 7, 8], [5])
  end

  test 'update monitoring status' do
    update_monitoring_status('state1_epi', 'patient_2', 'Non-Reporting', 'Closed', 'Not Monitoring', 'Completed Monitoring', 'details')
  end

  test 'update exposure risk assessment' do
    update_exposure_risk_assessment('locals1c1_epi', 'patient_4', 'Asymptomatic', 'High', 'details')
  end

  test 'update monitoring plan' do
    update_monitoring_plan('locals1c2_epi', 'patient_6', 'PUI', 'Daily active monitoring', 'details')
  end

  test 'update assigned jurisdiction' do
    update_jurisdiction('state2_epi', 'patient_11', 'PUI', 'USA, State 2, County 4', 'details')
    search_for_and_verify_patients_under_jurisdiction('state2_epi', [], [], [], [9, 10, 11], [])
    search_for_and_verify_patients_under_jurisdiction('locals2c3_epi', [], [], [], [], [])
    search_for_and_verify_patients_under_jurisdiction('locals2c4_epi', [], [], [], [10, 11], [])
  end

  test 'view reports' do
    view_reports('state1_epi', 'patient_1', 'Non-Reporting', [1, 2])
    view_reports('state1_epi', 'patient_2', 'Non-Reporting', [1, 2])
    view_reports('state1_epi', 'patient_3', 'Symptomatic', [1, 2])
    view_reports('locals1c1_epi', 'patient_4', 'Asymptomatic', [1])
    view_reports('state1_epi', 'patient_5', 'Closed', [1])
    view_reports('state1_epi', 'patient_6', 'PUI', [])
    view_reports('state1_epi', 'patient_7', 'PUI', [])
    view_reports('state1_epi', 'patient_8', 'PUI', [1, 2])
    view_reports('state2_epi', 'patient_9', 'PUI', [1, 2, 3, 4])
    view_reports('locals2c4_epi', 'patient_10', 'PUI', [1, 2, 3])
    view_reports('locals2c3_epi', 'patient_11', 'PUI', [])
  end

  test 'add report' do
    add_report('locals1c1_epi', 'patient_4', 'Asymptomatic', ASSESSMENTS["assessment_1"])
  end

  test 'edit report' do
    edit_report('locals2c4_epi', 'patient_10', 'PUI', 3, ASSESSMENTS["assessment_2"], 'Symptomatic')
  end

  test 'edit report and cancel' do
    edit_report_and_cancel('locals2c4_epi', 'patient_10', 'PUI', 3, ASSESSMENTS["assessment_2"])
  end

  test 'clear all reports' do
    mark_all_as_reviewed('state1_epi_enroller', 'patient_5', 'Closed', 'details')
  end

  test 'add comment' do
    add_comment('locals2c3_epi', 'patient_11', 'PUI', 'comment')
  end

  test 'export linelist data to csv' do
    #export_linelist_data_to_csv('locals2c4_epi')
  end

  test 'export comprehensive data to csv' do
    #export_comprehensive_data_to_csv('locals2c4_epi')
  end

  def search_for_and_verify_patients_under_jurisdiction(user_name, symptomatic_patients, non_reporting_patients, asymptomatic_patients, pui_patients, closed_patients)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.verify_patients_under_tab('Symptomatic', symptomatic_patients)
    @@public_health_monitoring_dashboard.verify_patients_under_tab('Non-Reporting', non_reporting_patients)
    @@public_health_monitoring_dashboard.verify_patients_under_tab('Asymptomatic', asymptomatic_patients)
    @@public_health_monitoring_dashboard.verify_patients_under_tab('PUI', pui_patients)
    @@public_health_monitoring_dashboard.verify_patients_under_tab('Closed', closed_patients)
    @@system_test_utils.logout
  end

  def update_monitoring_status(user_name, patient_name, old_tab, new_tab, monitoring_status, status_change_reason, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(old_tab, patient_name)
    @@public_health_monitoring_actions.update_monitoring_status(monitoring_status, status_change_reason, reasoning)
    @@public_health_monitoring_history.verify_monitoring_status_update(user_name, monitoring_status, status_change_reason, reasoning)
    @@system_test_utils.return_to_dashboard
    @@public_health_monitoring_dashboard.verify_patient_under_tab(new_tab, patient_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(new_tab, patient_name)
    @@public_health_monitoring_history.verify_monitoring_status_update(user_name, monitoring_status, status_change_reason, reasoning)
    @@system_test_utils.logout
  end

  def update_exposure_risk_assessment(user_name, patient_name, tab, exposure_risk_assessment, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_name)
    @@public_health_monitoring_actions.update_exposure_risk_assessment(exposure_risk_assessment, reasoning)
    @@public_health_monitoring_history.verify_exposure_risk_assessment_update(user_name, exposure_risk_assessment, reasoning)
    @@system_test_utils.return_to_dashboard
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_name)
    @@public_health_monitoring_history.verify_exposure_risk_assessment_update(user_name, exposure_risk_assessment, reasoning)
    @@system_test_utils.logout
  end

  def update_monitoring_plan(user_name, patient_name, tab, monitoring_plan, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_name)
    @@public_health_monitoring_actions.update_monitoring_plan(monitoring_plan, reasoning)
    @@public_health_monitoring_history.verify_monitoring_plan_update(user_name, monitoring_plan, reasoning)
    @@system_test_utils.return_to_dashboard
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_name)
    @@public_health_monitoring_history.verify_monitoring_plan_update(user_name, monitoring_plan, reasoning)
    @@system_test_utils.logout
  end

  def update_jurisdiction(user_name, patient_name, tab, jurisdiction, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_name)
    @@public_health_monitoring_actions.update_jurisdiction(jurisdiction, reasoning)
    @@public_health_monitoring_history.verify_jurisdiction_update(user_name, jurisdiction, reasoning)
    @@system_test_utils.logout
  end

  def add_comment(user_name, patient_name, tab, comment)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_name)
    @@public_health_monitoring_history.add_comment(comment)
    @@public_health_monitoring_history.verify_comment(user_name, comment)
    @@system_test_utils.return_to_dashboard
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_name)
    @@public_health_monitoring_history.verify_comment(user_name, comment)
    @@system_test_utils.logout
  end

  def view_reports(user_name, patient_name, tab, report_numbers)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_name)
    @@public_health_monitoring_reports.verify_existing_reports(patient_name, report_numbers)
    @@system_test_utils.logout
  end

  def add_report(user_name, patient_name, tab, assessment)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_name)
    @@public_health_monitoring_reports.add_report(assessment)
    @@public_health_monitoring_reports.verify_new_report(user_name, assessment)
    @@public_health_monitoring_history.verify_add_report(user_name)
    @@system_test_utils.logout
  end

  def edit_report(user_name, patient_name, old_tab, report_number, assessment, new_tab)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(old_tab, patient_name)
    @@public_health_monitoring_reports.edit_report(patient_name, report_number, assessment)
    @@public_health_monitoring_reports.verify_new_report(user_name, assessment)
    @@public_health_monitoring_history.verify_edit_report(user_name)
    @@system_test_utils.logout
  end

  def edit_report_and_cancel(user_name, patient_name, old_tab, report_number, assessment)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(old_tab, patient_name)
    @@public_health_monitoring_reports.edit_report_and_cancel(patient_name, report_number, assessment)
    ## add some assertions
    @@system_test_utils.logout
  end

  def mark_all_as_reviewed(user_name, patient_name, tab, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_name)
    @@public_health_monitoring_reports.mark_all_as_reviewed(reasoning)
    @@public_health_monitoring_history.verify_all_marked_as_reviewed(user_name)
    @@system_test_utils.logout
  end

  def export_linelist_data_to_csv(user_name)
    @@system_test_utils.login(user_name)
    assert_selector 'button', text: 'Export'
    click_on 'Export'
    click_on 'Line list CSV'
    @@system_test_utils.logout
  end

  def export_comprehensive_data_to_csv(user_name)
    @@system_test_utils.login(user_name)
    assert_selector 'button', text: 'Export'
    click_on 'Export'
    click_on 'Sara Alert Format CSV'
    @@system_test_utils.logout
  end
end
