// Actually write a test for this sometime
// Test URL below
// http://localhost:3000/interactions/?post=CGayWxxYmEe0rOXrIo5K&user=0040319e95297da3ccdc4d6be9021940ee753ca284c7f121a12e040dd14110fe&action=4


//Test upvote, downvote, flag, banned post, toggle, 

const chai = require('chai');
const chaiHttp = require('chai-http');

var app = require('../app.js'); // NOTE: Relative pathing can break
var utils = require('../server_utils.js');

chai.should();
chai.use(chaiHttp);

var expect = chai.expect;

// Checks Interaction logic
describe('Creates posts, upvotes, downvotes and flags and checks values', () => {

  const testLat = 37.7873589;
  const testLon = -122.408227;
  const testUser = '029ee2aa5aea9358dd430115bc769cb5fc5a9156ce8fa6f79710c95b7eba5540'

it('Correctly alllows for creating and upvoting a post', function(done) {

    // Variables to store data across HTTP requests
    let postId = "";

    chai.request(app).post('/posts')
      .send({
        "text" : "Chickfila sandwiches are better than popeyes",
        "userID" : "445a6a54cd2b9067621694ebd79efcad15372f0d3bd4f1b625fe2588026df674",
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

        console.log("We created dummy post with ID " + postId + " as part of our test ")

        var data = JSON.parse(res.text)
        for (ind in data) {
          if (data[ind]['postId'] == postId) {
            found_post = true
          }
        }
        expect(found_post).to.be.true;

        console.log("We then try to update the interactions")

        return chai.request(app).get('/interactions')
          .query({'post': postId,
                  'user': testUser,
                  'action': 1,
                });
      })
      .then((res) => { 
        res.should.have.status(200);

        return chai.request(app).get('/posts')
          .query({'lat': testLat,
                  'lon': testLon,
                  'user': testUser,
                  'range': 100});
      })
      .then((res) => { // Test that a Upvote has been registered
        res.should.have.status(200); 

        var data = JSON.parse(res.text)
        for (ind in data) {
          if (data[ind]['postId'] == postId) {
            expect(data[ind]['votes']).to.equal(1)
          }
        }

        return chai.request(app).get('/interactions')
          .query({'post': postId,
                  'user': testUser,
                  'action': 1,
                });
      })      
      .then((res) => { 
        res.should.have.status(200);

        return chai.request(app).get('/posts')
          .query({'lat': testLat,
                  'lon': testLon,
                  'user': testUser,
                  'range': 100});
      })
      .then((res) => { // Test that a toggle functionality works
        res.should.have.status(200); 

        var data = JSON.parse(res.text)
        for (ind in data) {
          if (data[ind]['postId'] == postId) {
            expect(data[ind]['votes']).to.equal(0)
          }
        }

        return chai.request(app).delete('/posts')
          .send({'postId': postId});
      })
      .then((res) => {
        res.should.have.status(200);
        done();
      })
  })


  it('Correctly alllows for creating and downvoting a post', function(done) {

    // Variables to store data across HTTP requests
    let postId = "";

    chai.request(app).post('/posts')
      .send({
        "text" : "Chickfila sandwiches are better than popeyes",
        "userID" : "445a6a54cd2b9067621694ebd79efcad15372f0d3bd4f1b625fe2588026df674",
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

        console.log("We created dummy post with ID " + postId + " as part of our test ")

        var data = JSON.parse(res.text)
        for (ind in data) {
          if (data[ind]['postId'] == postId) {
            found_post = true
          }
        }
        expect(found_post).to.be.true;

        console.log("We then try to update the interactions")

        return chai.request(app).get('/interactions')
          .query({'post': postId,
                  'user': testUser,
                  'action': 2,
                });
      })
      .then((res) => { 
        res.should.have.status(200);

        return chai.request(app).get('/posts')
          .query({'lat': testLat,
                  'lon': testLon,
                  'user': testUser,
                  'range': 100});
      })
      .then((res) => { // Test that a Downvote has been registered
        res.should.have.status(200); 

        var data = JSON.parse(res.text)
        for (ind in data) {
          if (data[ind]['postId'] == postId) {
            expect(data[ind]['votes']).to.equal(-1)
          }
        }

        return chai.request(app).get('/interactions')
          .query({'post': postId,
                  'user': testUser,
                  'action': 2,
                });
      })      
      .then((res) => { 
        res.should.have.status(200);

        return chai.request(app).get('/posts')
          .query({'lat': testLat,
                  'lon': testLon,
                  'user': testUser,
                  'range': 100});
      })
      .then((res) => { // Test that a toggle functionality works
        res.should.have.status(200); 

        var data = JSON.parse(res.text)
        for (ind in data) {
          if (data[ind]['postId'] == postId) {
            expect(data[ind]['votes']).to.equal(0)
          }
        }

        return chai.request(app).delete('/posts')
          .send({'postId': postId});
      })
      .then((res) => {
        res.should.have.status(200);
        done();
      })

  })

  it('Correctly alllows for creating and flagging a post', function(done) {

    // Variables to store data across HTTP requests
    let postId = "";

    chai.request(app).post('/posts')
      .send({
        "text" : "Chickfila sandwiches are better than popeyes",
        "userID" : "445a6a54cd2b9067621694ebd79efcad15372f0d3bd4f1b625fe2588026df674",
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

        console.log("We created dummy post with ID " + postId + " as part of our test ")

        var data = JSON.parse(res.text)
        for (ind in data) {
          if (data[ind]['postId'] == postId) {
            found_post = true
          }
        }
        expect(found_post).to.be.true;

        console.log("We then try to update the interactions")

        return chai.request(app).get('/interactions')
          .query({'post': postId,
                  'user': testUser,
                  'action': 4,
                });
      })
      .then((res) => { 
        res.should.have.status(200);

        return chai.request(app).get('/posts')
          .query({'lat': testLat,
                  'lon': testLon,
                  'user': testUser,
                  'range': 100});
      })
      .then((res) => { // Test that a Downvote has been registered
        res.should.have.status(200); 

        var data = JSON.parse(res.text)
        for (ind in data) {
          if (data[ind]['postId'] == postId) {
            expect(data[ind]['numFlags']).to.equal(1)
          }
        }
        return chai.request(app).delete('/posts')
          .send({'postId': postId});
      })
      .then((res) => {
        res.should.have.status(200);
        done();
      })
  })
})