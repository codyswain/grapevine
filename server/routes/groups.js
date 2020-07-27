var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js'); // NOTE: Relative pathing can break
const FieldValue = require('firebase-admin').firestore.FieldValue

router.post('/', createGroup);          // Create a group
router.post('/posts', createPost);	// Create post in a group
router.get('/', fetchGroups);           // Fetch groups for a given member 
router.get('/keygen', createGroupKey);    // Create a key so a new user can join a group
router.get('/key', consumeKey);         // Consume a key and return the groupID

/* POST /groups
Description: Post request includes the following
Input parameter Names: poster ID, group name
Output: groupID */
async function createGroup(req, res, next) {
  var db = req.app.get('db')
  let userID = req.body.ownerID
  let groupName = req.body.groupName
  group = {
    name : groupName,
    ownerID : userID,
    members: [userID]
  };
	db.collection("groups").add(group)
	.then(ref => {
    console.log('CREATED group with ID: ', ref.id);
    db.collection("users").doc(userID).update({ groups: FieldValue.arrayUnion(ref.id) })
    res.status(200).send({groupID: ref.id});
	})
	.catch((err) => {
		console.log("ERROR creating group: " + err)
		res.status(400).send()
	})
}

/* POST /groups/posts
Description: Post request includes the following
Input parameter Names: content, poster, votes, date, type, lat, lon, numFlags
Output: None */
async function createPost(req, res, next) {
	var db = req.app.get('db');  
	console.log("createGroupsPost request of type: " + req.body.type + " and req.body.userID: " + req.body.userID + " and req.body.groupID: " + req.body.groupID)
	// Text post creation logic
	if (req.body.type == 'text') {
		let toxic_result = await perspective.analyze(req.body.text);
		console.log("Toxicity score " + toxic_result.attributeScores.TOXICITY.summaryScore.value)
		userPost = {
			content : req.body.text,
      			poster : req.body.userID,
			votes : 0,
			date : req.body.date,
			type : req.body.type,
			lat : req.body.latitude,
			lon : req.body.longitude,
			groupID : req.body.groupID,
			numFlags : 0,
			geohash: utils.getGeohash(req.body.latitude, req.body.longitude),
			interactions: {},
			toxicity: toxic_result.attributeScores.TOXICITY.summaryScore.value,
			banned: false,
			comments: 0
		};
	}

	// Image/drawing creation logic
	if (req.body.type == 'image') {
		console.log("Setting user post as image")
		userPost = {
			content: req.body.text, // TODO: Hacky solution max of 1MB
			poster : req.body.userID,
			votes : 0,
			date : req.body.date,
			type : req.body.type,
			lat : req.body.latitude,
			lon : req.body.longitude,
			groupID : req.body.groupID,
			numFlags : 0,
			geohash: utils.getGeohash(req.body.latitude, req.body.longitude),
			interactions: {},
			toxicity: 1, // Just default to the worst for images
			banned: false,
			comments: 0
		};
  }

	await db.collection('groups').doc(groupID).collection('posts').add(userPost)
	.then(ref => {
    // update push notification token for APNS requests
    token = req.body.pushNotificationToken
    utils.updatePushNotificationToken(req, req.body.userID, token)
	  console.log('Added document with ID: ', ref.id);
		res.status(200).send(ref.id);
	})
	.catch((err) => {
		console.log("ERROR storing post : " + err)
		res.status(400).send()
  })
  

}

/* GET /groups
Description: Get request retrieves the groups a user is a member of
Input parameter Names: userID
Output: list of groups */
async function fetchGroups(req, res, next){
  var db = req.app.get('db');
  let userID = req.query.userID;
  var groups = [];

  // Fetch group id's from user doc
  // Fetch group names from group collection
  // TODO: Add in  error handling try/catch/finally
  let userRef = await db.collection('users').doc(userID).get();
  let fetchedGroups = userRef.data().groups
  if (fetchedGroups === undefined || fetchedGroups.length == 0){
    res.status(200).send([])
  } else {
    for (const groupID of fetchedGroups){
      let ref1 = await db.collection('groups').doc(groupID).get()
      if (ref1.exists){
        groups.push({
          name: ref1.data().name,
          id: groupID,
          ownerID: ref1.data().ownerID
        })
      }
    }
    res.status(200).send({groups: groups})
  }
}

/* POST /groups/key
Description: Generates a new key which allows access to join a group
Input parameter Names: groupID
Output: 4 charater key */
async function createGroupKey(req, res, next){
  var db = req.app.get('db')
  let groupID = req.query.groupID
  let newKey = utils.randomString(4);
  db.collection("keys").doc(newKey).set({groupID : groupID})
  .then(ref => {
    console.log(`CREATED key: ${newKey} for groupID: ${groupID}`);
    res.status(200).send({key: newKey});
	})
	.catch((err) => {
		console.log("ERROR creating group key: " + err)
		res.status(400).send()
	})
}

/* GET /groups/key
Description: Consumes a key, adding the user to a group
Input parameter Names: groupID
Output: 4 charater key */
async function consumeKey(req, res, next){
  var db = req.app.get('db')
  let userID = req.query.userID
  let key = req.query.key
  var docRef = db.collection("keys").doc(key);

  // Validate that the key corresponds to a group then remove it
  docRef.get().then(function(doc) {
    var groupID = doc.data().groupID
    docRef.delete().then(function() {
      console.log(`SUCCESSFULLY VALIDATED and REMOVED key: ${key}. ADDING userID: ${userID} to group: ${groupID}`);
      db.collection("groups").doc(groupID).update({ members: FieldValue.arrayUnion(userID) })
      db.collection("users").doc(userID).update({ groups: FieldValue.arrayUnion(groupID) }, {merge: true})
      res.status(200).send({groupID: groupID})
    }).catch(function(error) {
      console.log(`SUCCESSFULLY VALIDATED key: ${key} for groupID: ${groupID}`);
      console.error("Error removing document: ", error);
    });
  }).catch(function(error) {
    console.log(`Error validating key ${key}: `, error);
  });
}

module.exports = router;
