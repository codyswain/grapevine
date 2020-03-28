var express = require('express');
var router = express.Router();

// URL parsing to get info from client
router.get('/', getComments);
router.post('/', createComment);

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
	console.log("GET /comments request with postID: " + postID)

	// Get the db object, declared in app.js
	var db = req.app.get('db');

	// Query the db for posts
	db.collection('comments')
		.where("postID", "==", postID)
		.orderBy("date", 'desc').get()
		.then((snapshot) => {
      var comments = []
      
			// Loop through each comment returned and add it to our list
			snapshot.forEach((comment) => {
				var curComment = comment.data()
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

	// Text post creation logic
  userComment = {
    content : req.body.text,
    poster : req.body.userID,
    votes : 0,
    date : req.body.date,
  };

	db.collection("comments").add(userComment)
	.then(ref => {
	  console.log('Added document with ID: ', ref.id);
		res.status(200).send(ref.id);
	})
	.catch((err) => {
		console.log("ERROR storing comment: " + err)
		res.status(400).send()
	})
}

module.exports = router;
