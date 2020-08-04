var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js') // NOTE: Relative pathing can break
const FieldValue = require('firebase-admin').firestore.FieldValue

/**
 * Updates a user and a post based on how the user interacts with it.
 * @name updateInteractions
 * @function
 */
router.get('/', function(req, res, next) {
  let user = req.query.user;
  let commentID = req.query.commentID;
  let action = parseInt(req.query.action, 10); // Flag encoding request to toggle
  let groupID = req.query.groupID; //Karma doesn't change from private group interactions

  // Get the db object, declared in app.js
  var db = req.app.get('db');

  // Run transaction to update the post information atomically.
  const commentRef = db.collection('comments').doc(commentID)
  db.runTransaction(t => {
    return t.get(commentRef).then(snapshot => {
      if (!snapshot.exists) {
        throw "Comment " + commentID + " does not exist";
      }
      let interactions = snapshot.data().interactions;
      interactions[user] = action

      let v = snapshot.data().votes;
      let userv = 0;
      if (action === 1){
        userv = 1
        v += 1
      } else {
        userv = -1
        v -= 1
      }
      
      t.update(commentRef, { interactions: interactions, votes: v});

      // Update poster score if group is Grapevine
      // TODO: Entire transaction fails if the user document does not exist
      let poster = snapshot.data().poster;
      let userRef = db.collection('users').doc(poster)
      if (groupID == "Grapevine") {
        t.update(userRef, { score: FieldValue.increment(userv)})
      }
    });
  }).then(() => {
    res.status(200).send();
    console.log("Transaction to update interaction from " + user + " with comment " + commentID + " and action " + action + " successful");
  }).catch(err => {
    res.status(500).send();
    console.log("Transaction to update interaction from " + user + " with comment " + commentID + " and action " + action + " failed with: " + err)
  });
});

module.exports = router;