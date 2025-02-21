import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, ButtonGroup, Col, Dropdown, Form, Modal, OverlayTrigger, Row, ToggleButton, Tooltip } from 'react-bootstrap';
import Select, { components } from 'react-select';
import ReactTooltip from 'react-tooltip';
import { toast } from 'react-toastify';
import axios from 'axios';
import moment from 'moment-timezone';
import _ from 'lodash';

import DateInput from '../../util/DateInput';
import confirmDialog from '../../util/ConfirmDialog';
import { advancedFilterOptions } from '../../../data/advancedFilterOptions';

class AdvancedFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      activeFilter: null,
      activeFilterOptions: [],
      applied: false,
      filterName: null,
      lastAppliedFilter: null,
      savedFilters: [],
      showAdvancedFilterModal: false,
      showFilterNameModal: false,
    };
  }

  componentDidMount() {
    if (this.state.activeFilterOptions?.length === 0) {
      // Start with empty default
      this.addStatement();
    }

    // Set a timestamp to include in url to ensure browser cache is not re-used on page navigation
    const timestamp = `?t=${new Date().getTime()}`;

    // Grab saved filters
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios.get(window.BASE_PATH + '/user_filters' + timestamp).then(response => {
      this.setState({ savedFilters: response.data }, () => {
        // Apply filter if it exists in local storage
        let sessionFilter = this.getLocalStorage(`SaraFilter`);
        if (this.props.updateStickySettings && parseInt(sessionFilter)) {
          this.setFilter(
            this.state.savedFilters.find(filter => {
              return filter.id === parseInt(sessionFilter);
            }),
            true
          );
        }
      });
    });
  }

  /**
   * Start a new filter
   */
  newFilter = () => {
    this.setState({ activeFilterOptions: [], showAdvancedFilterModal: true, activeFilter: null, applied: false }, () => {
      this.addStatement();
    });
  };

  /**
   * Set the active filter
   * @param {Object} filter
   * @param {Bool} apply - only true when called from componentDidMount(), a flag to determine when the filter should be applied to the results
   *                         results & when other existing sticky settings/filter on the table should persist
   */
  setFilter = (filter, apply = false) => {
    if (filter) {
      this.setState({ activeFilter: filter, showAdvancedFilterModal: true, activeFilterOptions: filter?.contents || [] }, () => {
        if (apply) {
          this.apply(true);
        }
      });
    }
  };

  /**
   * Apply the current filter (updates the dashboard table)
   * @param {Boolean} keepStickySettings - Update local storage with filter being applied
   */
  apply = keepStickySettings => {
    const appliedFilter = {
      activeFilter: this.state.activeFilter,
      activeFilterOptions: _.cloneDeep(this.state.activeFilterOptions),
    };
    this.setState({ showAdvancedFilterModal: false, applied: true, lastAppliedFilter: appliedFilter }, () => {
      this.props.advancedFilterUpdate(this.state.activeFilterOptions, keepStickySettings);
      if (this.props.updateStickySettings && this.state.activeFilter) {
        this.setLocalStorage(`SaraFilter`, this.state.activeFilter.id);
      }
    });
  };

  /**
   * Reset main advanced filter modal when cancelled
   * Reverts modal to initial state if there is not a filer applied or the last applied filter
   */
  cancel = () => {
    const applied = this.state.applied;
    const activeFilter = applied ? this.state.lastAppliedFilter.activeFilter : null;
    const activeFilterOptions = applied ? this.state.lastAppliedFilter.activeFilterOptions : [];
    this.setState({ showAdvancedFilterModal: false, applied, activeFilter, activeFilterOptions }, () => {
      // if no filter was applied, start again with empty default
      if (!applied) {
        this.addStatement();
      }
    });
  };

  /**
   * Clears the current applied filter (saved or unsaved)
   * Resets the advanced filter modal and dashboard table
   */
  clear = () => {
    this.setState({ activeFilterOptions: [], show: false, activeFilter: null, applied: false }, () => {
      this.addStatement();
      this.props.advancedFilterUpdate(this.state.activeFilter, false);
      if (this.props.updateStickySettings) {
        this.setLocalStorage(`SaraFilter`, null);
      }
    });
  };

  /**
   * Delete an existing saved filter from the database
   * Resets modal to initial state
   */
  delete = () => {
    let self = this;
    const id = this.state.activeFilter.id;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .delete(window.BASE_PATH + '/user_filters/' + id)
      .catch(() => {
        toast.error('Failed to delete filter.');
      })
      .then(() => {
        toast.success('Filter successfully deleted.');
        if (this.props.updateStickySettings) {
          this.removeLocalStorage(`SaraFilter`);
        }
        this.setState(
          {
            savedFilters: [
              ...self.state.savedFilters.filter(filter => {
                return filter.id != id;
              }),
            ],
          },
          () => {
            this.clear();
          }
        );
      });
  };

  /**
   * Resets modal to initial state
   */
  reset = async () => {
    if (await confirmDialog('Are you sure you want to reset this filter? Anything currently configured will be lost.')) {
      this.newFilter();
    }
  };

  /**
   * Saves a new filter to the database
   */
  save = () => {
    let self = this;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/user_filters', { activeFilterOptions: this.state.activeFilterOptions, name: this.state.filterName })
      .catch(err => {
        toast.error(err?.response?.data?.error ? err.response.data.error : 'Failed to save filter.', {
          autoClose: 8000,
        });
      })
      .then(response => {
        if (response?.data) {
          toast.success('Filter successfully saved.');
          let data = { ...response?.data, contents: JSON.parse(response?.data?.contents) };
          this.setState({ activeFilter: data, savedFilters: [...self.state.savedFilters, data] });
        }
      });
  };

  /**
   * Updates an existing saved filter to the database
   */
  update = () => {
    let self = this;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .put(window.BASE_PATH + '/user_filters/' + this.state.activeFilter.id, { activeFilterOptions: this.state.activeFilterOptions })
      .catch(() => {
        toast.error('Failed to update filter.');
      })
      .then(response => {
        if (response?.data) {
          toast.success('Filter successfully updated.');
          let data = { ...response?.data, contents: JSON.parse(response?.data?.contents) };
          this.setState({
            activeFilter: data,
            savedFilters: [
              ...self.state.savedFilters.filter(filter => {
                return filter.id != data.id;
              }),
              data,
            ],
          });
        }
      });
  };

  /**
   * Adds a new filter statement to the end of the existing list of current filter statements
   */
  addStatement = () => {
    this.setState(state => ({
      activeFilterOptions: [...state.activeFilterOptions, { filterOption: null }],
    }));
  };

  /**
   * Removes the filter statement at certain index
   * @param {Number} index - Current filter index
   */
  removeStatement = index => {
    this.setState(state => ({
      activeFilterOptions: state.activeFilterOptions.slice(0, index).concat(state.activeFilterOptions.slice(index + 1, state.activeFilterOptions?.length)),
    }));
  };

  /**
   * Change the main filter option dropdown
   * @param {Number} index - Current filter index
   * @param {String} name - Current filter name
   */
  changeFilterOption = (index, name) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    let filterOption = advancedFilterOptions.find(filterOption => {
      return filterOption.name === name;
    });

    // Figure out dummy value for the picked type
    let value = null;
    if (filterOption.type === 'boolean') {
      value = true;
    } else if (filterOption.type === 'select') {
      value = filterOption.options[0];
    } else if (filterOption.type === 'number') {
      value = 0;
    } else if (filterOption.type === 'date') {
      // Default to "within" type
      value = {
        start: moment()
          .add(-72, 'hours')
          .format('YYYY-MM-DD'),
        end: moment().format('YYYY-MM-DD'),
      };
    } else if (filterOption.type === 'relative') {
      value = 'today';
    } else if (filterOption.type === 'search') {
      value = '';
    }

    activeFilterOptions[parseInt(index)] = {
      filterOption,
      value,
      numberOption: filterOption.type === 'number' ? 'equal' : null,
      dateOption: filterOption.type === 'date' ? 'within' : null,
      relativeOption: filterOption.type === 'relative' ? 'today' : null,
      additionalFilterOption: filterOption.type !== 'select' && filterOption.options ? filterOption.options[0] : null,
    };
    this.setState({ activeFilterOptions });
  };

  /**
   * Change the main number option for type number
   * @param {Number} index - Current filter index
   * @param {String} prevNumberOption - numberOption value from before change
   * @param {String} newNumberOption - numberOption value from after change
   * @param {String} value - Value of the current number type statement
   * @param {String} additionalFilterOption - Current additionalFilterOption value
   */
  // Change an index filter option for type number
  changeFilterNumberOption = (index, prevNumberOption, newNumberOption, value, additionalFilterOption) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    let newValue = value;
    if (prevNumberOption === 'between' && newNumberOption !== 'between') {
      newValue = 0;
    } else if (prevNumberOption !== 'between' && newNumberOption === 'between') {
      newValue = { firstBound: 0, secondBound: 0 };
    }
    activeFilterOptions[parseInt(index)] = {
      filterOption: activeFilterOptions[parseInt(index)].filterOption,
      value: newValue,
      numberOption: newNumberOption,
      additionalFilterOption,
      dateOption: null,
      relativeOption: null,
    };
    this.setState({ activeFilterOptions });
  };

  /**
   * Change the main date option for type date
   * @param {Number} index - Current filter index
   * @param {String} dateOption - Current dateOption value
   */
  changeFilterDateOption = (index, dateOption) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    let defaultValue = null;
    if (dateOption === 'within') {
      defaultValue = {
        start: moment()
          .subtract(3, 'days')
          .format('YYYY-MM-DD'),
        end: moment().format('YYYY-MM-DD'),
      };
    } else {
      defaultValue = moment().format('YYYY-MM-DD');
    }
    activeFilterOptions[parseInt(index)] = {
      filterOption: activeFilterOptions[parseInt(index)].filterOption,
      value: defaultValue,
      dateOption,
      numberOption: null,
      relativeOption: null,
      additionalFilterOption: null,
    };
    this.setState({ activeFilterOptions });
  };

  /**
   * Change the main relative filter option for type relative date
   * @param {Number} index - Current filter index
   * @param {String} relativeOption - Current relativeOption value
   */
  changeFilterRelativeOption = (index, relativeOption) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    let defaultValue = relativeOption === 'custom' ? { operator: 'less-than', number: 1, unit: 'days', when: 'past' } : relativeOption;
    activeFilterOptions[parseInt(index)] = {
      filterOption: activeFilterOptions[parseInt(index)].filterOption,
      value: defaultValue,
      relativeOption,
      dateOption: null,
      numberOption: null,
      additionalFilterOption: null,
    };
    this.setState({ activeFilterOptions });
  };

  /**
   * Change the additional filter option supported for different types if provided
   * @param {Number} index - Current filter index
   * @param {String} additionalFilterOption - Current additionalFilterOption value
   * @param {*} value - Current filter value
   * @param {String} numberOption - Current numberOption value (could be null depending on filter statement type)
   * @param {String} dateOption - Current dateOption value (could be null depending on filter statement type)
   * @param {String} relativeOption - Current relativeOption value (could be null depending on filter statement type)
   */
  changeFilterAdditionalFilterOption = (index, additionalFilterOption, value, numberOption, dateOption, relativeOption) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    // add all other options here
    activeFilterOptions[parseInt(index)] = {
      filterOption: activeFilterOptions[parseInt(index)].filterOption,
      value,
      additionalFilterOption,
      numberOption,
      dateOption,
      relativeOption,
    };
    this.setState({ activeFilterOptions });
  };

  /**
   * Change value of a filter statement
   * @param {Number} index - Current filter index
   * @param {*} value - Current filter value
   */
  changeValue = (index, value) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    activeFilterOptions[parseInt(index)]['value'] = value;
    this.setState({ activeFilterOptions });
  };

  /**
   * Gets the string inside the tooltip for relative date filter options.
   * @param {Object} filter - Filter currently selected
   * @param {Object} value - Filter value (object containing number, unit, operator and when)
   */
  getRelativeTooltipString(filter, value) {
    const filterName = filter.title.replace(' (Relative Date)', '');
    let before, after;
    let statement = '';
    const operatorValue = value.operator.replace('-', ' ');

    if (value.operator === 'more-than') {
      if (value.when === 'past') {
        before = moment()
          .subtract(value.number, value.unit)
          .format('MM/DD/YY');
      } else {
        after = moment()
          .add(value.number, value.unit)
          .format('MM/DD/YY');
      }
    } else if (value.operator === 'less-than') {
      // set variables for date options including a time stamp
      if (filter.hasTimestamp) {
        if (value.when === 'past') {
          after = moment()
            .subtract(value.number, value.unit)
            .format('MM/DD/YY');
          before = 'now';
        } else {
          after = 'now';
          before = moment()
            .add(value.number, value.unit)
            .format('MM/DD/YY');
        }
      }

      // set variables for date options without a timestamp
      else {
        if (value.when === 'past') {
          after = moment()
            .subtract(value.number, value.unit)
            .add(1, 'days')
            .format('MM/DD/YY');
          before = moment().format('MM/DD/YY');
        } else {
          after = moment().format('MM/DD/YY');
          before = moment()
            .add(value.number, value.unit)
            .subtract(1, 'days')
            .format('MM/DD/YY');
        }
      }
    }

    statement += `The current setting of "${operatorValue} ${value.number} ${value.unit} in the ${value.when}" will return records with ${filterName} date`;
    if (value.operator === 'less-than') {
      const timestampString = filter.hasTimestamp ? 'the current time on ' : '';
      if (!filter.hasTimestamp && value.number === 1 && value.unit === 'days') {
        statement += ' of today. ';
      } else {
        if (value.when === 'past') {
          statement += ` from ${timestampString}${after} through ${before}. `;
        } else {
          statement += ` from ${after} through ${timestampString}${before}. `;
        }
      }
    } else {
      const timestampString = filter.hasTimestamp ? 'the current time on ' : '';
      if (value.when === 'past') {
        statement += ` before ${timestampString}${before}. `;
      } else {
        statement += ` after ${timestampString}${after}. `;
      }
    }
    statement += `To filter between two dates, use the "more than" and "less than" filters in combination.`;
    return statement;
  }

  /**
   * Renders a tooltip for a statement row
   * @param {Object} filter - Filter currently selected
   * @param {Number} index - Filter index
   * @param {String} statement - Tooltip text
   */
  renderStatementTooltip = (filter, index, statement) => {
    const tooltipId = `${filter.name}-${index}`;
    return (
      <div className="align-middle float-right">
        <span data-for={tooltipId} data-tip="" className="ml-3 tooltip-af">
          <i className="fas fa-question-circle px-0"></i>
        </span>
        <ReactTooltip id={tooltipId} multiline={true} place="bottom" type="dark" effect="solid" className="tooltip-container">
          <span>{statement}</span>
        </ReactTooltip>
      </div>
    );
  };

  /**
   * Renders remove statement button (minus button at far right of statement)
   * @param {Number} index - Filter index
   */
  renderRemoveStatementButton = index => {
    return (
      <div className="float-right">
        <Button className="remove-filter-row" variant="danger" onClick={() => this.removeStatement(index)} aria-label="Remove Advanced Filter Option">
          <i className="fas fa-minus"></i>
        </Button>
      </div>
    );
  };

  /**
   * Format options for main select dropdown
   */
  getFormattedOptions = () => {
    return advancedFilterOptions
      .sort((a, b) => {
        if (a.type === 'blank') return -1;
        if (b.type === 'blank') return 1;
        return a.title.localeCompare(b.title);
      })
      .map(option => {
        return {
          label: option.title,
          subLabel: option.description,
          value: option.name,
          disabled: option.type === 'blank',
        };
      });
  };

  /**
   * Render the options for the select that represents fields to filter on
   * @param {String} current - Name of currently selected filter
   * @param {Number} index - Filter index
   */
  renderOptions = (current, index) => {
    const selectedValue = this.getFormattedOptions().find(option => {
      return option.value === current;
    });
    const Option = props => {
      return (
        <components.Option {...props}>
          <div>{props.data.label}</div>
          <div style={{ fontSize: 12 }}>{props.data.subLabel}</div>
        </components.Option>
      );
    };
    return (
      <Select
        options={this.getFormattedOptions()}
        value={selectedValue || null}
        isOptionDisabled={option => option.disabled}
        components={{ Option }}
        onChange={event => {
          this.changeFilterOption(index, event?.value);
        }}
        placeholder="Select Field...."
        aria-label="Advanced Filter Options Dropdown"
        className="advanced-filter-select"
        theme={theme => ({
          ...theme,
          borderRadius: 0,
        })}
      />
    );
  };

  /**
   * Renders additional filter option dropdown that is used in conjunction with other advanced filter types
   * @param {String} current - Selected option from additional list of options (if provided)
   * @param {Number} index - Filter index
   * @param {String[]} options - List of additional options provided for the dropdown
   * @param {*} value - Current value for the associated statement (could be any type)
   * @param {String} numberOption - Selected option for number filters that is possibly associated with this statement
   * @param {String} dateOption - Selected option for date filters that is possibly associated with this statement
   * @param {String} relativeOption - Selected option for relative date filters that is possibly associated with this statement
   */
  renderAdditionalFilterOptions = (current, index, options, value, numberOption, dateOption, relativeOption) => {
    return (
      <Form.Control
        as="select"
        value={current}
        className="advanced-filter-additional-filter-options py-0 my-0 mr-3"
        aria-label="Advanced Filter Number Additional Options Input"
        onChange={event => this.changeFilterAdditionalFilterOption(index, event.target.value, value, numberOption, dateOption, relativeOption)}>
        {options.map((option, op_index) => {
          return (
            <option key={index + 'opkeyop-f' + op_index} value={option}>
              {option}
            </option>
          );
        })}
      </Form.Control>
    );
  };

  /**
   * Renders boolean type line "statement"
   * @param {Object} filterOption - Filter currently selected
   * @param {Number} index - Filter index
   * @param {Boolean} value - Current value selected in the toggle buttons
   */
  renderBooleanStatement = (filter, index, value) => {
    return (
      <React.Fragment>
        <ButtonGroup toggle>
          <ToggleButton
            type="checkbox"
            className="advanced-filter-boolean-true"
            aria-label="Advanced Filter Boolean True"
            variant="outline-primary"
            checked={value}
            value="1"
            onChange={() => {
              this.changeValue(index, !value);
            }}>
            TRUE
          </ToggleButton>
          <ToggleButton
            type="checkbox"
            className="advanced-filter-boolean-false"
            aria-label="Advanced Filter Boolean False"
            variant="outline-primary"
            checked={!value}
            value="0"
            onChange={() => {
              this.changeValue(index, !value);
            }}>
            FALSE
          </ToggleButton>
        </ButtonGroup>
        {filter.tooltip && this.renderStatementTooltip(filter.name, index, filter.tooltip)}
      </React.Fragment>
    );
  };

  /**
   * Renders search/text type line "statement"
   * @param {Object} filterOption - Filter currently selected
   * @param {Number} index - Filter index
   * @param {String} value - Current text string in the input
   * @param {String} additionalFilterOption - Selected option from additional list of options (if provided)
   */
  renderSearchStatement = (filter, index, value, additionalFilterOption) => {
    // compute tooltip for specific search case
    let tooltip;
    if (filter.name === 'close-contact-with-known-case-id') {
      if (additionalFilterOption === 'Exact Match') {
        tooltip =
          'Returns records with an exact match to one or more of the user-entered search values when the known Case ID is specified for monitorees with “Close Contact with a Known Case”. Use commas to separate multiple values (ex: “12, 45” will return records where known Case ID is “45” or “45, 12”).';
      } else if (additionalFilterOption === 'Contains') {
        tooltip =
          'Returns records that contain a user-entered search value when the known Case ID is specified for monitorees with “Close Contact with a Known Case”. Use commas to separate multiple values (ex: “12, 45” will return records where known Case ID is “123, 90” or “12” or “1451).';
      }
    }

    return (
      <React.Fragment>
        <div style={{ display: 'flex' }}>
          <Form.Control
            as="input"
            value={value}
            className="advanced-filter-search-input py-0 my-0"
            aria-label="Advanced Filter Search Text Input"
            onChange={event => {
              this.changeValue(index, event.target.value);
            }}
          />
          {tooltip && this.renderStatementTooltip(filter.name, index, tooltip)}
        </div>
      </React.Fragment>
    );
  };

  /**
   * Renders dropdown select type line "statement"
   * @param {Object} filterOption - Filter currently selected
   * @param {Number} index - Filter index
   * @param {String} value - Current value selected in the dropdown
   */
  renderSelectStatement = (filter, index, value) => {
    return (
      <React.Fragment>
        <Form.Control
          as="select"
          value={value}
          className="advanced-filter-select-dropdown py-0 my-0"
          aria-label="Advanced Filter Option Select"
          onChange={event => {
            this.changeValue(index, event.target.value);
          }}>
          {filter.options.map((option, op_index) => {
            return (
              <option key={index + 'opkeyop-f' + op_index} value={option}>
                {option}
              </option>
            );
          })}
        </Form.Control>
      </React.Fragment>
    );
  };

  /**
   * Renders number type line "statement"
   * @param {Object} filterOption - Filter currently selected
   * @param {Number} index - Filter index
   * @param {*} value - Current value for this statement (could be an integer or object of integers)
   * @param {String} numberOption - Selected option for number filters that determines what else is rendered in this statement
   * @param {String} additionalFilterOption - Selected option from additional list of options (if provided)
   */
  renderNumberStatement = (filter, index, value, numberOption, additionalFilterOption) => {
    const betweenTooltipText = '"Between" is inclusive and will filter for values within the user-entered range, including the start and end values.';
    return (
      <React.Fragment>
        <Form.Group className="form-group-inline py-0 my-0">
          <Form.Control
            as="select"
            value={numberOption}
            className="advanced-filter-number-options mr-3"
            aria-label="Advanced Filter Number Select Options"
            onChange={event => this.changeFilterNumberOption(index, numberOption, event.target.value, value, additionalFilterOption)}>
            <option value="less-than">less than</option>
            <option value="less-than-equal">less than or equal to</option>
            <option value="equal">equal to</option>
            <option value="greater-than-equal">greater than or equal to</option>
            <option value="greater-than">greater than</option>
            {filter.allowRange && <option value="between">between</option>}
          </Form.Control>
          {numberOption !== 'between' && (
            <Form.Control
              className="advanced-filter-number-input"
              aria-label="Advanced Filter Number Input"
              value={value}
              type="number"
              min="0"
              onChange={event => this.changeValue(index, event?.target?.value)}
            />
          )}
          {numberOption === 'between' && (
            <React.Fragment>
              <Form.Control
                className="advanced-filter-number-input"
                aria-label="Advanced Filter Number Input Bound 1"
                value={value.firstBound}
                type="number"
                min="0"
                onChange={event => this.changeValue(index, { firstBound: event?.target?.value, secondBound: value.secondBound })}
              />
              <div className="text-center my-auto mx-4">
                <b>AND</b>
              </div>
              <Form.Control
                className="advanced-filter-number-input"
                aria-label="Advanced Filter Number Input Bound 2"
                value={value.secondBound}
                type="number"
                min="0"
                onChange={event => this.changeValue(index, { firstBound: value.firstBound, secondBound: event?.target?.value })}
              />
            </React.Fragment>
          )}
        </Form.Group>
        {numberOption === 'between' && this.renderStatementTooltip(filter.name, index, betweenTooltipText)}
      </React.Fragment>
    );
  };

  /**
   * Renders date type line "statement"
   * @param {Number} index - Filter index
   * @param {*} value - Current value for this statement (could be a single date or object of dates)
   * @param {String} dateOption - Selected option for date filters that determines what else is rendered in this statement
   */
  renderDateStatement = (index, value, dateOption) => {
    return (
      <React.Fragment>
        <Form.Group className="form-group-inline py-0 my-0">
          <Form.Control
            as="select"
            value={dateOption}
            className="advanced-filter-date-options py-0 my-0 mr-4"
            aria-label="Advanced Filter Date Select Options"
            onChange={event => {
              this.changeFilterDateOption(index, event.target.value);
            }}>
            <option value="within">within</option>
            <option value="before">before</option>
            <option value="after">after</option>
          </Form.Control>
          {dateOption !== 'within' && (
            <div className="advanced-filter-date-input">
              <DateInput
                date={value}
                onChange={date => {
                  this.changeValue(index, date);
                }}
                placement="bottom"
                customClass="form-control-md"
                ariaLabel="Advanced Filter Date Input"
                minDate={'1900-01-01'}
                maxDate={moment()
                  .add(2, 'years')
                  .format('YYYY-MM-DD')}
                replaceBlank={true}
              />
            </div>
          )}
          {dateOption === 'within' && (
            <React.Fragment>
              <div className="advanced-filter-date-input">
                <DateInput
                  date={value.start}
                  onChange={date => {
                    this.changeValue(index, { start: date, end: value.end });
                  }}
                  placement="bottom"
                  customClass="form-control-md"
                  ariaLabel="Advanced Filter Start Date Input"
                  minDate={'1900-01-01'}
                  maxDate={moment()
                    .add(2, 'years')
                    .format('YYYY-MM-DD')}
                  replaceBlank={true}
                />
              </div>
              <div className="text-center my-auto mx-4">
                <b>TO</b>
              </div>
              <div className="advanced-filter-date-input">
                <DateInput
                  date={value.end}
                  onChange={date => {
                    this.changeValue(index, { start: value.start, end: date });
                  }}
                  placement="bottom"
                  customClass="form-control-md"
                  ariaLabel="Advanced Filter End Date Input"
                  minDate={'1900-01-01'}
                  maxDate={moment()
                    .add(2, 'years')
                    .format('YYYY-MM-DD')}
                  replaceBlank={true}
                />
              </div>
            </React.Fragment>
          )}
        </Form.Group>
      </React.Fragment>
    );
  };

  /**
   * Renders relative date type line "statement"
   * @param {Object} filter - Filter currently selected
   * @param {Number} index - Filter index
   * @param {*} value - Current value for relative date filter (Object containing number, unit, operator and when if custom and just the relativeOption if not)
   * @param {String} relativeOption - Selected option for relative date filters that determines what else is rendered in this statement
   */
  renderRelativeDateStatement = (filter, index, value, relativeOption) => {
    return (
      <React.Fragment>
        <Form.Group className="form-group-inline py-0 my-0">
          <Form.Control
            as="select"
            value={relativeOption}
            className="advanced-filter-relative-options py-0 my-0 mr-3"
            aria-label="Advanced Filter Relative Date Select Options"
            onChange={event => {
              this.changeFilterRelativeOption(index, event.target.value);
            }}>
            <option value="today">today</option>
            <option value="tomorrow">tomorrow</option>
            <option value="yesterday">yesterday</option>
            <option value="custom">custom</option>
          </Form.Control>
          {relativeOption === 'custom' && (
            <Row>
              <Form.Control
                as="select"
                value={value.operator}
                className="advanced-filter-operator-input mx-3"
                aria-label="Advanced Filter Relative Date Operator Select"
                onChange={event => {
                  this.changeValue(index, { operator: event.target.value, number: value.number, unit: value.unit, when: value.when });
                }}>
                <option value="less-than">less than</option>
                <option value="more-than">more than</option>
              </Form.Control>
              <Form.Control
                value={value.number}
                className="advanced-filter-number-input"
                aria-label="Advanced Filter Relative Date Number Select"
                type="number"
                min="1"
                onChange={event => this.changeValue(index, { operator: value.operator, number: event.target.value, unit: value.unit, when: value.when })}
              />
              <Form.Control
                as="select"
                value={value.unit}
                className="advanced-filter-unit-input mx-3"
                aria-label="Advanced Filter Relative Date Unit Select"
                onChange={event => {
                  this.changeValue(index, { operator: value.operator, number: value.number, unit: event.target.value, when: value.when });
                }}>
                <option value="days">day(s)</option>
                <option value="weeks">week(s)</option>
                <option value="months">month(s)</option>
              </Form.Control>
              <Form.Control
                as="select"
                value={value.when}
                className="advanced-filter-when-input"
                aria-label="Advanced Filter Relative Date When Select"
                onChange={event => {
                  this.changeValue(index, { operator: value.operator, number: value.number, unit: value.unit, when: event.target.value });
                }}>
                <option value="past">in the past</option>
                {!filter.hasTimestamp && <option value="future">in the future</option>}
              </Form.Control>
            </Row>
          )}
        </Form.Group>
        {relativeOption === 'custom' && this.renderStatementTooltip(filter.name, index, this.getRelativeTooltipString(filter, value))}
      </React.Fragment>
    );
  };

  /**
   * Renders a single line "statement"
   * @param {Object} filterOption - Filter currently selected
   * @param {*} value - Current value for this statement (could be a string, bool, date or object)
   * @param {Number} index - Filter index
   * @param {Number} total - Total number of filters currently added
   * @param {String} numberOption - Selected option for number filters that determines what else is rendered in the statement
   * @param {String} dateOption - Selected option for date filters that determines what else is rendered in the statement
   * @param {String} relativeOption - Selected option for relative date filters that determines what else is rendered in the statement
   * @param {String} additionalFilterOption - Selected option from additional list of options (if provided)
   */
  renderStatement = (filterOption, value, index, total, numberOption, dateOption, relativeOption, additionalFilterOption) => {
    return (
      <React.Fragment key={'rowkey-filter-p' + index}>
        {index > 0 && index < total && (
          <Row key={'rowkey-filter-and' + index} className="and-row py-2">
            <Col className="py-0">
              <b>AND</b>
            </Col>
          </Row>
        )}
        <Row key={'rowkey-filter' + index} className="advanced-filter-statement pb-1 pt-1">
          <Col className="py-0" md={8}>
            {this.renderOptions(filterOption?.name, index)}
          </Col>
          {/* specific dropdown for filters with a type that requires additional options (not type option) */}
          {filterOption?.type !== 'select' && filterOption?.options && (
            <Col className="pl-0" md={4}>
              {this.renderAdditionalFilterOptions(additionalFilterOption, index, filterOption.options, value, numberOption, dateOption, relativeOption)}
            </Col>
          )}
          <Col className="p-0">
            {filterOption?.type === 'boolean' && this.renderBooleanStatement(filterOption, index, value)}
            {filterOption?.type === 'search' && this.renderSearchStatement(filterOption, index, value, additionalFilterOption)}
            {filterOption?.type === 'select' && this.renderSelectStatement(filterOption, index, value)}
            {filterOption?.type === 'number' && this.renderNumberStatement(filterOption, index, value, numberOption, additionalFilterOption)}
            {filterOption?.type === 'date' && this.renderDateStatement(index, value, dateOption)}
            {filterOption?.type === 'relative' && this.renderRelativeDateStatement(filterOption, index, value, relativeOption)}
          </Col>
          <Col className="py-0" md="auto">
            {this.renderRemoveStatementButton(index)}
          </Col>
        </Row>
      </React.Fragment>
    );
  };

  /**
   * Renders main advanced filter modal
   */
  renderAdvancedFilterModal = () => {
    return (
      <Modal
        id="advanced-filter-modal"
        show={this.state.showAdvancedFilterModal}
        centered
        dialogClassName="modal-af"
        className="advanced-filter-modal-container"
        onHide={this.cancel}>
        <Modal.Header>
          <Modal.Title>Advanced Filter: {this.state.activeFilter ? this.state.activeFilter.name : 'untitled'}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row className="pb-2 pt-1">
            <Col>
              {!this.state.activeFilter && (
                <Button
                  id="advanced-filter-save"
                  variant="primary"
                  onClick={() => {
                    this.setState({ showFilterNameModal: true, showAdvancedFilterModal: false });
                  }}
                  className="mr-1">
                  <i className="fas fa-save"></i>
                  <span className="ml-1">Save</span>
                </Button>
              )}
              {this.state.activeFilter && (
                <Button id="advanced-filter-update" variant="primary" onClick={this.update} className="mr-1">
                  <i className="fas fa-marker"></i>
                  <span className="ml-1">Update</span>
                </Button>
              )}
              {this.state.activeFilter && (
                <Button id="advanced-filter-delete" variant="danger" onClick={this.delete} disabled={!this.state.activeFilter}>
                  <i className="fas fa-trash"></i>
                  <span className="ml-1">Delete</span>
                </Button>
              )}
              <div className="float-right">
                <Button id="advanced-filter-reset" variant="danger" onClick={this.reset}>
                  Reset
                </Button>
              </div>
            </Col>
          </Row>
          <Row>
            <Col className="pb-3 pt-1">
              <div className="g-border-bottom-2"></div>
            </Col>
          </Row>
          {this.state.activeFilterOptions?.map((statement, index) => {
            return this.renderStatement(
              statement.filterOption,
              statement.value,
              index,
              this.state.activeFilterOptions?.length,
              statement.numberOption,
              statement.dateOption,
              statement.relativeOption,
              statement.additionalFilterOption
            );
          })}
          <Row className="pt-2 pb-1">
            <Col>
              <Button
                id="add-filter-row"
                variant="primary"
                disabled={this.state.activeFilterOptions?.length > 4}
                onClick={() => this.addStatement()}
                aria-label="Add Advanced Filter Option">
                <i className="fas fa-plus"></i>
              </Button>
            </Col>
          </Row>
        </Modal.Body>
        <Modal.Footer className="justify-unset">
          <p className="lead mr-auto">
            Filter will be applied to the line lists in the <u>{this.props.workflow}</u> workflow until reset.
          </p>
          <Button id="advanced-filter-cancel" variant="secondary btn-square" onClick={this.cancel}>
            Cancel
          </Button>
          <Button
            id="advanced-filter-apply"
            variant="primary"
            className="ml-2"
            onClick={() => {
              this.apply(false);
            }}>
            Apply
          </Button>
        </Modal.Footer>
      </Modal>
    );
  };

  /**
   * Renders modal to specify filter name (for saved filters)
   */
  renderFilterNameModal = () => {
    return (
      <Modal
        id="filter-name-modal"
        show={this.state.showFilterNameModal}
        centered
        className="advanced-filter-modal-container"
        onHide={() => {
          this.setState({ showFilterNameModal: false });
        }}>
        <Modal.Header>
          <Modal.Title>Filter Name</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form.Control
            id="filter-name-input"
            as="input"
            value={this.state.filterName || ''}
            className="py-0 my-0"
            onChange={event => {
              this.setState({ filterName: event.target.value });
            }}
          />
        </Modal.Body>
        <Modal.Footer>
          <Button
            id="filter-name-cancel"
            variant="secondary btn-square"
            onClick={() => {
              this.setState({ showFilterNameModal: false, showAdvancedFilterModal: true, filterName: null });
            }}>
            Cancel
          </Button>
          <Button
            id="filter-name-save"
            variant="primary btn-square"
            disabled={!this.state.filterName}
            onClick={() => {
              this.setState({ showFilterNameModal: false, showAdvancedFilterModal: true }, () => {
                this.save();
              });
            }}>
            Save
          </Button>
        </Modal.Footer>
      </Modal>
    );
  };

  /**
   * Get a local storage value
   * @param {String} key - relevant local storage key
   */
  getLocalStorage = key => {
    // It's rare this is needed, but we want to make sure we won't fail on Firefox's NS_ERROR_FILE_CORRUPTED
    try {
      return localStorage.getItem(key);
    } catch (error) {
      console.error(error);
      return null;
    }
  };

  /**
   * Set a local storage value
   * @param {String} key - relevant local storage key
   * @param {String} value - value to set
   */
  setLocalStorage = (key, value) => {
    // It's rare this is needed, but we want to make sure we won't fail on Firefox's NS_ERROR_FILE_CORRUPTED
    try {
      localStorage.setItem(key, value);
    } catch (error) {
      console.error(error);
    }
  };

  /**
   * Remove a local storage value
   * @param {String} key - relevant local storage key
   */
  removeLocalStorage = key => {
    // It's rare this is needed, but we want to make sure we won't fail on Firefox's NS_ERROR_FILE_CORRUPTED
    try {
      localStorage.removeItem(key);
    } catch (error) {
      console.error(error);
    }
  };

  render() {
    return (
      <React.Fragment>
        {this.state.showAdvancedFilterModal && this.renderAdvancedFilterModal()}
        {this.state.showFilterNameModal && this.renderFilterNameModal()}
        <OverlayTrigger overlay={<Tooltip>Find monitorees that meet specified parameters within current workflow</Tooltip>}>
          <Button
            size="sm"
            className="ml-2"
            onClick={() => {
              this.setState({ showAdvancedFilterModal: true });
            }}>
            <i className="fas fa-microscope"></i>
            <span className="ml-1">Advanced Filter</span>
          </Button>
        </OverlayTrigger>
        <Dropdown>
          <Dropdown.Toggle variant="outline-secondary" size="sm" className="advanced-filter-dropdown" aria-label="Advance Filter Dropdown Menu">
            {this.state.applied && (this.state.activeFilter?.name || 'untitled')}
          </Dropdown.Toggle>
          <Dropdown.Menu alignRight>
            <Dropdown.Item href="#" onClick={this.newFilter}>
              <i className="fas fa-plus fa-fw"></i>
              <span className="ml-2">New filter</span>
            </Dropdown.Item>
            {this.state.applied && (
              <React.Fragment>
                <Dropdown.Divider />
                <Dropdown.Item href="#" onClick={this.clear}>
                  <i className="fas fa-times fa-fw"></i>
                  <span className="ml-2">Clear current filter</span>
                </Dropdown.Item>
              </React.Fragment>
            )}
            <Dropdown.Divider />
            <Dropdown.Header>Saved Filters</Dropdown.Header>
            {this.state.savedFilters?.map((filter, index) => {
              return (
                <Dropdown.Item href="#" key={`di${index}`} onClick={() => this.setFilter(filter)}>
                  {filter.name}
                </Dropdown.Item>
              );
            })}
          </Dropdown.Menu>
        </Dropdown>
      </React.Fragment>
    );
  }
}

AdvancedFilter.propTypes = {
  authenticity_token: PropTypes.string,
  advancedFilterUpdate: PropTypes.func,
  workflow: PropTypes.string,
  updateStickySettings: PropTypes.bool,
};

export default AdvancedFilter;
