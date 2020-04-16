/************ File to store assorted utility functions ***********/

/*********************** Geohashing Logic ************************/

var geohash = require('ngeohash');
var apn = require('apn');

// These are magic numbers I got from StackOverflow (Douglas)
const dpm_lat = 0.0144927536231884; // degrees latitude per mile
const dpm_lon = 0.0181818181818182; // degrees longitude per mile


/**
 * @typedef {Object} Box
 * @property {number} lowerLat - The lower latitude
 * @property {number} lowerLon - The lower longitude
 * @property {number} upperLat - The upper latitude
 * @property {number} upperLon - The upper longitude
 */

/**
 * Gives the lower latitude and longitude and upper latitude and longitude
 * Formed by bounding in a box with a certain halfwidth
 * @param  {number} latitude - The latitude
 * @param  {number} longitude - The longitude
 * @param  {number} halfwidth - The halfwidth
 * @return {Box} - Box of upper and lower latitudes and longitudes
 */
function getCoordBox(latitude, longitude, halfwidth) {
  let lowerLat = latitude - dpm_lat * halfwidth;
  let lowerLon = longitude - dpm_lon * halfwidth;

  let upperLat = latitude + dpm_lat * halfwidth;
  let upperLon = longitude + dpm_lon * halfwidth;

  return {
  	lowerLat: lowerLat,
  	lowerLon: lowerLon,
  	upperLat: upperLat,
  	upperLon: upperLon,
  }
}

/**
 * @typedef {Object} GeohashRange
 * @property {string} lower - The lower geohash
 * @property {string} upper - The upper geohash
 */


/**
 * Gives the geohash encoded range of latitude and longitudes
 * @param  {number} latitude - The latitude
 * @param  {number} longitude - The longitude
 * @param  {number} halfwidth - The halfwidth
 * @return {}
 */
function getGeohashRange(latitude, longitude, halfwidth) {
	let cbox = getCoordBox(latitude, longitude, halfwidth);

  let lower = geohash.encode(cbox.lowerLat, cbox.lowerLon);
  let upper = geohash.encode(cbox.upperLat, cbox.upperLon);

  return {lower, upper};
}

function getGeohash(latitude, longitude) {
  return geohash.encode(latitude, longitude)
}


/****************** Interactions Encoding Logic ******************/

// The bits in our interaction number encode interactions a person
// has had with a post, eg 6 = 110 => Downvoted and flagged
// This system is nice because toggling is just bitwise XOR and 
// checking is AND

const UPVOTE = 1;
const DOWNVOTE = 2;
const FLAG = 4;

const VALID_INTERACTIONS = [UPVOTE, DOWNVOTE, FLAG];

/**
 * Toggles the interactions number by a certain type of interaction
 * Example toggleInteractions(interactionsSet, UPVOTE)
 * @param {Number} interactions [Number encoding previous interactions]
 * @param {Number} toggle [Interaction that we want to toggle by]
 * @return {Number} [The new interactions number after toggling]
 */
function toggleInteraction(interactions, toggle) {
  if (!VALID_INTERACTIONS.includes(toggle)) {
    throw new Error("We're trying to toggle interaction " + interactions + " by "
     + toggle + " but it is not a valid type of interaction to toggle by");
  }
  return interactions ^ toggle;
}

/**
 * Checks whether the interactions number encodes a certain kind of interaction (eg upvote, downvote, flag)
 * @param {Number} interactions [Number encoding previous interactions]
 * @param {Number} to_check [The interaction we want to check if contained here]
 * @return {Number} [1 if the interactions contains an instance of what we want to check, 0 otherwise]
 */
function hasInteraction(interactions, to_check) {
  if (!VALID_INTERACTIONS.includes(to_check)) {
    throw new Error("We're trying to check if interaction " + interactions + " has "
      + to_check + " but it is not a valid type of interaction to check against");
  }
  return Boolean(interactions & to_check);
}

/**
 * Gets the vote status from the interactions number, 1 for upvote, -1 for downvote
 * @param {Number} interactions [Number encoding previous interactions]
 * @return {Number} [The vote status of the user]
 */
function getVote(interactions) {
  return hasInteraction(interactions, UPVOTE)
  - hasInteraction(interactions, DOWNVOTE);
}

/**
 * Gets the flag status from the interactions number, 1 for upvote, -1 for downvote
 * @param {Number} interactions [Number encoding previous interactions]
 * @return {Number} [The flag status of the user]
 */
function getFlag(interactions) {
  return hasInteraction(interactions, FLAG);
}

/**
 * Determines how to update a post's flag count 
 * @param {Number} interactions [Number encoding previous interactions]
 * @return {Number} [The value to add to the flag count]
 */
function updateFlagCount(interactions) {
  let flagCount = 1
  // If this interactions set recently had its flag bit toggled
  if (hasInteraction(interactions, FLAG) == 0) {
    flagCount = -1
  }
  return flagCount;
}

/**
 * Determines how to update a post's vote count
 * @param {Number} interactions [Number encoding previous interactions]
 * @param {Number} toggle [Interaction that we toggled by]
 * @return {Number} [The value to add to the flag count]
 */
function updateVoteCount(interactions, toggle) {
  let voteCount = 1;
  // If this user just got downvoted or had their upvote undone
  if ((toggle == DOWNVOTE && hasInteraction(interactions, DOWNVOTE)) ||
    (toggle == UPVOTE && !hasInteraction(interactions, UPVOTE))) {
    voteCount = -1;
  }
  return voteCount;
}
/**
 * Determines the number of flags needed for a post to be banned
 * @param {Number} numInteractions [Number of interactoins on post]
 * @param {Number} toxicity [Toxicity value of post]
 * @param {Number} votes [Votes on a post]
 * @param {Number} dateTime [Date time that a post was posted]
 * @return {Number} [The total number of flags]
 */
function getFlagLimit(numInteractions, toxicity, votes, dateTime) {
  let limitInteractions = numInteractions/5;
  let limitToxicity = limitInteractions/(toxicity+1);
  let limitVotes = limitToxicity + (limitToxicity/2)*(votes/numInteractions);
  let postMins = (dateTime/60)|0;
  let curDate = new Date().getTime();
  let curMins = ((curDate/1000)/60)|0;
  let timeDiff = curMins - postMins;
  let flagLimit = limitVotes + ((30/Math.sqrt(timeDiff)) + 5);
  return flagLimit;
}

function deletePostComments(postID, req){
  var db = req.app.get('db');  
  var commentsQuery = db.collection('comments').where("postID", "==", postID)
  commentsQuery.get().then(function(querySnapshot){
    querySnapshot.forEach(function(doc){
      doc.ref.delete();
    });
  });
}

function updatePushNotificationToken(req, userID, body){
  var db = req.app.get('db');
  var userRef = db.collection('users').doc(userID);
  var setWithMerge = userRef.set({"pushNotificationToken": token}, { merge: true });
}

// Get user id from post id
function sendPushNotificationToPoster(req, postID, body){
  var db = req.app.get('db');
  var docRef = db.collection("posts").doc(postID);
  docRef.get().then(function(doc) {
    console.log("POST EXISTS");
      if (doc.exists) {
          userID = doc.data().poster;
          console.log(`RETRIEVED USER ID ${userID}`);
          pushNotificationHelper1(req, userID, body);
      } else {
          console.log("No such document!");
      }
  }).catch(function(error) {
      console.log("Error getting document:", error);
  });
}
// Get user token from user id
function pushNotificationHelper1(req, userID, body){
  var db = req.app.get('db');
  var docRef = db.collection("users").doc(userID);
  docRef.get().then(function(doc) {
      if (doc.exists) {
          token = doc.data().pushNotificationToken
          console.log(`RETRIEVED token ${token}`);
          pushNotificationHelper2(req, token, body);
      } else {
          console.log("No such document!");
      }
  }).catch(function(error) {
      console.log("Error getting document:", error);
  });
}
// Send the push notification
function pushNotificationHelper2(req, token, body){
  var apnProvider = req.app.get('apnProvider')
  if (token){
    console.log("TOKEN EXISTS");
    var note = new apn.Notification();
    note.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
    note.badge = 3;
    note.sound = "ping.aiff";
    note.alert = `🔥👅 ${body}`;
    note.payload = {'messageFrom': 'Anonymous'};
    note.topic = "io.grapevineapp.Grapevine";

    console.log("SENDING TOKEN");
    apnProvider.send(note, token).then( (result) => {
      console.log("Sent notification")
    });
  }
}

module.exports = {getCoordBox, getGeohashRange, getGeohash, UPVOTE, DOWNVOTE, FLAG, toggleInteraction, getVote, getFlag, updateFlagCount, updateVoteCount, getFlagLimit, deletePostComments, hasInteraction, updatePushNotificationToken, sendPushNotificationToPoster}
