var express = require('express');
var router = express.Router();

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
router.get('/', function(req, res, next) {
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
});

module.exports = router;
