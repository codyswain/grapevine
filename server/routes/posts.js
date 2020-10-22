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
router.get('/single', getSinglePost)
router.post('/checkToxicity', checkToxicity);

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
      if (typeFilter == "image" || typeFilter == "text"){
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
      if (typeFilter == "image" || typeFilter == "text"){
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
      if (typeFilter == "image" || typeFilter == "text"){
        query = db.collection('posts')
          .orderBy('votes', 'desc')
          .where("banned", "==", false)
          .where("type", "==", typeFilter)
          .where('visibility', '==', 'Global')
      } else {
        query = db.collection('posts')
          .where("banned", "==", false)
          .where("visibility", "==", "Global")
          .orderBy('votes', 'desc')
      }
    } else {
      if (typeFilter == "image" || typeFilter == "text"){
        query = db.collection('posts')
        .where("banned", "==", false)
        .where("type", "==", typeFilter)
        .where("visibility", "==", "Global")
        .orderBy('date', 'desc')
      } else {
        query = db.collection('posts')
        .where("banned", "==", false)
        .where("visibility", "==", "Global")
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
      posts = posts.length >= 20 ? posts.slice(0, 20) : posts
      ref = posts[posts.length - 1].postId
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
Post /posts/checkToxicity
Description: Checks the toxicity of a post before allowing it to be posted to the database
Only for text posts
*/
async function checkToxicity(req, res) {
  let text = req.body.text
  var score = 0
  let toxic_result = await perspective.analyze(text)
  .then((toxic_result) => {
    score = toxic_result.attributeScores.TOXICITY.summaryScore.value
    console.log("Toxicity score: " + score)
    if (score >= 0.8){
      res.status(214).json(score);
    }
    else {
      res.status(200).json(score);
    }
  })
  .catch((err) => {
    console.log("Toxicity score undetermined because: " + err)
    score = 999
    res.status(214).json(score);
  })
}
/*
Post /posts
Description: Post request including details of user post
Input parameter Names: content, poster, votes, date, type, lat, lon, numFlags, groupID
Output: None
*/
async function createPost(req, res, next) {
	var db = req.app.get('db');  
  console.log("createPost request of type: " + req.body.type + " and req.body.userID: " + req.body.userID)
  if(req.body.visibility == undefined){
    req.body.visibility = "Local"
  }
	// Text post creation logic
	if (req.body.type == 'text') {
    let text = req.body.text
    if (utils.isMatchBannedWords(text)) {
      console.log("content not permitted")
      res.status(213).send("content not permitted") //213  is a custom status code. Status codes are extensible. this is saying the request was successfully processed but indicated the content is not permitted. Defined by us.
      return
    }
    else {
      var toxicityScore = 0
      let toxic_result = await perspective.analyze(text)
      .then((toxic_result) => {
        toxicityScore = toxic_result.attributeScores.TOXICITY.summaryScore.value
      })
      .catch((err) => {
        console.log("Toxicity score undetermined because: " + err)
        toxicityScore = 999
      })
      .finally(() => {
        var numberOfFlags = 0
        if (toxicityScore >= 0.8) {
          console.log("Post flagged because it has a toxicity score of: " + toxicityScore)
          numberOfFlags = 1
        }
        userPost = {
          content : text,
          poster : req.body.userID,
          votes : 0,
          date : req.body.date,
          type : req.body.type,
          lat : req.body.latitude,
          lon : req.body.longitude,
          visibility : req.body.visibility,
          numFlags : numberOfFlags,
          geohash: utils.getGeohash(req.body.latitude, req.body.longitude),
          interactions: {},
          toxicity: toxicityScore,
          banned: false,
          comments: 0
        };
      })
    }
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
      visibility : req.body.visibility,
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
		console.log("ERROR deleting post : " + err)
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
      if (typeFilter == "image" || typeFilter == "text"){
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
      if (typeFilter == "image" || typeFilter == "text"){
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
      if (typeFilter == "image" || typeFilter == "text"){
        query = db.collection('posts')
          .where("banned", "==", false)
          .where("type", "==", typeFilter)
          // .where("visibility", "==", "Global")
          .orderBy('votes', 'desc')
      } else {
        query = db.collection('posts')
          .where("banned", "==", false)
          // .where("visibility", "==", "Local")
          .orderBy('votes', 'desc')
      }
    } else {
      if (typeFilter == "image" || typeFilter == "text"){
        query = db.collection('posts')
        .where("banned", "==", false)
        .where("type", "==", typeFilter)
        .where("visibility", "==", "Global")
        .orderBy('date', 'desc')
      } else {
        query = db.collection('posts')
        .where("banned", "==", false)
        .where("visibility", "==", "Global")
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
      } else if (posts.length >= postIdx + 2){
        ref = posts[posts.length - 1].postId
        posts = posts.slice(postIdx + 1, posts.length)
      } else {
        ref = ""
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
      } else if (posts.length >= postIdx + 2){
        ref = posts[posts.length - 1].postId
        posts = posts.slice(postIdx + 1, posts.length)
      } else {
        ref = ""
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

// get a single post from the database
async function getSinglePost(req, res, next) {
  let postID = req.query.postID;
  let groupID = req.query.groupID;
	console.log("GetSinglePost request for postID: " + postID + " in group: " + groupID)

  // Get the db object, declared in app.js
  var db = req.app.get('db');
  if (groupID == "Grapevine") {
    query = db.collection('posts').doc(postID)
  } else {
    query = db.collection('groups').doc(groupID).collection('posts').doc(postID)
  }
  query.get().then((doc) => { 
    if (doc.exists) {
      post = {
        "content": doc.get("content"),
        "postId" : postID,
        "poster" : doc.get("poster"),
        "votes" :  doc.get("votes"),
        "date" :  doc.get("date"),
        "voteStatus" : 0, // This function is for getting a user's own post; they cant interact with it.
        "type" :  doc.get("type"),
        "lat" :  doc.get("lat"),
        "lon" :  doc.get("lon"),
        "numFlags" :  doc.get("numFlags"),
        "flagStatus" : 0, //Same idea as voteStatus
        "geohash" :  doc.get("geohash"),
        "interactions" :  doc.get("interactions"),
        "toxicity" :  doc.get("toxicity"),
        "banned" :  doc.get("banned"),
        "groupID" : doc.get("groupID"),
        "comments" :  doc.get("comments")
      };
      res.status(200).send(post)
    } else {
      console.log("Post is either in a group or does not exist")
      res.status(404).send([])
    }
  })
  .catch((err) => {
    console.log("ERROR looking up post: " + postID + " in posts.js:" + err)
    res.status(400).send([])
  })

}

module.exports = router;
