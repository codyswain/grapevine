var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js') // NOTE: Relative pathing can break
const FieldValue = require('firebase-admin').firestore.FieldValue

// URL parsing to get info from client
router.get('/', getGroups);
router.post('/', createGroup);

/** 
 * Fetches groups from the database based on the url parameters and sends them to the client.
 */
/*
GET /comments
Input parameter Names: userID
Output: Groups (unordered)
*/

// TO-DO: return groups ordered by most used ?
// need to track which ones are being used

async function getGroups(req, res, next) {
  let user = req.query.userID
	console.log("GET /groups request for userId: " + userID)

	// Get the db object, declared in app.js
  var db = req.app.get('db');
  
  // 1. Fetch list of groups from user data
  // 2. Fetch group names and groupID

  // Query the db and return a list of groups
  // each group is composed of an ownerID, groupID, and groupName
  var userRef = db.collection('users').doc(user)
  var groupsRef = db.collection('groups')
  userRef.get().then((doc) => {
    console.log("/groups getGroups() fired");
    var userData = doc.data()
    var usersGroups = // groups a user is a part of 

  }).catch((err) => {
    console.log("Error /groups getGroups(): ", error);
  });


// Get the document snapshot of the last document first
refquery.get().then((doc) => {
  // Query for more posts started after the retrieved snapshot
  query.startAfter(doc).limit(20).get().then((snapshot) => {
    

	// Query the db for posts
	db.collection('groups')
		.where("postID", "==", postID)
		.orderBy("date", 'asc').get()
		.then((snapshot) => {
      var comments = []
      
			// Loop through each comment returned and add it to our list
			snapshot.forEach((comment) => {
        var curComment = comment.data()
        curComment.commentID = comment.id
       
        var interactions = comment.get("interactions")

        // TODO: Better solution by putting this in mobile backend
        curComment.voteStatus = 0
				for (var interacting_user in interactions) {
					if (interacting_user == userID) {
						curComment.voteStatus = interactions[userID]
						break
					}
        }
        
        comments.push(curComment)
      });
      
			// Return comments to client
			res.status(200).send(comments)
		})
		.catch((err) => { 
			console.log("ERROR looking up comments in comment.js: " + err)
			res.send([])
		})
}


/*
POST /comments
Description: Post request including details of comment
Input parameter Names: content, userID, date
Output: None
*/
async function createComment(req, res, next) {
  var db = req.app.get('db');  
  console.log(req.body.text)

	// Text post creation logic
  let postID = req.body.postID
  userComment = {
    content : req.body.text,
    poster : req.body.userID,
    postID : postID,
    votes : 0,
    date : req.body.date,
    interactions: {},
  };

	db.collection("comments").add(userComment)
	.then(ref => {
    // Send push notification to creator of post
    var body = "Someone commented on your post 👀";
    utils.sendPushNotificationToPoster(req, req.body.postID, body);
	  console.log('Added document with ID: ', ref.id);
		res.status(200).send(ref.id);
	})
	.catch((err) => {
		console.log("ERROR storing comment: " + err)
		res.status(400).send()
	})

	db.collection("posts").doc(postID).update({ comments: FieldValue.increment(1) })
}

async function deleteComment(req, res, next) {
  var db = req.app.get('db');
  let commentID = req.body.commentId
  let postID = req.body.postId
  console.log(`Attempting to delete: ${commentID}`)

	db.collection("comments").doc(commentID).delete()
	.catch((err) => {
		console.log("ERROR deleteing comment : " + err)
		res.status(400).send()
	})
	.then(() => {
		res.status(200).send("Successfully deleted comment " + commentID);
  })
	db.collection("posts").doc(postID).update({ comments: FieldValue.increment(-1) })
}

module.exports = router;
