const blankMockPatient = {
    additional_planned_travel_destination: null,
    additional_planned_travel_destination_country: null,
    additional_planned_travel_destination_state: null,
    additional_planned_travel_end_date: null,
    additional_planned_travel_port_of_departure: null,
    additional_planned_travel_related_notes: null,
    additional_planned_travel_start_date: null,
    additional_planned_travel_type: null,
    address_city: null,
    address_county: null,
    address_line_1: null,
    address_line_2: null,
    address_state: null,
    address_zip: null,
    age: 0,
    american_indian_or_alaska_native: null,
    asian: true,
    assigned_user: 0,
    black_or_african_american: null,
    case_status: null,
    closed_at: null,
    contact_of_known_case: false,
    contact_of_known_case_id: null,
    continuous_exposure: false,
    created_at: null,
    creator_id: 0,
    crew_on_passenger_or_cargo_flight: false,
    date_of_arrival: null,
    date_of_birth: null,
    date_of_departure: null,
    email: null,
    ethnicity: null,
    exposure_notes: null,
    exposure_risk_assessment: null,
    extended_isolation: null,
    first_name: null,
    flight_or_vessel_carrier: null,
    flight_or_vessel_number: null,
    foreign_address_city: null,
    foreign_address_country: null,
    foreign_address_line_1: null,
    foreign_address_line_2: null,
    foreign_address_line_3: null,
    foreign_address_state: null,
    foreign_address_zip: null,
    foreign_monitored_address_city: null,
    foreign_monitored_address_county: null,
    foreign_monitored_address_line_1: null,
    foreign_monitored_address_line_2: null,
    foreign_monitored_address_state: null,
    foreign_monitored_address_zip: null,
    gender_identity: null,
    healthcare_personnel: true,
    healthcare_personnel_facility_name: null,
    id: 0,
    interpretation_required: true,
    isolation: true,
    jurisdiction_id: 0,
    laboratory_personnel: false,
    laboratory_personnel_facility_name: null,
    last_assessment_reminder_sent: null,
    last_date_of_exposure: null,
    last_name: null,
    latest_assessment_at: null,
    latest_fever_or_fever_reducer_at: null,
    latest_positive_lab_at: null,
    latest_transfer_at: null,
    latest_transfer_from: null,
    linelist: {
        assigned_user: 0,
        closed_at: null,
        dob: null,
        end_of_monitoring: null,
        expected_purge_date: null,
        extended_isolation: null,
        id: 0,
        jurisdiction: null,
        latest_report: null,
        monitoring_plan: null,
        name: null,
        public_health_action: null,
        reason_for_closure: null,
        risk_level: null,
        sex: null,
        state_local_id: null,
        status: null,
        transferred_at: null,
        transferred_from: null,
        transferred_to: null,
    },
    member_of_a_common_exposure_cohort: true,
    member_of_a_common_exposure_cohort_type: null,
    middle_name: null,
    monitored_address_city: null,
    monitored_address_county: null,
    monitored_address_line_1: null,
    monitored_address_line_2: null,
    monitored_address_state: null,
    monitored_address_zip: null,
    monitoring: true,
    monitoring_plan: null,
    monitoring_reason: null,
    nationality: null,
    native_hawaiian_or_other_pacific_islander: null,
    negative_lab_count: 0,
    pause_notifications: false,
    port_of_entry_into_usa: null,
    port_of_origin: null,
    potential_exposure_country: null,
    potential_exposure_location: null,
    preferred_contact_method: null,
    preferred_contact_time: null,
    primary_language: null,
    primary_telephone: null,
    primary_telephone_type: null,
    public_health_action: null,
    purged: false,
    responder_id: 0,
    secondary_language: null,
    secondary_telephone: null,
    secondary_telephone_type: null,
    sex: null,
    sexual_orientation: null,
    source_of_report: null,
    source_of_report_specify: null,
    submission_token: null,
    symptom_onset: null,
    travel_related_notes: null,
    travel_to_affected_country_or_area: false,
    updated_at: null,
    user_defined_id: null,
    user_defined_id_cdc: null,
    user_defined_id_nndss: null,
    user_defined_id_statelocal: null,
    user_defined_symptom_onset: null,
    was_in_health_care_facility_with_known_cases: false,
    was_in_health_care_facility_with_known_cases_facility_name: null,
    white: null
}

const mockPatient1 = {
    additional_planned_travel_destination: "Kokomo",
    additional_planned_travel_destination_country: "USA",
    additional_planned_travel_destination_state: "Florida",
    additional_planned_travel_end_date: "2020-09-16",
    additional_planned_travel_port_of_departure: "Miami",
    additional_planned_travel_related_notes: null,
    additional_planned_travel_start_date: "2020-09-05",
    additional_planned_travel_type: "Domestic",
    address_city: "Springfield",
    address_county: "Fairfield",
    address_line_1: "1 Hartford Drive",
    address_line_2: null,
    address_state: "Connecticut",
    address_zip: "00000-0000",
    age: 76,
    american_indian_or_alaska_native: null,
    asian: true,
    assigned_user: 21,
    black_or_african_american: null,
    case_status: "Not a Case",
    closed_at: "2020-09-13T20:32:02.000Z",
    contact_of_known_case: false,
    contact_of_known_case_id: null,
    continuous_exposure: false,
    created_at: "2020-09-13T14:35:09.000Z",
    creator_id: 4,
    crew_on_passenger_or_cargo_flight: false,
    date_of_arrival: null,
    date_of_birth: "1945-03-08",
    date_of_departure: null,
    email: "minnie.mouse@example.com",
    ethnicity: "Not Hispanic or Latino",
    exposure_notes: null,
    exposure_risk_assessment: "No Identified Risk",
    extended_isolation: null,
    first_name: "Minnie",
    flight_or_vessel_carrier: null,
    flight_or_vessel_number: null,
    foreign_address_city: null,
    foreign_address_country: null,
    foreign_address_line_1: null,
    foreign_address_line_2: null,
    foreign_address_line_3: null,
    foreign_address_state: null,
    foreign_address_zip: null,
    foreign_monitored_address_city: null,
    foreign_monitored_address_county: null,
    foreign_monitored_address_line_1: null,
    foreign_monitored_address_line_2: null,
    foreign_monitored_address_state: null,
    foreign_monitored_address_zip: null,
    gender_identity: null,
    healthcare_personnel: true,
    healthcare_personnel_facility_name: "Crystal Ball",
    id: 17,
    interpretation_required: true,
    isolation: true,
    jurisdiction_id: 4,
    laboratory_personnel: false,
    laboratory_personnel_facility_name: null,
    last_assessment_reminder_sent: null,
    last_date_of_exposure: "2020-09-13",
    last_name: "Mouse",
    latest_assessment_at: "2020-09-15T20:59:36.000Z",
    latest_fever_or_fever_reducer_at: null,
    latest_positive_lab_at: null,
    latest_transfer_at: null,
    latest_transfer_from: null,
    linelist: {
        assigned_user: 21,
        closed_at: "Sun, 13 Sep 2020 20:32:02 +0000",
        dob: "1945-03-08",
        end_of_monitoring: "2020-09-27",
        expected_purge_date: "Sun, 27 Sep 2020 20:32:02 +0000",
        extended_isolation: "",
        id: 17,
        jurisdiction: "County 2",
        latest_report: "Tue, 15 Sep 2020 20:59:36 +0000",
        monitoring_plan: "None",
        name: "Mouse, Minnie",
        public_health_action: "None",
        reason_for_closure: "Transferred to another jurisdiction",
        risk_level: "No Identified Risk",
        sex: "Female",
        state_local_id: "EX-771721",
        status: "reporting",
        transferred_at: "",
        transferred_from: "",
        transferred_to: ""
    },
    member_of_a_common_exposure_cohort: true,
    member_of_a_common_exposure_cohort_type: "Dark Two-Face",
    middle_name: null,
    monitored_address_city: "Santoton",
    monitored_address_county: "Pine Heights",
    monitored_address_line_1: "94011 Green Passage",
    monitored_address_line_2: "Suite 455",
    monitored_address_state: "Massachusetts",
    monitored_address_zip: "98145-4774",
    monitoring: true,
    monitoring_plan: "None",
    monitoring_reason: "Transferred to another jurisdiction",
    nationality: "Serbs",
    native_hawaiian_or_other_pacific_islander: null,
    negative_lab_count: 0,
    pause_notifications: false,
    port_of_entry_into_usa: null,
    port_of_origin: null,
    potential_exposure_country: "Mexico",
    potential_exposure_location: null,
    preferred_contact_method: "E-mailed Web Link",
    preferred_contact_time: null,
    primary_language: "English",
    primary_telephone: null,
    primary_telephone_type: null,
    public_health_action: "None",
    purged: false,
    responder_id: 292,
    secondary_language: null,
    secondary_telephone: null,
    secondary_telephone_type: null,
    sex: "Female",
    sexual_orientation: null,
    source_of_report: null,
    source_of_report_specify: null,
    submission_token: "ed3535055837367e9edb14b131b130b5f4c70e15",
    symptom_onset: null,
    travel_related_notes: null,
    travel_to_affected_country_or_area: false,
    updated_at: "2020-09-13T20:32:02.000Z",
    user_defined_id_cdc: "4677015425",
    user_defined_id_nndss: "38966610-6",
    user_defined_id_statelocal: "EX-771721",
    user_defined_symptom_onset: null,
    was_in_health_care_facility_with_known_cases: false,
    was_in_health_care_facility_with_known_cases_facility_name: null,
    white: null
}

const mockPatient2 = {
    additional_planned_travel_destination: "Kokomo",
    additional_planned_travel_destination_country: "USA",
    additional_planned_travel_destination_state: "Florida",
    additional_planned_travel_end_date: "2020-09-16",
    additional_planned_travel_port_of_departure: "Miami",
    additional_planned_travel_related_notes: null,
    additional_planned_travel_start_date: "2020-09-05",
    additional_planned_travel_type: "Domestic",
    address_city: "Springfield",
    address_county: "Fairfield",
    address_line_1: "1 Hartford Drive",
    address_line_2: null,
    address_state: "Connecticut",
    address_zip: "00000-0000",
    age: 79,
    american_indian_or_alaska_native: null,
    asian: true,
    assigned_user: 21,
    black_or_african_american: null,
    case_status: "Not a Case",
    closed_at: "2020-09-13T20:32:02.000Z",
    contact_of_known_case: false,
    contact_of_known_case_id: null,
    continuous_exposure: false,
    created_at: "2020-09-13T14:35:09.000Z",
    creator_id: 4,
    crew_on_passenger_or_cargo_flight: false,
    date_of_arrival: null,
    date_of_birth: "1942-03-08",
    date_of_departure: null,
    email: "mickey.mouse@example.com",
    ethnicity: "Not Hispanic or Latino",
    exposure_notes: null,
    exposure_risk_assessment: "No Identified Risk",
    extended_isolation: null,
    first_name: "Mickey",
    flight_or_vessel_carrier: null,
    flight_or_vessel_number: null,
    foreign_address_city: null,
    foreign_address_country: null,
    foreign_address_line_1: null,
    foreign_address_line_2: null,
    foreign_address_line_3: null,
    foreign_address_state: null,
    foreign_address_zip: null,
    foreign_monitored_address_city: null,
    foreign_monitored_address_county: null,
    foreign_monitored_address_line_1: null,
    foreign_monitored_address_line_2: null,
    foreign_monitored_address_state: null,
    foreign_monitored_address_zip: null,
    gender_identity: null,
    healthcare_personnel: true,
    healthcare_personnel_facility_name: "Crystal Ball",
    id: 18,
    interpretation_required: true,
    isolation: true,
    jurisdiction_id: 4,
    laboratory_personnel: false,
    laboratory_personnel_facility_name: null,
    last_assessment_reminder_sent: null,
    last_date_of_exposure: "2020-09-13",
    last_name: "Mouse",
    latest_assessment_at: "2020-09-15T20:59:36.000Z",
    latest_fever_or_fever_reducer_at: null,
    latest_positive_lab_at: null,
    latest_transfer_at: null,
    latest_transfer_from: null,
    linelist: {
        assigned_user: 21,
        closed_at: "Sun, 13 Sep 2020 20:32:02 +0000",
        dob: "1942-03-08",
        end_of_monitoring: "2020-09-27",
        expected_purge_date: "Sun, 27 Sep 2020 20:32:02 +0000",
        extended_isolation: "",
        id: 18,
        jurisdiction: "County 2",
        latest_report: "Tue, 15 Sep 2020 20:59:36 +0000",
        monitoring_plan: "None",
        name: "Mouse, Mickey",
        public_health_action: "None",
        reason_for_closure: "Transferred to another jurisdiction",
        risk_level: "No Identified Risk",
        sex: "Male",
        state_local_id: "EX-771721",
        status: "reporting",
        transferred_at: "",
        transferred_from: "",
        transferred_to: ""
    },
    member_of_a_common_exposure_cohort: true,
    member_of_a_common_exposure_cohort_type: "Dark Two-Face",
    middle_name: null,
    monitored_address_city: "Santoton",
    monitored_address_county: "Pine Heights",
    monitored_address_line_1: "94011 Green Passage",
    monitored_address_line_2: "Suite 455",
    monitored_address_state: "Massachusetts",
    monitored_address_zip: "98145-4774",
    monitoring: true,
    monitoring_plan: "None",
    monitoring_reason: "Transferred to another jurisdiction",
    nationality: "Serbs",
    native_hawaiian_or_other_pacific_islander: null,
    negative_lab_count: 0,
    pause_notifications: false,
    port_of_entry_into_usa: null,
    port_of_origin: null,
    potential_exposure_country: "Mexico",
    potential_exposure_location: null,
    preferred_contact_method: "SMS Texted Weblink",
    preferred_contact_time: null,
    primary_language: "English",
    primary_telephone: '123-456-7890',
    primary_telephone_type: 'Smartphone',
    public_health_action: "None",
    purged: false,
    responder_id: 292,
    secondary_language: null,
    secondary_telephone: null,
    secondary_telephone_type: null,
    sex: "Male",
    sexual_orientation: null,
    source_of_report: null,
    source_of_report_specify: null,
    submission_token: "ed3535055837367e9edb14b131b130b5f4c70e15",
    symptom_onset: null,
    travel_related_notes: null,
    travel_to_affected_country_or_area: false,
    updated_at: "2020-09-13T20:32:02.000Z",
    user_defined_id: "00000-1",
    user_defined_id_cdc: "4677015425",
    user_defined_id_nndss: "38966610-6",
    user_defined_id_statelocal: "EX-771721",
    user_defined_symptom_onset: null,
    was_in_health_care_facility_with_known_cases: false,
    was_in_health_care_facility_with_known_cases_facility_name: null,
    white: null
}

export {
    blankMockPatient,
    mockPatient1,
    mockPatient2
};