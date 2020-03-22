## UI Tests

Currently, there are 3 storyboards: main, create post, and score. 

The main and create post storyboards are closely linked, so a single function called `testPosts`. The score storyboard is tested in a function called `testScoreScreen`. 

### [`testPosts()`](./UITest.swift)

This function tests that the main and create posts storyboards' UI elements are visible on the screen. 

Afterwards, it attempts to create a new post that says "Hi". After creating the post, it verifies that the post is created by refreshing the main storyboard. It also check that the various elements associated with a post such as the upvote, downvote, flag, and delete buttons are displayed and behave properly.

### [`testScoreScreen()`](./UITest.swift)

This function tests that the score storyboard's UI elements are visible on the screen.
