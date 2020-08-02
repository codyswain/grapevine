var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js') // NOTE: Relative pathing can break
const Perspective = require('perspective-api-client');
const perspective = new Perspective({apiKey: process.env.PERSPECTIVE_API_KEY});

const default_range = "1"; // Default bounding square half width, in miles

// URL parsing to get info from client
router.get('/', getMyPosts);
router.get('/more', getMoreMyPosts);
// router.get('/comments', getMyComments);

async function getMyPosts(req, res, next) {
	let user = req.query.user;
  let activityFilter = req.query.activityFilter;
  let typeFilter = req.query.typeFilter;
  let groupID = req.query.groupID;

	console.log("MyPosts request from user: " + user)

	// Get the db object, declared in app.js
  var db = req.app.get('db');
  var query; 
  if (groupID == "Grapevine") {
    query = db.collection('posts').where("poster", "==", user)
  } else {
    query = db.collection('groups').doc(groupID).collection('posts').where("poster", "==", user)
  }

  // Query the db for posts
  if (activityFilter == "top"){
    query.orderBy('votes', 'desc')
    .limit(20).get()
    .then((snapshot) => {
      let ref = snapshot.size == 0 ? "" : snapshot.docs[snapshot.docs.length-1].id
      var posts = []
      // Loop through each post returned and add it to our list
      snapshot.forEach((post) => {
        var voteStatus = 0
        var flagStatus = 0
        var interactions = post.get("interactions")

        // TODO: Better solution by putting this in mobile backend
        for (var interacting_user in interactions) {
          if (interacting_user == user) {
            voteStatus = utils.getVote(interactions[user])
            flagStatus = utils.getFlag(interactions[user]) ? 1 : 0
            break
          }
        }

        // Add the post, ID, and vote status before returning it
        var curPost = post.data()
        curPost.postId = post.id
        curPost.voteStatus = voteStatus
		    curPost.flagStatus = flagStatus
        delete curPost["geohash"]
        delete curPost["interactions"]
        // delete curPost["inter"]
        posts.push(curPost)
      });
      // Return the posts to the client
      posts = posts.sort((a, b) => { return b.votes - a.votes })
      res.status(200).send({reference: ref, posts: posts})
    })
    .catch((err) => { 
      console.log("ERROR looking up post in posts.js:" + err)
      res.send([])
    })
  } else {
    query.orderBy('date', 'desc')
    .limit(20).get()
    .then((snapshot) => {
      let ref = snapshot.size == 0 ? "" : snapshot.docs[snapshot.docs.length-1].id
      var posts = []
      // Loop through each post returned and add it to our list
      snapshot.forEach((post) => {
        var voteStatus = 0
        var flagStatus = 0
        var interactions = post.get("interactions")

        // TODO: Better solution by putting this in mobile backend
        for (var interacting_user in interactions) {
          if (interacting_user == user) {
            voteStatus = utils.getVote(interactions[user])
            flagStatus = utils.getFlag(interactions[user]) ? 1 : 0
            break
          }
        }

        // Add the post, ID, and vote status before returning it
        var curPost = post.data()
        curPost.postId = post.id
        curPost.voteStatus = voteStatus
		    curPost.flagStatus = flagStatus
        delete curPost["geohash"]
        delete curPost["interactions"]
        // delete curPost["inter"]
        posts.push(curPost)
      });
      // Return the posts to the client
      posts = posts.sort((a, b) => { return b.date - a.date })
      res.status(200).send({reference: ref, posts: posts})
    })
    .catch((err) => { 
      console.log("ERROR looking up post in getMyPosts:" + err)
      res.send([])
    })
  }
}

async function getMoreMyPosts(req, res, next) {
	let user = req.query.user;
  let activityFilter = req.query.activityFilter;
  let typeFilter = req.query.typeFilter;
  let docRef = req.query.ref;
  let groupID = req.query.groupID;
	console.log("getMoreMyPosts request from user: " + user)
	
	// Get the db object, declared in app.js
	var db = req.app.get('db');

	// Request the document snapshot of the last post retrieved in the previous request for posts
  var refquery;
  
  if (groupID == "Grapevine") {
    refquery = db.collection('posts').doc(docRef)
  } else {
    refquery = db.collection('groups').doc(groupID).collection('posts').doc(docRef)
  }

  var query;
  var postCollection;
  if (groupID == "Grapevine") {
    postCollection = db.collection('posts')
  } else {
    postCollection = db.collection('groups').doc(groupID).collection('posts')
  }

  // Basic request for posts
  if (activityFilter == "top"){
    if (typeFilter == "art" || typeFilter == "text"){
      query = postCollection
        .where("poster", "==", user)
        .where("banned", "==", false)
        .where("type", "==", typeFilter)
        .orderBy('votes', 'desc')
    } else {
      query = postCollection
        .where("poster", "==", user)
        .where("banned", "==", false)
        .orderBy('votes', 'desc')
    }
  } else {
    if (typeFilter == "art" || typeFilter == "text"){
      query = postCollection
      .where("poster", "==", user)
      .where("banned", "==", false)
      .where("type", "==", typeFilter)
      .orderBy('date', 'desc')
    } else {
      query = postCollection
      .where("poster", "==", user)
      .where("banned", "==", false)
      .orderBy('date', 'desc')
    }
  }

	// Get the document snapshot of the last document first
	refquery.get().then((doc) => {
		// Query for more posts started after the retrieved snapshot
		query.startAfter(doc).limit(20).get().then((snapshot) => {
			let ref = snapshot.size == 0 ? "" : snapshot.docs[snapshot.docs.length-1].id
			var posts = []

			snapshot.forEach((post) => {
				var voteStatus = 0
				var flagStatus = 0
	
				var interactions = post.get("interactions")
	
				// TODO: Better solution by putting this in mobile backend
				for (var interacting_user in interactions) {
					if (interacting_user == user) {
						voteStatus = utils.getVote(interactions[user])
						flagStatus = utils.getFlag(interactions[user]) ? 1 : 0
						break
					}
				}
	
				// Add the post, ID, and vote status before returning it
				var curPost = post.data()
				curPost.postId = post.id
				curPost.voteStatus = voteStatus
				curPost.flagStatus = flagStatus
				delete curPost["geohash"]
				delete curPost["interactions"]
				// delete curPost["inter"]
				posts.push(curPost)
			});
      // Return the posts to the client
      if (activityFilter == "top"){
        posts = posts.sort((a, b) => { return b.votes - a.votes })
      } else {
        posts = posts.sort((a, b) => { return b.date - a.date })
      }
			res.status(200).send({reference: ref, posts: posts})
		})	
		.catch((err) => { 
			console.log("ERROR looking up posts in getMoreMyPosts:" + err)
			res.send([])
		})	
	})
	.catch((err) => { 
		console.log("ERROR looking up document in getMoreMyPosts:" + err)
		res.send([])
	})
	
}

module.exports = router;