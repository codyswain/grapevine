var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js'); // NOTE: Relative pathing can break
const FieldValue = require('firebase-admin').firestore.FieldValue

router.post('/', createGroup);          // Create a group 
router.get('/', fetchGroups);           // Fetch groups for a given member 
router.post('/key', createGroupKey);    // Create a key so a new user can join a group
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
      groups.push({
        name: ref1.data().name,
        id: groupID,
        ownerID: ref1.data().ownerID
      })
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
