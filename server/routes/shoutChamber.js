var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js') // NOTE: Relative pathing can break
const admin = require('firebase-admin');
const FieldValue = require('firebase-admin').firestore.FieldValue

// URL parsing to get info from client
router.get('/', getShoutablePosts);
router.get('/shoutPost/', shoutPost);

/**
 * Fetches downvoted posts and updates the user's score.
 */
async function getShoutablePosts(req, res, next) {
	let user = req.query.user;
	let lat = Number(req.query.lat);
	let lon = Number(req.query.lon);
	let range = req.query.range;
	let groupID = req.query.groupID;
	if (typeof(range) == "undefined") { // If range unspecified, use some default one
		range = default_range;
	}
	range = Number(range);

	console.log("GetShoutablePosts request from lat: " + lat + " and lon: " + lon + " for posts within range:" + range + " from user: " + user)

	// Get the db object, declared in app.js
	var db = req.app.get('db');
	var query = ""
	if (groupID == "Grapevine") {
		query = db.collection('posts').where("banned", "==", false)
	} else {
		query = db.collection('groups').doc(groupID).collection('posts').where("banned", "==", false)
	}
	if (range != -1) { // -1 refers to global range
		// Calculate the lower and upper geohashes to consider
		const search_box = utils.getGeohashRange(lat, lon, range);

		if (groupID == "Grapevine") {
			query = db.collection('posts')
					.where("banned", "==", false)
					.where("geohash", ">=", search_box.lower)
					.where("geohash", "<=", search_box.upper)
					.orderBy("geohash")
		} else {
			query = db.collection('groups').doc(groupID).collection('posts')
					.where("banned", "==", false)
					.where("geohash", ">=", search_box.lower)
					.where("geohash", "<=", search_box.upper)
					.orderBy("geohash")
		}
	}

	var posts = []

	// Query the db for posts
	await query.orderBy('date', 'desc')
		.limit(50).get().then((snapshot) => {
            // Loop through each post returned and add it to our list
            let now = Math.floor(Date.now() / 1000)
			snapshot.forEach((post) => {
				var curPost = post.data()
				if (curPost.shoutExpiration == undefined || parseInt(curPost.shoutExpiration) < now){
					curPost.postId = post.id
					curPost.voteStatus = 0
					curPost.flagStatus = 0
					delete curPost["geohash"]
					delete curPost["interactions"]
					posts.push(curPost)
				}
			});
		})
		.catch((err) => { 
			console.log("ERROR looking up shoutable posts:" + err)
		})

	res.status(200).send({reference: "", posts: posts})		
}

/**
 * Fetches downvoted posts and updates the user's score.
 * 
 * TODO: Check if the post has already been shout out and fail if it still has time left
 */
async function shoutPost(req, res, next) {
	let user = req.query.user;
	let datetime = req.query.time;
	let postID = req.query.postID;
	let groupID = req.query.groupID;
	// Get the db object, declared in app.js
	var db = req.app.get('db');

	let userref = db.collection('users').doc(user)
	var docref = ""
	if (groupID == "Grapevine") {
		docref = db.collection('posts').doc(postID)
	} else {
		docref = db.collection('groups').doc(groupID).collection('posts').doc(postID)
	}
	db.runTransaction(t => {
		return t.get(docref).then(snapshot => {
			console.log(snapshot.data())
			if (!snapshot.exists) {
				res.status(500).send();
				throw "Post " + postID + " does not exist";
			}

			console.log("boop")
			t.update(userref, { score: FieldValue.increment(-10)});
			t.update(docref, { shoutExpiration: parseInt(datetime)});
		})
	}).then(() => {
        console.log("Successfully gave a shout out to the post " + postID)
        var body = "🔈 Someone gave you a shout out!";
        utils.sendPushNotificationToPoster(req, postID, body);
        res.status(200).send()
	}).catch((err) => {
		console.log("Failed to give a shout out to the post " + postID)
		console.log("Error: " + err)
		res.status(500).send()
	})
}

module.exports = router;
