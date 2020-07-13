var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js') // NOTE: Relative pathing can break
const Perspective = require('perspective-api-client');
const perspective = new Perspective({apiKey: process.env.PERSPECTIVE_API_KEY});

const default_range = "1"; // Default bounding square half width, in miles

// URL parsing to get info from client
router.get('/', getPosts);
router.get('/more', morePosts);
router.post('/', createPost);
router.delete('/', deletePost);

/**
 * Fetches posts from the database based on the url parameters and sends them to the client.
 */
/*
GET /posts
Description: Get request including userID, latitude and longitude of user location.
Input parameter Names: user, lat, lon
Output: 20 posts ordered by recency returned as posts.
*/
async function getPosts(req, res, next) {
	let user = req.query.user;
	let lat = Number(req.query.lat);
	let lon = Number(req.query.lon);
  let range = req.query.range;
  let activityFilter = req.query.activityFilter;
  let typeFilter = req.query.typeFilter;
	if (typeof(range) == "undefined") { // If range unspecified, use some default one
		range = default_range;
	} 
	range = Number(range);
	console.log("GetPosts request from lat: " + lat + " and lon: " + lon + " for posts within range:" + range + " from user: " + user)

  // Get the db object, declared in app.js
  var db = req.app.get('db');

  // Update the requesters location (geohash)
  db.collection("users").doc(user).update({ location: utils.getGeohash(lat, lon) })

  var query; 
	if (range != -1) { // -1 refers to global range
		// Calculate the lower and upper geohashes to consider
		const search_box = utils.getGeohashRange(lat, lon, range);

    // Basic request for posts
    if (activityFilter == "top"){
      if (typeFilter == "art" || typeFilter == "text"){
        query = db.collection('posts')
					.where("banned", "==", false)
					.where("geohash", ">=", search_box.lower)
          .where("geohash", "<=", search_box.upper)
          .where("type", "==", typeFilter)
					.orderBy("geohash")
					.orderBy('votes', 'desc')
      } else {
        query = db.collection('posts')
					.where("banned", "==", false)
					.where("geohash", ">=", search_box.lower)
					.where("geohash", "<=", search_box.upper)
					.orderBy("geohash")
					.orderBy('votes', 'desc')
      }
    } else {
      if (typeFilter == "art" || typeFilter == "text"){
        query = db.collection('posts')
					.where("banned", "==", false)
					.where("geohash", ">=", search_box.lower)
          .where("geohash", "<=", search_box.upper)
          .where("type", "==", typeFilter)
					.orderBy("geohash")
          .orderBy('date', 'desc')
      } else {
        query = db.collection('posts')
					.where("banned", "==", false)
					.where("geohash", ">=", search_box.lower)
					.where("geohash", "<=", search_box.upper)
					.orderBy("geohash")
					.orderBy('date', 'desc')
      }
    }
	} else {
    if (activityFilter == "top"){
      if (typeFilter == "art" || typeFilter == "text"){
        query = db.collection('posts')
          .where("banned", "==", false)
          .where("type", "==", typeFilter)
          .orderBy('votes', 'desc')
      } else {
        query = db.collection('posts')
          .where("banned", "==", false)
          .orderBy('votes', 'desc')
      }
    } else {
      if (typeFilter == "art" || typeFilter == "text"){
        query = db.collection('posts')
        .where("banned", "==", false)
        .where("type", "==", typeFilter)
        .orderBy('date', 'desc')
      } else {
        query = db.collection('posts')
        .where("banned", "==", false)
        .orderBy('date', 'desc')
      }
    }
  }

  // Get the document snapshot of the last document first
  query.get().then((snapshot) => {

    var posts = []
    var ref;

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
      posts = posts.size >= 20 ? posts.slice(0, 20) : posts
      ref = posts[posts.size - 1].postId
    } else {
      posts = posts.sort((a, b) => { return b.date - a.date })
      posts = posts.length >= 20 ? posts.slice(0, 20) : posts
      ref = posts[posts.length - 1].postId    
    }
    res.status(200).send({reference: ref, posts: posts})
  })	
  .catch((err) => { 
    console.log("ERROR looking up posts in posts.js:" + err)
    res.send([])
  })	
}

/*
Post /posts
Description: Post request including details of user post
Input parameter Names: content, poster, votes, date, type, lat, lon, numFlags
Output: None
*/
async function createPost(req, res, next) {
	var db = req.app.get('db');  
	console.log("createPost request of type: " + req.body.type + " and req.body.userID: " + req.body.userID)
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
			numFlags : 0,
			geohash: utils.getGeohash(req.body.latitude, req.body.longitude),
			interactions: {},
			toxicity: 1, // Just default to the worst for images
			banned: false,
			comments: 0
		};
  }

	await db.collection("posts").add(userPost)
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

async function deletePost(req, res, next) {
  var db = req.app.get('db');
  postID = req.body.postId
  console.log(`Attempting to delete: ${postID}`)

	db.collection("posts").doc(postID).delete()
	.catch((err) => {
		console.log("ERROR storing post : " + err)
		res.status(400).send()
	})
	.then(() => {
    utils.deletePostComments(postID, req)
		res.status(200).send("Successfully deleted post " + postID);
  })


}

async function morePosts(req, res, next) {
	let user = req.query.user;
	let lat = Number(req.query.lat);
	let lon = Number(req.query.lon);
	let range = req.query.range;
  let docRef = req.query.ref;
  let activityFilter = req.query.activityFilter;
  let typeFilter = req.query.typeFilter;
	if (typeof(range) == "undefined") { // If range unspecified, use some default one
		range = default_range;
	}

	range = Number(range);

	console.log("GetMorePosts request from lat: " + lat + " and lon: " + lon + " for posts within range:" + range + " from user: " + user)
	
	// Get the db object, declared in app.js
	var db = req.app.get('db');

  var query;
	if (range != -1) { // -1 refers to global range
		// Calculate the lower and upper geohashes to consider
		const search_box = utils.getGeohashRange(lat, lon, range);

    // Basic request for posts
    if (activityFilter == "top"){
      if (typeFilter == "art" || typeFilter == "text"){
        query = db.collection('posts')
					.where("banned", "==", false)
					.where("geohash", ">=", search_box.lower)
          .where("geohash", "<=", search_box.upper)
          .where("type", "==", typeFilter)
					.orderBy("geohash")
					.orderBy('votes', 'desc')
      } else {
        query = db.collection('posts')
					.where("banned", "==", false)
					.where("geohash", ">=", search_box.lower)
					.where("geohash", "<=", search_box.upper)
					.orderBy("geohash")
					.orderBy('votes', 'desc')
      }
    } else {
      if (typeFilter == "art" || typeFilter == "text"){
        query = db.collection('posts')
					.where("banned", "==", false)
					.where("geohash", ">=", search_box.lower)
          .where("geohash", "<=", search_box.upper)
          .where("type", "==", typeFilter)
					.orderBy("geohash")
					.orderBy('date', 'desc')
      } else {
        query = db.collection('posts')
					.where("banned", "==", false)
					.where("geohash", ">=", search_box.lower)
					.where("geohash", "<=", search_box.upper)
					.orderBy("geohash")
					.orderBy('date', 'desc')
      }
    }
	} else {
    if (activityFilter == "top"){
      if (typeFilter == "art" || typeFilter == "text"){
        query = db.collection('posts')
          .where("banned", "==", false)
          .where("type", "==", typeFilter)
          .orderBy('votes', 'desc')
      } else {
        query = db.collection('posts')
          .where("banned", "==", false)
          .orderBy('votes', 'desc')
      }
    } else {
      if (typeFilter == "art" || typeFilter == "text"){
        query = db.collection('posts')
        .where("banned", "==", false)
        .where("type", "==", typeFilter)
        .orderBy('date', 'desc')
      } else {
        query = db.collection('posts')
        .where("banned", "==", false)
        .orderBy('date', 'desc')
      }
    }
  }

  // Get the document snapshot of the last document first
  query.get().then((snapshot) => {
    var posts = []
    var ref;

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

      // Get index of post with docRef (last post from previous request)
      var postIdx = posts.map(function(e) { return e.postId; }).indexOf(docRef);

      // Get the next 20 posts
      if (posts.length >= postIdx + 21){
        ref = posts[postIdx + 20].postId
        posts = posts.slice(postIdx + 1, postIdx + 21)
      } else if (posts.length >= postIdx + 1){
        ref = posts[posts.length - 1].postId
        posts = posts.slice(postIdx + 1, posts.length)
      } else {
        ref = posts[posts.length - 1].postId
        posts = []
      }
      
    } else {
      posts = posts.sort((a, b) => { return b.date - a.date })
      // Get index of post with docRef (last post from previous request)
      var postIdx = posts.map(function(e) { return e.postId; }).indexOf(docRef);

      // Get the next 20 posts
      if (posts.length >= postIdx + 21){
        ref = posts[postIdx + 20].postId
        posts = posts.slice(postIdx + 1, postIdx + 21)
      } else if (posts.length >= postIdx + 1){
        ref = posts[posts.length - 1].postId
        posts = posts.slice(postIdx + 1, posts.length)
      } else {
        ref = posts[posts.length - 1].postId
        posts = []
      }
    }
    res.status(200).send({reference: ref, posts: posts})
  })	
  .catch((err) => { 
    console.log("ERROR looking up posts in posts.js:" + err)
    res.send([])
  })
	
}

module.exports = router;