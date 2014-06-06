## Running this yourself

 1. Create a Dropbox app
     1. Go to [Dropbox App Console](https://www.dropbox.com/developers/apps) (may need to create an account first)
     2. Create an app with the following settings:
         - Dropbox API App
         - Store: Files and datastores
         - Own folder: Yes
         - Name: HeroCast
     3. Generate an Oauth2 token on the app Settings tab (use this in feed URL in step 4.1).
 2. Create a Heroku app
     1. Sign up for Heroku
     2. Download, install, configure Heroku tools.
     3. Create Heroku app with `heroku create --buildpack https://github.com/miyagawa/heroku-buildpack-perl.git`
     4. Deploy app with `git push heroku master`
 3. Add items to feed
     1. There should be a "HeroCast" folder in an "Apps" folder in your Dropbox.
     2. Add audio and video files.
 4. Access feed
     1. Go to http://your-app.herokuapp.com/feed/accesstoken (from step 1.3)