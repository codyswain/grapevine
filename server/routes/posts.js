var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js') // NOTE: Relative pathing can break
const Perspective = require('perspective-api-client');
const perspective = new Perspective({apiKey: process.env.PERSPECTIVE_API_KEY});

const default_range = "1"; // Default bounding square half width, in miles

// URL parsing to get info from client
router.get('/', getPosts);
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
	if (typeof(range) == "undefined") { // If range unspecified, use some default one
		range = default_range;
	}
	range = Number(range);

	console.log("GetPosts request from lat: " + lat + " and lon: " + lon + " for posts within range:" + range + " from user: " + user)

	// Get the db object, declared in app.js
	var db = req.app.get('db');

	// Calculate the lower and upper geohashes to consider
    const search_box = utils.getGeohashRange(lat, lon, range);

	// Query the db for posts
	db.collection('posts')
		.where("banned", "==", false)
		.where("geohash", ">=", search_box.lower)
		.where("geohash", "<=", search_box.upper)
		.orderBy("geohash")
		.orderBy('date', 'desc')
		.limit(20).get()
		.then((snapshot) => {
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
			res.status(200).send(posts)
		})
		.catch((err) => { 
			console.log("ERROR looking up post in posts.js:" + err)
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
			banned: false
		};
	}

	// Image/drawing creation logic
	if (req.body.type == 'image') {

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
			banned: false
		};
	}

	db.collection("posts").add(userPost)
	.then(ref => {
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

	db.collection("posts").doc(req.body.postId).delete()
	.catch((err) => {
		console.log("ERROR storing post : " + err)
		res.status(400).send()
	})
	.then(() => {
		res.status(200).send("Successfully deleted post " + req.body.postId);
	})


}

module.exports = router;