# frozen_string_literal: true

# Helper module for FHIR translations
module FhirHelper # rubocop:todo Metrics/ModuleLength
  # Returns a representative FHIR::Patient for an instance of a Sara Alert Patient. Uses US Core
  # extensions for sex, race, and ethnicity.
  # https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-patient.html
  def patient_as_fhir(patient)
    return nil if patient.nil?

    creator_agent_ref = FHIR::Reference.new
    if patient.creator.is_api_proxy
      # Created with an M2M workflow client
      creator_app = OauthApplication.find_by(user_id: patient.creator.id)
      creator_agent_ref.identifier = FHIR::Identifier.new(value: creator_app.uid)
      creator_agent_ref.display = creator_app.name
    else
      # Created with a user worfklow client or a human user
      creator_agent_ref.identifier = FHIR::Identifier.new(value: patient.creator.id)
      creator_agent_ref.display = patient.creator.email
    end

    FHIR::Patient.new(
      meta: FHIR::Meta.new(lastUpdated: patient.updated_at.strftime('%FT%T%:z')),
      contained: [FHIR::Provenance.new(
        # Would like to use a Rails URL Helper here, but we don't get one for this endpoint
        target: [FHIR::Reference.new(reference: "/fhir/r4/Patient/#{patient.id}")],
        agent: [
          FHIR::Provenance::Agent.new(
            who: creator_agent_ref
          )
        ],
        recorded: patient.created_at.strftime('%FT%T%:z'),
        activity: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/v3-DataOperation',
              code: 'CREATE',
              display: 'create'
            }
          ]
        }
      )],
      id: patient.id,
      identifier: [to_statelocal_identifier(patient.user_defined_id_statelocal)],
      active: patient.monitoring,
      name: [FHIR::HumanName.new(given: [patient.first_name, patient.middle_name].reject(&:blank?), family: patient.last_name)],
      telecom: [
        patient.primary_telephone ? FHIR::ContactPoint.new(system: 'phone',
                                                           value: patient.primary_telephone,
                                                           rank: 1,
                                                           extension: [to_string_extension(patient.primary_telephone_type, 'phone-type')])
                                  : nil,
        patient.secondary_telephone ? FHIR::ContactPoint.new(system: 'phone',
                                                             value: patient.secondary_telephone,
                                                             rank: 2,
                                                             extension: [to_string_extension(patient.secondary_telephone_type, 'phone-type')])
                                    : nil,
        patient.email ? FHIR::ContactPoint.new(system: 'email', value: patient.email, rank: 1) : nil
      ].reject(&:nil?),
      birthDate: patient.date_of_birth&.strftime('%F'),
      address: [to_address_by_type_extension(patient, 'USA'), to_address_by_type_extension(patient, 'Foreign')].reject(&:blank?),
      communication: [
        language_coding(patient.primary_language) ? FHIR::Patient::Communication.new(
          language: FHIR::CodeableConcept.new(coding: [language_coding(patient.primary_language)]),
          preferred: patient.interpretation_required
        ) : nil
      ].reject(&:nil?),
      extension: [
        to_us_core_race(races_as_hash(patient)),
        to_us_core_ethnicity(patient.ethnicity),
        to_us_core_birthsex(patient.sex),
        to_string_extension(patient.preferred_contact_method, 'preferred-contact-method'),
        to_string_extension(patient.preferred_contact_time, 'preferred-contact-time'),
        to_date_extension(patient.symptom_onset, 'symptom-onset-date'),
        to_date_extension(patient.last_date_of_exposure, 'last-date-of-exposure'),
        to_bool_extension(patient.isolation, 'isolation'),
        to_string_extension(patient.jurisdiction.jurisdiction_path_string, 'full-assigned-jurisdiction-path'),
        to_string_extension(patient.monitoring_plan, 'monitoring-plan'),
        to_positive_integer_extension(patient.assigned_user, 'assigned-user'),
        to_date_extension(patient.additional_planned_travel_start_date, 'additional-planned-travel-start-date'),
        to_string_extension(patient.port_of_origin, 'port-of-origin'),
        to_date_extension(patient.date_of_departure, 'date-of-departure'),
        to_string_extension(patient.flight_or_vessel_number, 'flight-or-vessel-number'),
        to_string_extension(patient.flight_or_vessel_carrier, 'flight-or-vessel-carrier'),
        to_date_extension(patient.date_of_arrival, 'date-of-arrival'),
        to_string_extension(patient.exposure_notes, 'exposure-notes'),
        to_string_extension(patient.travel_related_notes, 'travel-related-notes'),
        to_string_extension(patient.additional_planned_travel_related_notes, 'additional-planned-travel-notes'),
        to_bool_extension(patient.continuous_exposure, 'continuous-exposure')
      ].reject(&:nil?)
    )
  end

  def races_as_hash(patient)
    {
      white: patient.white,
      black_or_african_american: patient.black_or_african_american,
      american_indian_or_alaska_native: patient.american_indian_or_alaska_native,
      asian: patient.asian,
      native_hawaiian_or_other_pacific_islander: patient.native_hawaiian_or_other_pacific_islander,
      race_other: patient.race_other,
      race_unknown: patient.race_unknown,
      race_refused_to_answer: patient.race_refused_to_answer
    }
  end

  # Create a hash of atttributes that corresponds to a Sara Alert Patient (and can be used to
  # create new ones, or update existing ones), using the given FHIR::Patient.
  def patient_from_fhir(patient, default_jurisdiction_id)
    symptom_onset = from_date_extension(patient, ['symptom-onset-date'])
    address = from_address_by_type_extension(patient, 'USA')
    foreign_address = from_address_by_type_extension(patient, 'Foreign')
    {
      monitoring: patient&.active.nil? ? false : patient.active,
      first_name: patient&.name&.first&.given&.first,
      middle_name: patient&.name&.first&.given&.second,
      last_name: patient&.name&.first&.family,
      primary_telephone: from_fhir_phone_number(patient&.telecom&.select { |t| t&.system == 'phone' }&.first&.value),
      secondary_telephone: from_fhir_phone_number(patient&.telecom&.select { |t| t&.system == 'phone' }&.second&.value),
      email: patient&.telecom&.select { |t| t&.system == 'email' }&.first&.value,
      date_of_birth: patient&.birthDate,
      age: Patient.calc_current_age_fhir(patient&.birthDate),
      address_line_1: address&.line&.first,
      address_line_2: address&.line&.second,
      address_city: address&.city,
      address_county: address&.district,
      address_state: address&.state,
      address_zip: address&.postalCode,
      monitored_address_line_1: address&.line&.first,
      monitored_address_line_2: address&.line&.second,
      monitored_address_city: address&.city,
      monitored_address_county: address&.district,
      monitored_address_state: address&.state,
      monitored_address_zip: address&.postalCode,
      foreign_address_line_1: foreign_address&.line&.first,
      foreign_address_line_2: foreign_address&.line&.second,
      foreign_address_line_3: foreign_address&.line&.third,
      foreign_address_city: foreign_address&.city,
      foreign_address_state: foreign_address&.state,
      foreign_address_zip: foreign_address&.postalCode,
      foreign_address_country: foreign_address&.country,
      primary_language: patient&.communication&.first&.language&.coding&.first&.display,
      interpretation_required: patient&.communication&.first&.preferred,
      white: race_code?(patient, '2106-3', 'ombCategory', false),
      black_or_african_american: race_code?(patient, '2054-5', 'ombCategory', false),
      american_indian_or_alaska_native: race_code?(patient, '1002-5', 'ombCategory', false),
      asian: race_code?(patient, '2028-9', 'ombCategory', false),
      native_hawaiian_or_other_pacific_islander: race_code?(patient, '2076-8', 'ombCategory', false),
      race_other: race_code?(patient, '2131-1', 'detailed', false),
      race_unknown: race_code?(patient, 'unknown', 'http://hl7.org/fhir/StructureDefinition/data-absent-reason', true),
      race_refused_to_answer: race_code?(patient, 'asked-declined', 'http://hl7.org/fhir/StructureDefinition/data-absent-reason', true),
      ethnicity: from_us_core_ethnicity(patient),
      sex: from_us_core_birthsex(patient),
      preferred_contact_method: from_string_extension(patient, 'preferred-contact-method'),
      preferred_contact_time: from_string_extension(patient, 'preferred-contact-time'),
      symptom_onset: symptom_onset,
      user_defined_symptom_onset: !symptom_onset.nil?,
      last_date_of_exposure: from_date_extension(patient, %w[last-date-of-exposure last-exposure-date]),
      isolation: from_bool_extension(patient, 'isolation') || false,
      jurisdiction_id: from_full_assigned_jurisdiction_path_extension(patient, default_jurisdiction_id),
      monitoring_plan: from_string_extension(patient, 'monitoring-plan'),
      assigned_user: from_positive_integer_extension(patient, 'assigned-user'),
      additional_planned_travel_start_date: from_date_extension(patient, ['additional-planned-travel-start-date']),
      port_of_origin: from_string_extension(patient, 'port-of-origin'),
      date_of_departure: from_date_extension(patient, ['date-of-departure']),
      flight_or_vessel_number: from_string_extension(patient, 'flight-or-vessel-number'),
      flight_or_vessel_carrier: from_string_extension(patient, 'flight-or-vessel-carrier'),
      date_of_arrival: from_date_extension(patient, ['date-of-arrival']),
      exposure_notes: from_string_extension(patient, 'exposure-notes'),
      travel_related_notes: from_string_extension(patient, 'travel-related-notes'),
      additional_planned_travel_related_notes: from_string_extension(patient, 'additional-planned-travel-notes'),
      primary_telephone_type: from_primary_phone_type_extension(patient),
      secondary_telephone_type: from_secondary_phone_type_extension(patient),
      user_defined_id_statelocal: from_statelocal_id_extension(patient),
      continuous_exposure: from_bool_extension(patient, 'continuous-exposure') || false
    }
  end

  def close_contact_as_fhir(close_contact)
    FHIR::RelatedPerson.new(
      meta: FHIR::Meta.new(lastUpdated: close_contact.updated_at.strftime('%FT%T%:z')),
      id: close_contact.id,
      name: [FHIR::HumanName.new(given: [close_contact.first_name].reject(&:blank?), family: close_contact.last_name)],
      telecom: [
        close_contact.primary_telephone ? FHIR::ContactPoint.new(system: 'phone',
                                                                 value: close_contact.primary_telephone,
                                                                 rank: 1)
                                  : nil,
        close_contact.email ? FHIR::ContactPoint.new(system: 'email', value: close_contact.email, rank: 1) : nil
      ].reject(&:nil?),
      patient: FHIR::Reference.new(reference: "Patient/#{close_contact.patient_id}"),
      extension: [
        to_date_extension(close_contact.last_date_of_exposure, 'last-date-of-exposure'),
        to_positive_integer_extension(close_contact.assigned_user, 'assigned-user'),
        to_unsigned_integer_extension(close_contact.contact_attempts, 'contact-attempts'),
        to_string_extension(close_contact.notes, 'notes'),
        to_reference_extension(close_contact.enrolled_id, 'Patient', 'enrolled-patient')
      ]
    )
  end

  def close_contact_from_fhir(related_person)
    {
      first_name: related_person&.name&.first&.given&.first,
      last_name: related_person&.name&.first&.family,
      primary_telephone: from_fhir_phone_number(related_person&.telecom&.find { |t| t&.system == 'phone' }&.value),
      email: related_person&.telecom&.find { |t| t&.system == 'email' }&.value,
      last_date_of_exposure: from_date_extension(related_person, %w[last-date-of-exposure last-exposure-date]),
      assigned_user: from_positive_integer_extension(related_person, 'assigned-user'),
      notes: from_string_extension(related_person, 'notes'),
      patient_id: related_person&.patient&.reference&.match(%r{^Patient/(\d+)$}).to_a[1],
      contact_attempts: from_unsigned_integer_extension(related_person, 'contact-attempts') || 0
    }
  end

  # Build a FHIR US Core Race Extension given Sara Alert race booleans.
  def to_us_core_race(races)
    # Don't return an extension if all race categories are false or nil
    return nil unless races.values.include?(true)

    # Build out extension based on what race categories are true
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race', extension: [
      races[:white] ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2106-3', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'White')
      ) : nil,
      races[:black_or_african_american] ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2054-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Black or African American')
      ) : nil,
      races[:american_indian_or_alaska_native] ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '1002-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'American Indian or Alaska Native')
      ) : nil,
      races[:asian] ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2028-9', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Asian')
      ) : nil,
      races[:native_hawaiian_or_other_pacific_islander] ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2076-8', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Native Hawaiian or Other Pacific Islander')
      ) : nil,
      races[:race_other] ? FHIR::Extension.new(
        url: 'detailed',
        valueCoding: FHIR::Coding.new(code: '2131-1', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Other Race')
      ) : nil,
      races[:race_unknown] ? FHIR::Extension.new(
        url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason',
        valueCode: 'unknown'
      ) : nil,
      races[:race_refused_to_answer] ? FHIR::Extension.new(
        url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason',
        valueCode: 'asked-declined'
      ) : nil,
      FHIR::Extension.new(
        url: 'text',
        valueString: [races[:white] ? 'White' : nil,
                      races[:black_or_african_american] ? 'Black or African American' : nil,
                      races[:american_indian_or_alaska_native] ? 'American Indian or Alaska Native' : nil,
                      races[:asian] ? 'Asian' : nil,
                      races[:native_hawaiian_or_other_pacific_islander] ? 'Native Hawaiian or Other Pacific Islander' : nil,
                      races[:race_unknown] ? 'Unknown' : nil,
                      races[:race_other] ? 'Other' : nil,
                      races[:race_refused_to_answer] ? 'Refused to Answer' : nil].reject(&:nil?).join(', ')
      )
    ].reject(&:nil?))
  end

  # Return a boolean indicating if the given race code is present on the given FHIR::Patient.
  def race_code?(patient, code, url, absent)
    race_extension = patient&.extension&.select { |e| e&.url&.include?('us-core-race') }&.first&.extension
    race_extension&.select { |e| e&.url == url }&.any? { |e| (absent ? e&.valueCode : e&.valueCoding&.code) == code }
  end

  # Build a FHIR US Core Ethnicity Extension given Sara Alert ethnicity information.
  def to_us_core_ethnicity(ethnicity)
    # Don't return an extension if no ethnicity specified
    return nil unless ValidationHelper::VALID_PATIENT_ENUMS[:ethnicity].include?(ethnicity)

    # Build out extension based on what ethnicity was specified
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity', extension: [
                          ethnicity == 'Hispanic or Latino' ? FHIR::Extension.new(
                            url: 'ombCategory',
                            valueCoding: FHIR::Coding.new(code: '2135-2', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Hispanic or Latino')
                          ) : nil,
                          ethnicity == 'Not Hispanic or Latino' ? FHIR::Extension.new(
                            url: 'ombCategory',
                            valueCoding: FHIR::Coding.new(code: '2186-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Not Hispanic or Latino')
                          ) : nil,
                          ethnicity == 'Unknown' ? FHIR::Extension.new(
                            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason',
                            valueCode: 'unknown'
                          ) : nil,
                          ethnicity == 'Refused to Answer' ? FHIR::Extension.new(
                            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason',
                            valueCode: 'asked-declined'
                          ) : nil,
                          FHIR::Extension.new(
                            url: 'text',
                            valueString: ethnicity
                          )
                        ])
  end

  # Return a string representing the ethnicity of the given FHIR::Patient
  def from_us_core_ethnicity(patient)
    urls = %w[ombCategory http://hl7.org/fhir/StructureDefinition/data-absent-reason]
    ethnicity = patient&.extension&.select { |e| e.url.include?('us-core-ethnicity') }&.first&.extension&.select { |e| urls.include?(e.url) }&.first
    code = ethnicity&.valueCoding&.code || ethnicity&.valueCode
    return 'Hispanic or Latino' if code == '2135-2'
    return 'Not Hispanic or Latino' if code == '2186-5'
    return 'Unknown' if code == 'unknown'
    return 'Refused to Answer' if code == 'asked-declined'

    code
  end

  # Build a FHIR US Core BirthSex Extension given Sara Alert sex information.
  def to_us_core_birthsex(sex)
    # Don't return an extension if no sex specified
    return nil unless %w[Male Female Unknown].include?(sex)

    # Build out extension based on what sex was specified
    code = sex == 'Unknown' ? 'UNK' : sex.first
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex', valueCode: code)
  end

  # Return a string representing the birthsex of the given FHIR::Patient
  def from_us_core_birthsex(patient)
    url = 'us-core-birthsex'
    code = patient&.extension&.select { |e| e.url.include?(url) }&.first&.valueCode
    return 'Male' if code == 'M'
    return 'Female' if code == 'F'
    return 'Unknown' if code == 'UNK'

    code
  end

  # Given a language string, try to find the corresponding BCP 47 code for it and construct a FHIR::Coding.
  def language_coding(language)
    PatientHelper.languages(language&.downcase) ? FHIR::Coding.new(**PatientHelper.languages(language&.downcase)) : nil
  end

  # Helper to understand a boolean extension
  def from_bool_extension(patient, extension_id)
    patient&.extension&.find { |e| e.url.include?(extension_id) }&.valueBoolean
  end

  def to_bool_extension(value, extension_id)
    value.nil? ? nil : FHIR::Extension.new(
      url: "http://saraalert.org/StructureDefinition/#{extension_id}",
      valueBoolean: value
    )
  end

  def to_date_extension(value, extension_id)
    value.nil? ? nil : FHIR::Extension.new(
      url: "http://saraalert.org/StructureDefinition/#{extension_id}",
      valueDate: value
    )
  end

  # Check for multiple extension IDs for the sake of backwards compatibility with IDs that have changed
  def from_date_extension(element, extension_ids)
    val = nil
    extension_ids.each do |eid|
      val = element&.extension&.select { |e| e.url.include?(eid) }&.first&.valueDate
      break unless val.nil?
    end
    val
  end

  def to_string_extension(value, extension_id)
    value.nil? || value.empty? ? nil : FHIR::Extension.new(
      url: "http://saraalert.org/StructureDefinition/#{extension_id}",
      valueString: value
    )
  end

  def from_string_extension(element, extension_id)
    element&.extension&.select { |e| e.url.include?(extension_id) }&.first&.valueString
  end

  def to_reference_extension(id, resource_type, extension_id)
    id.blank? ? nil : FHIR::Extension.new(
      url: "http://saraalert.org/StructureDefinition/#{extension_id}",
      valueReference: FHIR::Reference.new(reference: "#{resource_type}/#{id}")
    )
  end

  def to_positive_integer_extension(value, extension_id)
    value.nil? ? nil : FHIR::Extension.new(
      url: "http://saraalert.org/StructureDefinition/#{extension_id}",
      valuePositiveInt: value
    )
  end

  def from_positive_integer_extension(element, extension_id)
    element&.extension&.select { |e| e.url.include?(extension_id) }&.first&.valuePositiveInt
  end

  def to_unsigned_integer_extension(value, extension_id)
    value.nil? ? nil : FHIR::Extension.new(
      url: "http://saraalert.org/StructureDefinition/#{extension_id}",
      valueUnsignedInt: value
    )
  end

  def from_unsigned_integer_extension(element, extension_id)
    element&.extension&.select { |e| e.url.include?(extension_id) }&.first&.valueUnsignedInt
  end

  # Convert from FHIR extension for Full Assigned Jurisdiction Path.
  # Use the default if there is no path specified.
  def from_full_assigned_jurisdiction_path_extension(patient, default_jurisdiction_id)
    jurisdiction_path = from_string_extension(patient, 'full-assigned-jurisdiction-path')
    jurisdiction_path ? Jurisdiction.find_by(path: jurisdiction_path)&.id : default_jurisdiction_id
  end

  def from_primary_phone_type_extension(patient)
    phone_telecom = patient&.telecom&.select { |t| t&.system == 'phone' }&.first
    phone_telecom&.extension&.select { |e| e.url.include?('phone-type') }&.first&.valueString
  end

  def from_secondary_phone_type_extension(patient)
    phone_telecom = patient&.telecom&.select { |t| t&.system == 'phone' }&.second
    phone_telecom&.extension&.select { |e| e.url.include?('phone-type') }&.first&.valueString
  end

  def from_fhir_phone_number(value)
    Phonelib.parse(value, 'US').full_e164.presence || value
  end

  def to_statelocal_identifier(statelocal_identifier)
    FHIR::Identifier.new(value: statelocal_identifier, system: 'http://saraalert.org/SaraAlert/state-local-id') unless statelocal_identifier.blank?
  end

  def from_statelocal_id_extension(patient)
    statelocal_id = patient&.identifier&.find { |i| i&.system == 'http://saraalert.org/SaraAlert/state-local-id' }
    statelocal_id&.value
  end

  def to_address_by_type_extension(patient, address_type)
    case address_type
    when 'USA'
      FHIR::Address.new(
        line: [patient.address_line_1, patient.address_line_2].reject(&:blank?),
        city: patient.address_city,
        district: patient.address_county,
        state: patient.address_state,
        postalCode: patient.address_zip
      )
    when 'Foreign'
      [patient.foreign_address_line_1,
       patient.foreign_address_line_2,
       patient.foreign_address_line_3,
       patient.foreign_address_city,
       patient.foreign_address_country,
       patient.foreign_address_zip,
       patient.foreign_address_state].any? ?
      FHIR::Address.new(
        line: [patient.foreign_address_line_1, patient.foreign_address_line_2, patient.foreign_address_line_3].reject(&:blank?),
        city: patient.foreign_address_city,
        country: patient.foreign_address_country,
        state: patient.foreign_address_state,
        postalCode: patient.foreign_address_zip,
        extension: [FHIR::Extension.new(url: 'http://saraalert.org/StructureDefinition/address-type', valueString: 'Foreign')]
      ) : nil
    end
  end

  def from_address_by_type_extension(patient, address_type)
    address = patient&.address&.find do |a|
      a.extension&.any? { |e| e.url == 'http://saraalert.org/StructureDefinition/address-type' && e.valueString == address_type }
    end

    if address.nil? && address_type == 'USA'
      address = patient&.address&.find do |a|
        a.extension&.all? { |e| e.url != 'http://saraalert.org/StructureDefinition/address-type' }
      end
    end

    address
  end
end
