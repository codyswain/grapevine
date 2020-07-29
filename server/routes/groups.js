var express = require('express');
var router = express.Router();
var utils = require('../server_utils.js'); // NOTE: Relative pathing can break
const Perspective = require('perspective-api-client');
const perspective = new Perspective({apiKey: process.env.PERSPECTIVE_API_KEY});
const FieldValue = require('firebase-admin').firestore.FieldValue

router.post('/', createGroup);          // Create a group
router.post('/posts', createPost);	// Create post in a group
router.get('/', fetchGroups);           // Fetch groups for a given member 
router.get('/keygen', createGroupKey);    // Create a key so a new user can join a group
router.get('/key', consumeKey);         // Consume a key and return the groupID
router.get('/posts', getPosts);		//Get all Posts from a group
router.get('/posts/more', morePosts);	//Get more posts from a group for infinite scrolling
router.delete('/posts', deletePost);	//Delete post from group
router.delete('/', deleteGroup);	//Delete post from group

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

/* POST /groups/posts
Description: Post request includes the following
Input parameter Names: content, poster, votes, date, type, lat, lon, numFlags
Output: None */
async function createPost(req, res, next) {
	var db = req.app.get('db');
	let groupID = req.body.groupID
	console.log("createGroupsPost request of type: " + req.body.type + " and req.body.userID: " + req.body.userID + " and req.body.groupID: " + req.body.groupID)
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
			groupID : req.body.groupID,
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
			groupID : req.body.groupID,
			numFlags : 0,
			geohash: utils.getGeohash(req.body.latitude, req.body.longitude),
			interactions: {},
			toxicity: 1, // Just default to the worst for images
			banned: false,
			comments: 0
		};
  }

	await db.collection('groups').doc(groupID).collection('posts').add(userPost)
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
      if (ref1.exists){
        groups.push({
          name: ref1.data().name,
          id: groupID,
          ownerID: ref1.data().ownerID
        })
      }
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
    res.status(404).send()
  });
}

/* GET /groups/posts
Description: Get request including userID, latitude and longitude of user location, AND GROUPID
Input parameter Names: user, lat, lon, groupID
Output: 20 posts ordered by recency returned as posts.
*/
async function getPosts(req, res, next) {
	let user = req.query.user;
	let groupID = req.query.groupID;
	let activityFilter = req.query.activityFilter;
	let typeFilter = req.query.typeFilter;
	console.log("GetPosts request from groupID: " + groupID + " for user " + user)

  	// Get the db object, declared in app.js
  	var db = req.app.get('db');

  	var query; 

    	// Basic request for posts
    	if (activityFilter == "top"){
		if (typeFilter == "art" || typeFilter == "text"){
        		query = db.collection('groups').doc(groupID).collection('posts')
				.where("banned", "==", false)
          			.where("type", "==", typeFilter)
				.orderBy('votes', 'desc')
		} else {
			db.collection('groups').doc(groupID).collection('posts')
				.where("banned", "==", false)
				.orderBy('votes', 'desc')
		}
	} else {
		if (typeFilter == "image" || typeFilter == "text"){
			query = db.collection('groups').doc(groupID).collection('posts')
				.where("banned", "==", false)
          			.where("type", "==", typeFilter)
				.orderBy('date', 'desc')
		} else {
        		query = db.collection('groups').doc(groupID).collection('posts')
				.where("banned", "==", false)
				.orderBy('date', 'desc')
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


async function morePosts(req, res, next) {
	let docRef = req.query.ref;
	let user = req.query.user;
	let groupID = req.query.groupID;
	let activityFilter = req.query.activityFilter;
	let typeFilter = req.query.typeFilter;
	console.log("GetMorePosts request from groupID: " + groupID + " for user " + user)

  	// Get the db object, declared in app.js
  	var db = req.app.get('db');

  	var query; 

    	// Basic request for posts
    	if (activityFilter == "top"){
		if (typeFilter == "art" || typeFilter == "text"){
        		query = db.collection('groups').doc(groupID).collection('posts')
				.where("banned", "==", false)
          			.where("type", "==", typeFilter)
				.orderBy('votes', 'desc')
		} else {
			db.collection('groups').doc(groupID).collection('posts')
				.where("banned", "==", false)
				.orderBy('votes', 'desc')
		}
	} else {
		if (typeFilter == "image" || typeFilter == "text"){
			query = db.collection('groups').doc(groupID).collection('posts')
				.where("banned", "==", false)
          			.where("type", "==", typeFilter)
				.orderBy('date', 'desc')
		} else {
        		query = db.collection('groups').doc(groupID).collection('posts')
				.where("banned", "==", false)
				.orderBy('date', 'desc')
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

//Delete a post from a group
//Inputs: postID, groupID
//Outputs: None
async function deletePost(req, res, next) {
  var db = req.app.get('db');
  let postID = req.body.postId
  let groupID = req.body.groupID
  console.log(`Attempting to delete: ${postID} with groupID: ${groupID}`)
	db.collection('groups').doc(groupID).collection('posts').doc(postID).delete()
	.catch((err) => {
		console.log("ERROR storing post : " + err)
		res.status(400).send()
	})
	.then(() => {
    utils.deletePostComments(postID, req)
		res.status(200).send("Successfully deleted post " + postID);
  })
}


//Inputs: groupID
async function deleteGroup(req, res, next) {
	var db = req.app.get('db');
  let groupID = req.body.groupID;

  // Fetch all the posts and delete corresponding comments
  db.collection('groups').doc(groupID).collection('posts').get()
  .then(function(querySnapshot) {
    querySnapshot.forEach(function(doc) {
      let postID = doc.id
      console.log(`DELETE comments for post ${postID}`); //doc.data() never undefined
      utils.deletePostComments(postID, req);
    });
  })
  .catch(function(error) {
      console.log("Error getting documents: ", error);
      res.status(400).send()
      return
  });

  // Get all the members in a group (groups collection)
  // THEN delete corresponding group id from each member (users collection)
  let groupRef = await db.collection('groups').doc(groupID).get() // returns an array
  if (groupRef.data() === undefined){
    console.log(`ERROR: Attempting to delete group that doesn't exist: ${groupID}`)
    res.status(400).send()
    return
  }
  let fetchedMembers = groupRef.data().members
  if (fetchedMembers === undefined || fetchedMembers.length == 0){
    console.log(`ERROR: undefined members array (or empty) groupID: ${groupID}`)
    res.status(400).send()
    return
  } else {
    for (const memberID of fetchedMembers){
      console.log(`DELETE group ${groupID} field from member: ${memberID}`)
      let groupRef = await db.collection('users').doc(memberID)
      groupRef.update({
        groups: FieldValue.arrayRemove(groupID)
      })
    }
  }

  // Delete the group
  console.log(`Deleting group: ${groupID}`)
  db.collection('groups').doc(groupID).delete()
  .catch((err) => {
		console.log("ERROR deleting group: " + err)
    res.status(400).send()
    return
	})
	.then(() => {
    res.status(200).send(`COMPLETED DELETE group:${groupID}`);
  })
}

module.exports = router;
