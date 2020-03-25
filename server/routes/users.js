var express = require('express');
var router = express.Router();
const admin = require('firebase-admin');

// URL parsing to get info from client
router.get('/', getUser);
router.get('/freeUser/', freeUser);

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


module.exports = router;
