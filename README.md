# Grapevine
Grapevine is an anonymous, proximity-based sharing application that allows users to truly express their opinions, anxieties, and overall personalities with complete peace of mind. This can be in the form of text, drawings, polls, voice, or other media. 
It’s useful and fun to see what people exclusively in your area actually think. As our generation has gotten so conditioned to have all of our activity associated with our profile online, a space to be genuine with no repercussions is needed. People want a place to be themselves without judgement. We will provide an open space for young people (especially at universities and companies) to communicate without worrying about their reputation. While we try to avoid using romantic language, an implementation that succeeds in providing this type of environment will be a liberating break from what we have become used to. 

To combat bullying, all posts are parsed by the Google Perspective AI, and given a toxicity score 0<TS<1. Posts above a certain threshold are flagged. The goal is to eventually build a community moderation mechanism, by which respected users are incentivized to moderate content within their respective localities. 

## Directory Structure
The client code is within 'Grapevine' folder. 

The server code is within 'server' folder. The main 'startup' file that acts like main is app.js, and posts.js and users.js control their eponymous endpoints. Most of the rest is auto-generated from the Node starter project.  

## Installation/Run instructions
To run the server,
```
git clone [repo]
cd [repo]
cd server
npm install
npm start
``` 
And then use a mock client like Postman to test it out.

To run the client code, make sure you're using the latest version of Xcode, and open the .xcworkspace file, NOT the .xcodeproject file. You should see the files laid out and be able to run the client there. To connect the client to a Firestore database you need to add a GoogleService-Info.plist file to the /Grapevine-130/Grapevine-130 folder. If you are using your own database, this file can be generated from the Firestore settings page. The database requires a "users" collection and a "posts" collection.

## Relevant Links 
grapevineapp.herokuapp.com


