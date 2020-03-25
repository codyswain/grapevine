var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js') // NOTE: Relative pathing can break
const admin = require('firebase-admin');

// URL parsing to get info from client
router.get('/', getBannablePosts);
router.get('/banPoster/', banPoster);

/**
 * Fetches downvoted posts and updates the user's score.
 */
async function getBannablePosts(req, res, next) {
	let user = req.query.user;
	let lat = Number(req.query.lat);
	let lon = Number(req.query.lon);
	let range = req.query.range;
	if (typeof(range) == "undefined") { // If range unspecified, use some default one
		range = default_range;
	}
	range = Number(range);

	console.log("GetBannablePosts request from lat: " + lat + " and lon: " + lon + " for posts within range:" + range + " from user: " + user)

	// Get the db object, declared in app.js
	var db = req.app.get('db');

	// Calculate the lower and upper geohashes to consider
    const search_box = utils.getGeohashRange(lat, lon, range);
	
	var posts = []

	// Query the db for posts
	db.collection('posts')
		.where("geohash", ">=", search_box.lower)
    	.where("geohash", "<=", search_box.upper)
    	.orderBy('geohash')
		.orderBy('date', 'desc')
		.limit(50).get()
		.then((snapshot) => {
			// Loop through each post returned and add it to our list
			snapshot.forEach((post) => {
				var curPost = post.data()
				if (curPost.votes < 0){
					curPost.postId = post.id
					curPost.voteStatus = 0
					curPost.flagStatus = 0
					delete curPost["geohash"]
					delete curPost["interactions"]
					posts.push(curPost)
				}
			});
			// Return the posts to the client
			
		})
		.catch((err) => { 
			console.log("ERROR looking up bannable posts:" + err)
		})

	db.collection('users').doc(user).update({
	  score: admin.firestore.FieldValue.increment(-20)
	}).then((snapshot) => {
		res.status(200).send(posts)		
	})
	.catch((err) => { 
		console.log("ERROR changing user score:" + err)
		res.status(200).send(posts)
	})	
	
}

/**
 * Fetches downvoted posts and updates the user's score.
 */
async function banPoster(req, res, next) {
	let poster = req.query.poster;
	let time = req.query.time;
	// Get the db object, declared in app.js
	var db = req.app.get('db');
	var strikeUpdateStatus = false
	var timeUpdateStatus = false

	await db.collection('users').doc(poster).update({
	  strikes: admin.firestore.FieldValue.increment(3)
	}).then((snapshot) => {
		strikeUpdateStatus = true
	})
	.catch((err) => { 
		strikeUpdateStatus = false
		console.log("ERROR updating strikes in posts.js:" + err)
	})	

	await db.collection('users').doc(poster).update({
	  banDate: parseInt(time)
	}).then((snapshot) => {
		timeUpdateStatus = true
	})
	.catch((err) => { 
		timeUpdateStatus = false
		console.log("ERROR updating time in posts.js:" + err)
	})	

	if (strikeUpdateStatus && timeUpdateStatus){
		res.send("banPoster strikes and time update success")
	} else {
		res.send("Error in banPoster")
	}
}

module.exports = router;