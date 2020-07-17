var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js') // NOTE: Relative pathing can break
const FieldValue = require('firebase-admin').firestore.FieldValue

// URL parsing to get info from client
router.get('/', getComments);
router.post('/', createComment);
router.delete('/', deleteComment);

/**
 * Fetches comments from the database based on the url parameters and sends them to the client.
 */
/*
GET /comments
Input parameter Names: post id
Output: Comments ordered by time created
*/

async function getComments(req, res, next) {
  let postID = req.query.postID;
  let userID = req.query.userID
	console.log("GET /comments request with postID: " + postID)

	// Get the db object, declared in app.js
	var db = req.app.get('db');

	// Query the db for posts
	db.collection('comments')
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
  commentID = req.body.commentId
  postID = req.body.postId
  console.log(`Attempting to delete: ${commentID}`)

	db.collection("comments").doc(commentID).delete()
	.catch((err) => {
		console.log("ERROR deleteing comment : " + err)
		res.status(400).send()
	})
	.then(() => {
		res.status(200).send("Successfully deleted comment " + commentID);
  })
	db.collection("posts").doc(postID).update({ comments: FieldValue.decrement(1) })
}

module.exports = router;
