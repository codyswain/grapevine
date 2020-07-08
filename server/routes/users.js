var express = require('express');
var router = express.Router();
const admin = require('firebase-admin');
var utils = require('../server_utils.js') // NOTE: Relative pathing can break

// URL parsing to get info from client
router.get('/', getUser);
router.get('/freeUser/', freeUser);
router.get('/getUsersWithinRange/', getUsersWithinRange);

/**
 * Fetches a user from the database based on the url parameters and sends it to the client.
 * @name getPosts
 * @function
 */
/*
Description: Get request including SHA256 hash of user id
Input parameter Names: user
Output: Userinfo 
Output parameter Names: userInfo: user, banDate, strikes, score
*/
async function getUser(req, res, next) {
  let usr = req.query.user;
  let abbreviation = usr.substring(0, 64)
  console.log("GetUsers request from " + usr);

  // Get the db object, declared in app.js
  var db = req.app.get('db');

  // Query the DB for this user's information
  db.collection('users').where("user", "==", usr)
    .get()
    .then((querySnapshot) => {
      let userInfo = {}
      if (querySnapshot.size > 0) {
        userInfo = querySnapshot.docs[0].data();
      } else {
        // If the user isn't found, create them
        let docRef = db.collection('users').doc(abbreviation);
        userInfo = {
          user: usr,
          banDate: 0,
          strikes: 0,
          score: 0
        }
        let setUser = docRef.set(userInfo);
      }

      res.send(userInfo);
    })
}

async function freeUser(req, res, next) {
  let usr = req.query.user;
  let abbreviation = usr.substring(0, 64)
  console.log("freeUser request from " + usr);

  // Get the db object, declared in app.js
  var db = req.app.get('db');

  await db.collection('users').doc(usr).update({
    strikes: admin.firestore.FieldValue.increment(-3)
  }).then((snapshot) => {
    res.send("freeUser success")
  })
  .catch((err) => { 
    res.send("ERROR freeUser:" + err)
  })  
}

async function getUsersWithinRange(req, res, next) {
  let user = req.query.user;
  let lat = Number(req.query.lat);
  let lon = Number(req.query.lon);
  let range = req.query.range;
  if (typeof(range) == "undefined") { // If range unspecified, use some default one
    range = default_range;
  } 
  range = Number(range);
  console.log("getUsersWithinRange request from lat: " + lat + " and lon: " + lon + " for users within range:" + range + " from user: " + user)

  // Get the db object, declared in app.js
  var db = req.app.get('db');

  // Update the requesters location (geohash)
  db.collection("users").doc(user).update({ location: utils.getGeohash(lat, lon) })

  var query; 
  // Calculate the lower and upper geohashes to consider
  const search_box = utils.getGeohashRange(lat, lon, range);
  
  query = db.collection('users')
    .where("location", ">=", search_box.lower)
    .where("location", "<=", search_box.upper)
    .orderBy("location")

  var currentTime = new Date() / 1000
  query.limit(10000).get()
  .then((snapshot) => {
    let ref = snapshot.size == 0 ? "" : snapshot.docs[snapshot.docs.length-1].id
    var users = []
    // Loop through each post returned and add it to our list
    snapshot.forEach((user) => {
    // console.log("user :" + JSON.stringify(user))
      var curUser = user.data()
      if (currentTime - curUser.banDate > 86400.0){ // if the user is not banned
        // curUser.postId = user.id
        // delete curUser["interactions"]
        users.push(curUser)
      }
    });
    // Return the users to the client
    users = users.sort((a, b) => { return b.date - a.date })
    res.status(200).send({reference: ref, users: users})
  })
  .catch((err) => { 
    console.log("ERROR retrieving users in a certain radius in users.js:" + err)
    res.send([])
  })
}

module.exports = router;
