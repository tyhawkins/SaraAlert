import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Button } from 'react-bootstrap';
import RiskStratificationTable from './widgets/RevisedDashboard/RiskStratificationTable';
import MonitoreeFlow from './widgets/RevisedDashboard/MonitoreeFlow';
import AgeStratificationActive from './widgets/RevisedDashboard/AgeStratificationActive';
import Demographics from './widgets/RevisedDashboard/Demographics';
import moment from 'moment';

class RevisedMonitorAnalytics extends React.Component {
  constructor(props) {
    super(props);
  }
  render() {
    return (
      <React.Fragment>
        <Row className="text-left mb-4">
          <Col>
            <Button variant="primary" className="ml-2 btn-square" onClick={this.handleClick}>
              EXPORT ANALYSIS AS PNG
            </Button>
          </Col>
          <Col className="text-right">
            <span className="display-6 pt-3"> Last Updated At: {moment(this.props.stats.last_updated_at).format('YYYY-MM-DD HH:mm:ss')} </span>
          </Col>
        </Row>
        <Row className="mb-4">
          <Col lg="14" md="24">
            <RiskStratificationTable stats={this.props.stats} />
          </Col>
          <Col lg="10" md="24">
            <MonitoreeFlow stats={this.props.stats} />
          </Col>
        </Row>
        <h2> Epidemiological Summary </h2>
        <Row className="mb-4">
          <Col lg="12" md="24">
            <AgeStratificationActive stats={this.props.stats} />
          </Col>
          <Col lg="12" md="24">
            <Demographics stats={this.props.stats} />
          </Col>
        </Row>
      </React.Fragment>
    );
  }
}

RevisedMonitorAnalytics.propTypes = {
  stats: PropTypes.object,
  current_user: PropTypes.object,
};

export default RevisedMonitorAnalytics;
