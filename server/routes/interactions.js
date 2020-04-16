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
  let vote = 0;
  let user = req.query.user;
  let post = req.query.post;
  let action = parseInt(req.query.action, 10); // Flag encoding request to toggle
  console.log("updateInteractions request from " + user + " for " + post);

  // Get the db object, declared in app.js
  var db = req.app.get('db');

  // Run transaction to update the post information atomically.
  const postRef = db.collection('posts').doc(post)
  db.runTransaction(t => {
    return t.get(postRef).then(snapshot => {
      if (!snapshot.exists) {
        throw "Post " + post + " does not exist";
      }

      let interactions = snapshot.data().interactions;

      // Update interaction
      if (user in interactions) { 
        // This will throw if it fail
        interactions[user] = utils.toggleInteraction(interactions[user], action)
      } else {
        interactions[user] = action;
      }
      let f = snapshot.data().numFlags;
      let v = snapshot.data().votes;
      let toxicity = snapshot.data().toxicity;
      let date = snapshot.data().date;
      let numInteractions = Object.keys(interactions).length;

      let userv = 0;
      if (utils.hasInteraction(action, utils.FLAG)) {
        // Update post flag count
        f += utils.updateFlagCount(interactions[user]);
      } else {
        // Update post votes
        vote = utils.updateVoteCount(interactions[user], action);
        v += vote;
        userv = vote; 
      }
      
      // Delete if interaction is voided or results in bad data
      if (interactions[user] == 0) {
        delete interactions[user];
      }

      let limit = utils.getFlagLimit(numInteractions, toxicity, v, date);
      let ban = false;
      if (f >= limit) {
        ban = true;
      }
      t.update(postRef, { interactions: interactions, votes: v, numFlags: f, banned: ban});

      // Update poster score
      // TODO: Entire transaction fails if the user document does not exist
      let poster = snapshot.data().poster;
      let userRef = db.collection('users').doc(poster);
      t.update(userRef, { score: FieldValue.increment(userv)});

    });
  }).then(() => {
    // Send notification to poster if the interaction is an upvote
    if (vote === 1){
      var body = "Someone liked your post";
      utils.sendPushNotificationToPoster(req, post, body);
    }
    res.status(200).send();
    console.log("Transaction to update interaction from " + user + " with post " + post + " and action " + action + " successful");
  }).catch(err => {
    res.status(500).send();
    console.log("Transaction to update interaction from " + user + " with post " + post + " and action " + action + " failed with: " + err)
  });
});

module.exports = router;