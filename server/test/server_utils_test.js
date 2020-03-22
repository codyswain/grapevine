const chai = require('chai');
const chaiHttp = require('chai-http');

var app = require('../app.js'); // NOTE: Relative pathing can break
var utils = require('../server_utils.js');

chai.should();
chai.use(chaiHttp);

var expect = chai.expect;

describe('Calculating new number of Flags', () => {
  it('Correctly calculates the value of num flags', function(done) {
    var date = ((Date.now())/1000) - 1000;
    var limit = utils.getFlagLimit(1000, 0.1, 3, date)|0;
    expect(limit).to.equal(194)
    done();
  })
})