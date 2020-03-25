var express = require('express');
var path = require('path');
var createError = require('http-errors');
var bodyParser = require('body-parser');
var fs = require('fs');
require('dotenv').config();;

// These are the files that control endpoints the actual endpoints
var postsRouter = require('./routes/posts');
var commentsRouter = require('./routes/comments');
var usersRouter = require('./routes/users');
var interactionsRouter = require('./routes/interactions');
var banChamberRouter = require('./routes/banChamber');

// Set the app to use Express
var app = express();

// Firestore initialization
const admin = require('firebase-admin');
const { GeoCollectionReference, GeoFirestore, GeoQuery, GeoQuerySnapshot } = require('geofirestore');

var serviceAccount
try {
  if(fs.existsSync('./firebase-key.json')) {
    serviceAccount = require('./firebase-key.json');
  } else {
    serviceAccount = JSON.parse(process.env.FIREBASE_KEY)
  }
} catch (err) {
  console.error(err);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const firestore = admin.firestore();

// Aliases
app.set('db', firestore); 

// Middleware that allows us to use URL decoding, JSON, etc
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, 'public')));

// Link files that control endpoints to the actual endpoints
app.use('/posts', postsRouter);
app.user('/comments', commentsRouter);
app.use('/users', usersRouter);
app.use('/interactions', interactionsRouter);
app.use('/banChamber', banChamberRouter);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.send('error');
});

module.exports = app;

// app.listen(3000, () => {console.log("Running")});