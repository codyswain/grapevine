const chai = require('chai');
const chaiHttp = require('chai-http');

var app = require('../app.js'); // NOTE: Relative pathing can break
var utils = require('../server_utils.js');

chai.should();
chai.use(chaiHttp);

var expect = chai.expect;

const testLat = 37.7873589;
const testLon = -122.408227;
const testUser = 'ce77cb568cc58c1c24879c213277407ec86c8a757867ca3b12c28c0ffcb745db'

// Checks geographic limits for posts getting
describe('Getting posts from server', () => {

  it('Correctly gets posts within certain ranges', function(done) {
    var agent = chai.request(app)

    // Check that posts are within the default 1 mile
    agent.get('/posts')
      .query({'lat': testLat,
              'lon': testLon,
              'user': testUser})
      .end((err, res) => {
        res.should.have.status(200); // Assert gave 200 status

        cbox = utils.getCoordBox(testLat, testLon, 1); // 1 mile defaultcle

        res.body.forEach(function (post) {
          expect(post['lon']).to.be.within(cbox.lowerLon, cbox.upperLon);
          expect(post['lat']).to.be.within(cbox.lowerLat, cbox.upperLat);
        })
      })

    // Check that posts are within 100 miles and greater than 2, ie including more posts than above
    agent.get('/posts')
      .query({'lat': testLat,
              'lon': testLon,
              'user': testUser,
              'range': 100})
      .end((err, res) => {
        res.should.have.status(200); // Assert gave 200 status

        cbox = utils.getCoordBox(testLat, testLon, 100); // 1 mile defaultcle

        res.body.forEach(function (post) {
          expect(post['lon']).to.be.within(cbox.lowerLon, cbox.upperLon);
          expect(post['lat']).to.be.within(cbox.lowerLat, cbox.upperLat);
        })

        expect(res.body.length > 2) // NOTE: This is hardcoded in given current database conditions, not too robust

        done();
      })
  })

  it('Does not retrieve posts that are banned', function(done) {
    var agent = chai.request(app)

    // Check that posts are within the default 1 mile
    agent.get('/posts')
      .query({'lat': testLat,
              'lon': testLon,
              'user': testUser})
      .end((err, res) => {
        res.should.have.status(200); // Assert gave 200 status
        var data = JSON.parse(res.text)
        var found_post = false;
        for (ind in data) {
          if (data[ind]['postId'] == 'IrlbLtFFEX9rwXc2VEJc') {
            found_post = true
          }
        }
        expect(found_post).to.be.false;
        done();
      })
  })
})

// Checks POST, GET, and DELETE logic for posts
describe('Creates posts, checks that it exists, then deletes it', () => {

  const testLat = 37.7873589;
  const testLon = -122.408227;
  const testUser = '0040319e95297da3ccdc4d6be9021940ee753ca284c7f121a12e040dd14110fe'

  it('Correctly alllows for creating, checking, then deleting a post', function(done) {

    // Variables to store data across HTTP requests
    let postId = "";

    chai.request(app).post('/posts')
      .send({
        "text" : "LaGuardia is worse than a third world country airport - Biden",
        "userID" : "ce77cb568cc58c1c24879c213277407ec86c8a757867ca3b12c28c0ffcb745db",
        "date" : 1580328718.1122699,
        "type" : "text",
        "latitude" : 37.7873589,
        "longitude" : -122.408227
      })
      .then((res) => { // Create post and save its post ID
        res.should.have.status(200); 
        postId = res.text

        return chai.request(app).get('/posts')
          .query({'lat': testLat,
                  'lon': testLon,
                  'user': testUser,
                  'range': 100});
      })
      .then((res) => { // Check that we see this posts when we make a request for posts
        res.should.have.status(200); 
        var found_post = false

        console.log("We created dummy post with ID " + postId + " as part of our test (it should be deleted)")

        var data = JSON.parse(res.text)
        for (ind in data) {
          if (data[ind]['postId'] == postId) {
            found_post = true
          }
        }

        expect(found_post).to.be.true;

        return chai.request(app).delete('/posts')
          .send({'postId': postId});
      })
      .then((res) => { // Delete this post
        res.should.have.status(200); 

        return chai.request(app).get('/posts')
          .query({'lat': testLat,
                  'lon': testLon,
                  'user': testUser,
                  'range': 100});
      })
      .then((res) => { // Check that the post was successfully deleted
        res.should.have.status(200); 
        var found_post = false

        var data = JSON.parse(res.text)
        for (ind in data) {
          if (data[ind]['postId'] == postId) {
            found_post = true
          }
        }
        expect(found_post).to.be.false;

        done();
      })
  })
})